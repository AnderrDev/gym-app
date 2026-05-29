-- RPC para reordenar los ejercicios de un día en una sola llamada.
-- Reemplaza el patrón anterior de N UPDATEs paralelos desde el cliente
-- (workout_remote_data_source -> reorderExercisesInDay) y evita la N+1
-- latencia + las race conditions de tener varios UPDATEs concurrentes
-- sobre la misma fila/restricciones unique.
--
-- Seguridad:
--   * SECURITY DEFINER (necesita actualizar routine_exercises del owner)
--   * Verifica que el `auth.uid()` actual es el creador del routine_day
--     padre. Si no, RAISE NOTFOUND para no leakear existencia.
--   * No confía en la longitud del array recibido — sólo actualiza los
--     ids que efectivamente pertenecen al día indicado.

create or replace function public.reorder_routine_exercises(
  p_day_id     uuid,
  p_ordered_ids uuid[]
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner uuid;
begin
  -- Authorize: el día debe existir y pertenecer (vía routine) al usuario actual.
  select r.user_id
    into v_owner
    from public.routine_days rd
    join public.routines r on r.id = rd.routine_id
   where rd.id = p_day_id;

  if v_owner is null then
    raise exception 'routine_day_not_found' using errcode = 'P0002';
  end if;

  if v_owner <> auth.uid() then
    raise exception 'not_authorized' using errcode = '42501';
  end if;

  -- Actualizar order según la posición en el array.
  -- WITH ORDINALITY le da a unnest el índice 1..N que usamos como `order` (0-based).
  update public.routine_exercises re
     set "order" = ord.idx - 1
    from unnest(p_ordered_ids) with ordinality as ord(exercise_id, idx)
   where re.routine_day_id = p_day_id
     and re.exercise_id    = ord.exercise_id;
end;
$$;

revoke all on function public.reorder_routine_exercises(uuid, uuid[]) from public;
-- `anon` recibe EXECUTE vía default privileges del proyecto; lo revocamos
-- explícitamente para dejar la función authenticated-only, igual que el resto
-- de RPCs (fork_routine_v1, get_*). El gate de auth.uid() ya bloquea a anon,
-- pero mantenemos la convención + defensa en profundidad.
revoke execute on function public.reorder_routine_exercises(uuid, uuid[]) from anon;
grant execute on function public.reorder_routine_exercises(uuid, uuid[]) to authenticated;

comment on function public.reorder_routine_exercises(uuid, uuid[]) is
  'Reordena los ejercicios de un routine_day en una sola operación. SECURITY DEFINER + check owner.';
