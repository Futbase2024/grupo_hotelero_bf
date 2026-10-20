import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface NotificationPayload {
  user_id?: string;
  user_ids?: string[];
  property_id?: string;
  booking_id?: string;
  type: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface FcmToken {
  id: string;
  token: string;
  user_id: string;
  platform: string;
}

async function getAccessToken(serviceAccount: Record<string, string>): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, "")
      .replace(/\+/g, "-")
      .replace(/\//g, "_");

  const toSign = `${encode(header)}.${encode(claim)}`;

  const keyData = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----\n?/, "")
    .replace(/\n?-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(toSign)
  );

  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");

  const jwt = `${toSign}.${sigB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  if (!tokenData.access_token) {
    throw new Error(`FCM OAuth2 error: ${JSON.stringify(tokenData)}`);
  }
  return tokenData.access_token;
}

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<{ success: boolean; error?: string }> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data: data ?? {},
          webpush: {
            headers: { Urgency: "high" },
            notification: {
              icon: "/icons/icon-192x192.png",
              badge: "/icons/badge-72x72.png",
              click_action: data?.url ?? "/",
            },
          },
          apns: {
            headers: { "apns-priority": "10" },
            payload: { aps: { sound: "default", badge: 1 } },
          },
          android: {
            priority: "high",
            notification: { sound: "default", channel_id: "bf_stay_default" },
          },
        },
      }),
    }
  );

  if (res.ok) return { success: true };

  const err = await res.json();
  const isInvalidToken = JSON.stringify(err).includes("REGISTRATION_TOKEN_NOT_REGISTERED") ||
                         JSON.stringify(err).includes("INVALID_ARGUMENT");
  return { success: false, error: isInvalidToken ? "INVALID_TOKEN" : JSON.stringify(err) };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    // ── Validar secrets de Firebase ──────────────────────────────────────────
    const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID");

    if (!serviceAccountRaw) {
      return new Response(
        JSON.stringify({ error: "Secret FIREBASE_SERVICE_ACCOUNT no configurado" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }
    if (!projectId) {
      return new Response(
        JSON.stringify({ error: "Secret FIREBASE_PROJECT_ID no configurado" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    let serviceAccount: Record<string, string>;
    try {
      serviceAccount = JSON.parse(serviceAccountRaw);
    } catch {
      return new Response(
        JSON.stringify({ error: "FIREBASE_SERVICE_ACCOUNT no es un JSON válido" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Parsear payload ───────────────────────────────────────────────────────
    const payload: NotificationPayload = await req.json();
    const { type, title, body, data, booking_id } = payload;

    if (!title || !body || !type) {
      return new Response(
        JSON.stringify({ error: "Campos requeridos: title, body, type" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // ── Resolver user_ids destino ─────────────────────────────────────────────
    let userIds: string[] = [];

    if (payload.user_ids?.length) {
      userIds = payload.user_ids;
    } else if (payload.user_id) {
      userIds = [payload.user_id];
    } else if (payload.property_id) {
      const { data: roles } = await supabase
        .from("user_roles")
        .select("user_id")
        .eq("property_id", payload.property_id)
        .in("role", ["admin", "staff"]);
      userIds = (roles ?? []).map((r: { user_id: string }) => r.user_id);
    }

    if (!userIds.length) {
      return new Response(
        JSON.stringify({ error: "No se encontraron usuarios destino" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Obtener tokens FCM activos ────────────────────────────────────────────
    const { data: tokens, error: tokensErr } = await supabase
      .from("fcm_tokens")
      .select("id, token, user_id, platform")
      .in("user_id", userIds)
      .eq("is_active", true);

    if (tokensErr) throw new Error(`Error leyendo tokens: ${tokensErr.message}`);

    if (!tokens?.length) {
      return new Response(
        JSON.stringify({ ok: true, message: "Sin tokens FCM registrados para estos usuarios", sent: 0, failed: 0 }),
        { headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Obtener access token de Firebase ─────────────────────────────────────
    const accessToken = await getAccessToken(serviceAccount);

    // ── Enviar a cada token ───────────────────────────────────────────────────
    let sent = 0;
    let failed = 0;
    const fcmResponses: object[] = [];
    const invalidTokenIds: string[] = [];

    await Promise.all(
      (tokens as FcmToken[]).map(async (t) => {
        const result = await sendFcmMessage(accessToken, projectId, t.token, title, body, {
          ...data,
          type,
        });

        if (result.success) {
          sent++;
          fcmResponses.push({ token_id: t.id, ok: true });
        } else {
          failed++;
          fcmResponses.push({ token_id: t.id, error: result.error });
          if (result.error === "INVALID_TOKEN") invalidTokenIds.push(t.id);
        }
      })
    );

    // ── Desactivar tokens inválidos ───────────────────────────────────────────
    if (invalidTokenIds.length) {
      await supabase
        .from("fcm_tokens")
        .update({ is_active: false })
        .in("id", invalidTokenIds);
    }

    // ── Registrar en notification_log ─────────────────────────────────────────
    const logStatus = failed === 0 ? "sent" : sent === 0 ? "failed" : "partial";
    await supabase.from("notification_log").insert({
      user_id: userIds.length === 1 ? userIds[0] : null,
      booking_id: booking_id ?? null,
      type,
      title,
      body,
      data: data ?? null,
      tokens_sent: sent,
      tokens_failed: failed,
      status: logStatus,
      fcm_response: fcmResponses,
    });

    return new Response(
      JSON.stringify({ ok: true, sent, failed, invalidated: invalidTokenIds.length }),
      { headers: { "Content-Type": "application/json" } }
    );

  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    console.error("[send-fcm] Error:", message);
    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
