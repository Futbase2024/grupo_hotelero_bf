-- Rollback de 20260720120000_create_extra_requests.sql
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'extra_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime DROP TABLE public.extra_requests;
  END IF;
END $$;

DROP TABLE IF EXISTS public.extra_requests CASCADE;
