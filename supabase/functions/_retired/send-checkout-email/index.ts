// ============================================================================
// COPIA DE SEGURIDAD — versión 17 desplegada de la Edge Function `send-checkout-email`
// Retirada el 2026-10-19: desplegada sin autenticación (cualquiera podía
// enviar emails con la marca BF Stay) y sin uso en la app, la BD ni el cron.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// supabase/functions/send-checkout-email/index.ts
import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

type Payload = {
  to_email: string;
  to_name?: string;
  params: {
    nombre_huesped: string;
    nombre_propiedad: string;
    fecha_salida: string;
    hora_salida: string;
    link_valoracion?: string;
    telefono_soporte?: string;
  };
  booking_id?: string;
  unit_id?: string;
};

function jsonResponse(body: unknown, status = 200, extraHeaders: HeadersInit = {}) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      ...extraHeaders,
    },
  });
}

function corsHeaders(origin = "*") {
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

function isValidEmail(email: string) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders() });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders());
  }

  const BREVO_API_KEY = Deno.env.get("BREVO_API_KEY");
  if (!BREVO_API_KEY) {
    return jsonResponse({ error: "Missing BREVO_API_KEY env var" }, 500, corsHeaders());
  }

  const templateId = Number(Deno.env.get("BREVO_TEMPLATE_CHECKOUT_ID") ?? "4");
  if (!Number.isFinite(templateId) || templateId <= 0) {
    return jsonResponse({ error: "Invalid BREVO_TEMPLATE_CHECKOUT_ID" }, 500, corsHeaders());
  }

  let payload: Payload;
  try {
    payload = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400, corsHeaders());
  }

  if (!payload?.to_email || !isValidEmail(payload.to_email)) {
    return jsonResponse({ error: "to_email is required and must be valid" }, 400, corsHeaders());
  }

  const p = payload.params;
  const requiredKeys: Array<keyof Payload["params"]> = [
    "nombre_huesped",
    "nombre_propiedad",
    "fecha_salida",
    "hora_salida",
  ];

  for (const k of requiredKeys) {
    if (!p?.[k] || String(p[k]).trim().length === 0) {
      return jsonResponse({ error: `params.${k} is required` }, 400, corsHeaders());
    }
  }

  const brevoBody = {
    to: [{ email: payload.to_email, name: payload.to_name }],
    templateId,
    params: {
      ...payload.params,
      link_valoracion: payload.params.link_valoracion ?? "",
      telefono_soporte: payload.params.telefono_soporte ?? "",
    },
  };

  const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
  const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  const supabase =
    SUPABASE_URL && SUPABASE_SERVICE_ROLE_KEY
      ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
          auth: { persistSession: false },
        })
      : null;

  let brevoRespText = "";
  let brevoStatus = 0;

  try {
    const brevoResp = await fetch("https://api.brevo.com/v3/smtp/email", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "api-key": BREVO_API_KEY,
        "accept": "application/json",
      },
      body: JSON.stringify(brevoBody),
    });

    brevoStatus = brevoResp.status;
    brevoRespText = await brevoResp.text();

    if (!brevoResp.ok) {
      if (supabase) {
        await supabase.from("email_logs").insert({
          kind: "checkout",
          to_email: payload.to_email,
          template_id: templateId,
          status: "error",
          provider: "brevo",
          provider_status: brevoStatus,
          provider_response: brevoRespText,
          booking_id: payload.booking_id ?? null,
          unit_id: payload.unit_id ?? null,
          params: payload.params,
        });
      }

      return jsonResponse(
        {
          error: "Brevo send failed",
          provider_status: brevoStatus,
          provider_response: brevoRespText,
        },
        502,
        corsHeaders(),
      );
    }

    if (supabase) {
      await supabase.from("email_logs").insert({
        kind: "checkout",
        to_email: payload.to_email,
        template_id: templateId,
        status: "sent",
        provider: "brevo",
        provider_status: brevoStatus,
        provider_response: brevoRespText,
        booking_id: payload.booking_id ?? null,
        unit_id: payload.unit_id ?? null,
        params: payload.params,
      });
    }

    return jsonResponse(
      { ok: true, templateId, provider_status: brevoStatus, provider_response: brevoRespText },
      200,
      corsHeaders(),
    );
  } catch (e) {
    if (supabase) {
      await supabase.from("email_logs").insert({
        kind: "checkout",
        to_email: payload.to_email,
        template_id: templateId,
        status: "error",
        provider: "brevo",
        provider_status: brevoStatus || null,
        provider_response: brevoRespText || String(e),
        booking_id: payload.booking_id ?? null,
        unit_id: payload.unit_id ?? null,
        params: payload.params,
      });
    }

    return jsonResponse({ error: "Unexpected error", details: String(e) }, 500, corsHeaders());
  }
});
