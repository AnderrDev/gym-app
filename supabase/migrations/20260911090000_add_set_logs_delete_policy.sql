-- set_logs: faltaba la política de DELETE.
--
-- `set_logs` tiene RLS habilitado y políticas de SELECT/INSERT/UPDATE, pero
-- ninguna de DELETE. Al desmarcar una serie, el DELETE de PostgREST no
-- coincide con ninguna política, borra 0 filas y **no devuelve error**: la
-- app mostraba la serie desmarcada mientras la fila seguía en la base
-- (reaparecía al reanudar y contaba en el resumen de la sesión).
--
-- Misma condición que `set_logs_update`: sólo el dueño de la sesión.

DROP POLICY IF EXISTS "set_logs_delete" ON public.set_logs;
CREATE POLICY "set_logs_delete" ON public.set_logs
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.workout_sessions ws
      WHERE ws.id = set_logs.session_id
        AND ws.user_id = (select auth.uid())
    )
  );
