-- Cierre y coaching de una sesión: solo los escribe el servidor.
--
-- `finalize_workout_session_v1` ya ignora el `coaching_analysis` del cliente
-- (B2), pero la policy `sessions_update` (uid = user_id) seguía dejando que el
-- cliente escribiera `completed_at` / `coaching_analysis` directamente por
-- PostgREST: forjar coaching, cerrar sin pasar por la Edge Function o reabrir
-- una sesión cerrada (`completed_at = NULL`). Lo mismo con un INSERT que ya
-- traiga esas columnas.
--
-- Igual que `guard_session_exercise_plan_v1`: el trigger es de invoker, así
-- que `current_user` es `authenticated`/`anon` en escrituras directas del
-- cliente, `service_role` en la Edge Function (cliente admin) y el dueño de la
-- función dentro de las RPC SECURITY DEFINER. Solo se bloquea a los dos
-- primeros. El cliente actual solo inserta (user_id, routine_day_id,
-- session_date, id) y nunca hace UPDATE sobre `workout_sessions`.
CREATE FUNCTION public.guard_session_completion_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path=public AS $$
BEGIN
 IF current_user IN ('authenticated','anon') AND
   ((TG_OP='INSERT' AND (NEW.completed_at IS NOT NULL OR NEW.coaching_analysis IS NOT NULL)) OR
    (TG_OP='UPDATE' AND (NEW.completed_at IS DISTINCT FROM OLD.completed_at OR
                         NEW.coaching_analysis IS DISTINCT FROM OLD.coaching_analysis))) THEN
   RAISE EXCEPTION 'completed_at/coaching_analysis are managed by finalize_workout_session_v1'
     USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION public.guard_session_completion_v1() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER guard_session_completion_v1 BEFORE INSERT OR UPDATE ON public.workout_sessions
FOR EACH ROW EXECUTE FUNCTION public.guard_session_completion_v1();
