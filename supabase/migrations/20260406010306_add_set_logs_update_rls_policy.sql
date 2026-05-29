DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'set_logs'
      AND policyname = 'set_logs_update'
  ) THEN
    CREATE POLICY "set_logs_update" ON public.set_logs
      FOR UPDATE USING (
        EXISTS (
          SELECT 1 FROM public.workout_sessions ws
          WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
        )
      )
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM public.workout_sessions ws
          WHERE ws.id = set_logs.session_id AND ws.user_id = auth.uid()
        )
      );
  END IF;
END
$$;
