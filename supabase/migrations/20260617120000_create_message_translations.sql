-- Caché de traducciones de mensajes de chat.
-- Solo accesible vía la Edge Function `translate-message` (service_role).
-- RLS habilitado y sin policies para anon/authenticated => denegado por defecto.

CREATE TABLE IF NOT EXISTS public.message_translations (
    message_id      UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    target_lang     TEXT NOT NULL,            -- ISO 639-1: 'es','fr','en','de',...
    translated_text TEXT NOT NULL,
    detected_lang   TEXT,                     -- idioma detectado por OpenAI
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT message_translations_pkey PRIMARY KEY (message_id, target_lang)
);

CREATE INDEX IF NOT EXISTS idx_message_translations_target_lang
    ON public.message_translations (target_lang);

ALTER TABLE public.message_translations ENABLE ROW LEVEL SECURITY;

-- Denegación EXPLÍCITA para roles de cliente (defensa en profundidad).
-- Solo service_role (Edge Function translate-message) accede, y salta RLS.
CREATE POLICY "message_translations_deny_select"
    ON public.message_translations
    FOR SELECT TO anon, authenticated USING (false);

CREATE POLICY "message_translations_deny_insert"
    ON public.message_translations
    FOR INSERT TO anon, authenticated WITH CHECK (false);

CREATE POLICY "message_translations_deny_update"
    ON public.message_translations
    FOR UPDATE TO anon, authenticated USING (false) WITH CHECK (false);

CREATE POLICY "message_translations_deny_delete"
    ON public.message_translations
    FOR DELETE TO anon, authenticated USING (false);

COMMENT ON TABLE public.message_translations IS
    'Caché de traducciones de mensajes. Solo accesible vía Edge Function translate-message (service_role). RLS deniega a anon/authenticated.';
