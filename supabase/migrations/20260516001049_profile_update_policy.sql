-- Permite al usuario actualizar SU propio profile (full_name, eventualmente
-- preferences). Antes existía sólo SELECT — los updates desde el cliente
-- fallaban silenciosamente con RLS.
--
-- Restricción: NO permite cambiar `id` (el `WITH CHECK` re-verifica el
-- ownership tras el update para que un usuario malicioso no pueda
-- reasignar la row a otro usuario).

DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles
  FOR UPDATE
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);
