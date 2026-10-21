-- Arreglo de `discard_workout_session_v1` (20261020120000) para sesiones con
-- ejercicios sustituidos.
--
-- Si en la sesión abierta se sustituyó un ejercicio DESPUÉS de registrarle
-- series (`adapt_session_exercise_v1` con `p_replaces_exercise_id`), el
-- original queda en `exercise_plan` con `replaced_by_exercise_name` y el
-- trigger `guard_session_set_log_v1` (20261015144656) declara sus series
-- inmutables: el `DELETE` de la RPC fallaba con 23514 'retained original
-- logs are immutable' y el cliente lo mostraba como "ya se finalizó".
--
-- Igual que `delete_account_data_v1`, se quita el plan antes de borrar las
-- series: sin `exercise_plan` el trigger no aplica. La función es SECURITY
-- DEFINER, así que `guard_session_exercise_plan_v1` (que sólo bloquea a los
-- roles cliente) permite el UPDATE. Firma, grants y códigos de error no
-- cambian.

create or replace function public.discard_workout_session_v1(
  p_session_id uuid
) returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
  v_completed_at timestamptz;
begin
  if auth.uid() is null then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  select ws.user_id, ws.completed_at
    into v_owner, v_completed_at
    from public.workout_sessions ws
   where ws.id = p_session_id
   for update;

  if not found then
    return false;
  end if;

  if v_owner <> auth.uid() then
    raise exception 'session_not_found' using errcode = 'P0002';
  end if;

  if v_completed_at is not null then
    raise exception 'session_already_completed' using errcode = '23514';
  end if;

  -- Sin plan, `guard_session_set_log_v1` deja borrar también las series de
  -- originales sustituidos. Todo va en la misma transacción.
  update public.workout_sessions
     set exercise_plan = null
   where id = p_session_id
     and exercise_plan is not null;

  delete from public.set_logs where session_id = p_session_id;
  delete from public.workout_sessions where id = p_session_id;
  return true;
end;
$$;

revoke all on function public.discard_workout_session_v1(uuid) from public;
revoke execute on function public.discard_workout_session_v1(uuid) from anon;
grant execute on function public.discard_workout_session_v1(uuid) to authenticated;

comment on function public.discard_workout_session_v1(uuid) is
  'Descarta (borra) una sesión abierta del usuario actual junto con sus series, aunque tenga ejercicios sustituidos. SECURITY DEFINER + check owner.';
