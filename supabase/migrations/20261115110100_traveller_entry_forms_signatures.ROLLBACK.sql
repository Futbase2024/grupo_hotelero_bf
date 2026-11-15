-- Rollback de 20261115110100_traveller_entry_forms_signatures.sql
-- ⚠️ Aplicar ANTES el rollback de 20261115110200.
-- ⚠️ BORRA todos los partes de entrada y firmas recogidos con el flujo nuevo.
--    Si ya hay estancias reales registradas, exportarlos antes: forman parte
--    del registro de viajeros que hay que conservar 3 años.

BEGIN;

DROP TABLE IF EXISTS public.guest_signatures;
DROP TABLE IF EXISTS public.traveller_entry_forms;

DROP FUNCTION IF EXISTS public.trg_guest_signatures_immutable();
DROP FUNCTION IF EXISTS public.trg_traveller_entry_forms_immutable();

COMMIT;
