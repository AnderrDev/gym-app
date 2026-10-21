-- RPC para descartar un entrenamiento en curso.
--
-- Hasta ahora una sesión abierta sólo podía cerrarse finalizándola: si el
-- usuario la empezó por error (o la dejó a medias días atrás) la app le
-- bloqueaba iniciar cualquier otro día ("Finalízalo o retómalo") y la única
-- salida era finalizarla, metiendo una sesión basura en el historial y las
-- estadísticas.
--
-- `workout_sessions` no tiene política RLS de DELETE (y no queremos abrirla:
-- el historial cerrado es inmutable), así que el borrado va por una función:
--   * SECURITY DEFINER + check de owner contra `auth.uid()`.
--   * Sólo sesiones ABIERTAS (`completed_at IS NULL`). Una cerrada es
--     historial y no se puede descartar.
--   * Borra las series y la sesión en la misma transacción.
--   * Idempotente: si la sesión ya no existe devuelve `false` (reintento tras
--     perder la respuesta). Ajena o cerrada → error, sin filtrar existencia
--     de sesiones de otros usuarios.

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

  delete from public.set_logs where session_id = p_session_id;
  delete from public.workout_sessions where id = p_session_id;
  return true;
end;
$$;

revoke all on function public.discard_workout_session_v1(uuid) from public;
revoke execute on function public.discard_workout_session_v1(uuid) from anon;
grant execute on function public.discard_workout_session_v1(uuid) to authenticated;

comment on function public.discard_workout_session_v1(uuid) is
  'Descarta (borra) una sesión abierta del usuario actual junto con sus series. SECURITY DEFINER + check owner.';
