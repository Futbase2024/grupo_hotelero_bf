-- ============================================================================
-- Migración 3: Buckets públicos con listado abierto (advisor 0025)
-- ----------------------------------------------------------------------------
-- La app solo usa getPublicUrl() sobre estos buckets (nunca .list()), y los
-- buckets son públicos => las URLs públicas siguen funcionando sin estas
-- policies. Se elimina el listado abierto y se restringe email-assets a staff.
--
-- Estado previo:
--   * unit_photos_public_read  : SELECT a `public`  => cualquiera lista fotos
--   * email_assets_full_admin_staff : ALL a `authenticated` SIN check de rol
--       => cualquier autenticado (incl. invitado anónimo) podía leer/subir/borrar
-- Rollback en: 20260710121000_fix_public_bucket_listing.ROLLBACK.sql
-- ============================================================================

-- 1. unit-photos: quitar el listado público (render vía getPublicUrl no lo necesita)
DROP POLICY IF EXISTS unit_photos_public_read ON storage.objects;

-- 2. email-assets: restringir a staff real (antes: cualquier authenticated)
DROP POLICY IF EXISTS email_assets_full_admin_staff ON storage.objects;
CREATE POLICY email_assets_staff_all ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'email-assets' AND public.is_staff())
  WITH CHECK (bucket_id = 'email-assets' AND public.is_staff());
