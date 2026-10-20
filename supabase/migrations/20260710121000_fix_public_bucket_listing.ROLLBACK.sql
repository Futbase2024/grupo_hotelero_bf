-- ROLLBACK de 20260710121000_fix_public_bucket_listing.sql
-- Restaura las policies originales tal cual estaban (2026-07-10).
BEGIN;

DROP POLICY IF EXISTS email_assets_staff_all ON storage.objects;

CREATE POLICY email_assets_full_admin_staff ON storage.objects
  FOR ALL TO authenticated
  USING (bucket_id = 'email-assets')
  WITH CHECK (bucket_id = 'email-assets');

CREATE POLICY unit_photos_public_read ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'unit-photos');

COMMIT;
