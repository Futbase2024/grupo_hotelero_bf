// Edge Function: translate-message
// Traduce el `text` de un mensaje de chat a `targetLang` usando OpenAI gpt-4o-mini.
// Doble caché:
//   - Servidor: tabla `message_translations` (PK message_id + target_lang).
//   - Cliente: lo gestiona el TranslationRepository de la app (Map en memoria).
// El cliente Flutter NUNCA accede a la tabla directamente: todo pasa por aquí.
// verify_jwt: true => solo usuarios autenticados pueden invocar (la app inyecta el JWT).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface TranslateRequest {
  messageId: string;
  text: string;
  targetLang: string; // 'es' | 'fr' | 'en' | 'de' | ...
}

interface TranslateResponse {
  translatedText: string;
  detectedLanguage: string;
  fromCache: boolean;
}

const OPENAI_MODEL = "gpt-4o-mini";
const MAX_TEXT_CHARS = 2000; // límite anti-coste / anti-abuso

Deno.serve(async (req) => {
  // 1. CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 2. Validar API key de OpenAI
    const openaiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openaiKey) {
      return jsonError(500, "OPENAI_API_KEY no configurada");
    }

    // 3. Parse + validar body
    const { messageId, text, targetLang } = (await req.json()) as TranslateRequest;
    if (!messageId || !text || !targetLang) {
      return jsonError(
        400,
        "Faltan parámetros requeridos (messageId, text, targetLang)"
      );
    }
    const trimmed = text.trim();
    if (trimmed.length === 0) {
      return jsonError(400, "Texto vacío");
    }
    const safeText = trimmed.slice(0, MAX_TEXT_CHARS); // truncar anti-coste

    // 4. Cliente Supabase con service_role (salta RLS)
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 5. Caché servidor: SELECT en message_translations
    const { data: cached, error: cacheErr } = await supabase
      .from("message_translations")
      .select("translated_text, detected_lang")
      .eq("message_id", messageId)
      .eq("target_lang", targetLang)
      .maybeSingle();

    if (cacheErr) console.warn("Cache read error:", cacheErr.message);
    if (cached) {
      return jsonResponse<TranslateResponse>({
        translatedText: cached.translated_text,
        detectedLanguage: cached.detected_lang ?? "",
        fromCache: true,
      });
    }

    // 6. Llamada OpenAI Chat Completions (detecta idioma + traduce, JSON mode)
    const systemPrompt =
      `You are a translation engine. Detect the source language of the user text and translate it ` +
      `to the language identified by the ISO 639-1 code "${targetLang}". ` +
      `Respond ONLY with strict JSON: {"translatedText": string, "detectedLanguage": <ISO 639-1 code of the source language>}. ` +
      `If the text is already in "${targetLang}", return it unchanged in "translatedText" and set "detectedLanguage" accordingly. ` +
      `Preserve tone and meaning. Do not add explanations or quotes.`;

    const oaResp = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openaiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: OPENAI_MODEL,
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: safeText },
        ],
      }),
    });

    if (!oaResp.ok) {
      const oaErrRaw = await oaResp.text();
      console.error("OpenAI error:", oaResp.status, oaErrRaw);
      return jsonResponse(
        {
          error: "Error llamando a OpenAI",
          detail: `OpenAI ${oaResp.status}: ${oaErrRaw.slice(0, 300)}`,
        },
        502
      );
    }

    const oaData = await oaResp.json();
    const contentStr = oaData.choices?.[0]?.message?.content ?? "{}";
    let parsed: { translatedText?: string; detectedLanguage?: string };
    try {
      parsed = JSON.parse(contentStr);
    } catch {
      return jsonError(502, "Respuesta OpenAI no es JSON válido");
    }
    const translatedText = (parsed.translatedText ?? "").trim();
    if (!translatedText) {
      return jsonError(502, "OpenAI no devolvió translatedText");
    }
    const detectedLanguage = parsed.detectedLanguage ?? "";

    // 7. Upsert en caché (service_role salta RLS). Idempotente por PK compuesta.
    const { error: upsertErr } = await supabase
      .from("message_translations")
      .upsert(
        {
          message_id: messageId,
          target_lang: targetLang,
          translated_text: translatedText,
          detected_lang: detectedLanguage,
        },
        { onConflict: "message_id,target_lang" }
      );
    if (upsertErr) console.warn("Cache write error:", upsertErr.message);

    // 8. Response
    return jsonResponse<TranslateResponse>({
      translatedText,
      detectedLanguage,
      fromCache: false,
    });
  } catch (error) {
    console.error("translate-message error:", error);
    return jsonError(500, (error as Error)?.message ?? "Error interno");
  }
});

// ---- helpers ----
function jsonResponse<T>(body: T, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function jsonError(status: number, message: string): Response {
  return jsonResponse({ error: message }, status);
}
