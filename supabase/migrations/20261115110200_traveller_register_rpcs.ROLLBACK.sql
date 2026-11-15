-- Rollback de 20261115110200_traveller_register_rpcs.sql
-- Solo elimina funciones: no borra datos.

BEGIN;

DROP FUNCTION IF EXISTS public.submit_traveller_checkin(UUID);
DROP FUNCTION IF EXISTS public.sign_traveller_entry_form(UUID, UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.save_traveller_guest(UUID, UUID, JSONB);
DROP FUNCTION IF EXISTS public.traveller_register_issues(UUID);
DROP FUNCTION IF EXISTS public._traveller_guest_snapshot(UUID, UUID);
DROP FUNCTION IF EXISTS public._traveller_guest_issues(UUID, UUID);
DROP FUNCTION IF EXISTS public._traveller_issue(TEXT, TEXT, TEXT);
DROP FUNCTION IF EXISTS public._can_access_traveller_register(UUID, BOOLEAN);

COMMIT;
