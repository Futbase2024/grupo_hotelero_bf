-- ROLLBACK de 20260710124000_drop_test_auth_uid.sql
-- Recrea la función de depuración tal cual estaba (2026-07-10).
CREATE OR REPLACE FUNCTION public.test_auth_uid()
 RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_uid UUID;
BEGIN
  v_uid := auth.uid();
  IF v_uid IS NULL THEN
    RETURN 'auth.uid() is NULL';
  ELSE
    RETURN 'auth.uid() is ' || v_uid::text;
  END IF;
END;
$function$;
