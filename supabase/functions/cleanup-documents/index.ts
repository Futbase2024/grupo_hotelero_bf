// Supabase Edge Function: cleanup-documents
//
// Borra del bucket `guest-documents` las imágenes de DNI / NIE / pasaporte cuyo
// plazo ya ha vencido y marca su fila como borrada (`deleted_at`). La fila se
// conserva como constancia; los datos del huésped siguen en `guests`.
//
// Las reglas (24 h tras validar, al cancelar, tras el check-out si nunca se
// validó, salvo retención) viven en SQL: guest_documents_due_for_deletion().
//
// La llama pg_cron cada 15 min (job `cleanup-guest-documents`) con la cabecera
// `x-internal-secret`. Desplegar con verify_jwt = false.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const BUCKET = "guest-documents";
const BATCH_LIMIT = 1000;
const REMOVE_CHUNK = 100;
const ORPHAN_LIMIT = 500;

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const admin = createClient(supabaseUrl, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

interface DueDocument {
  id: string;
  booking_id: string;
  storage_path: string;
  reason: string;
}

// ── Solo llamadas internas ──────────────────────────────────────────────────
// Antes bastaba con un User-Agent que contuviera "Supabase", cosa que puede
// poner cualquiera. Ahora: secreto interno de Vault o la service role.
let cachedInternalSecret: string | null = null;

async function isInternalCall(req: Request): Promise<boolean> {
  const bearer = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (serviceKey && bearer === serviceKey) return true;

  const provided = req.headers.get("x-internal-secret");
  if (!provided) return false;

  if (!cachedInternalSecret) {
    const { data, error } = await admin.rpc("internal_functions_secret");
    if (error || !data) {
      console.error("[cleanup-documents] No se pudo leer el secreto interno:", error?.message);
      return false;
    }
    cachedInternalSecret = data as string;
  }
  return provided === cachedInternalSecret;
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// Archivos del bucket sin fila en guest_documents (más de 24 h). Ninguna regla
// por reserva los alcanza, así que se limpian aparte en cada pasada.
async function removeOrphanFiles(): Promise<number> {
  const { data, error } = await admin.rpc("guest_documents_orphan_files", {
    p_limit: ORPHAN_LIMIT,
  });
  if (error) {
    console.error("❌ [cleanup-documents] Error buscando huérfanos:", error.message);
    return 0;
  }

  const names = ((data ?? []) as { name: string }[]).map((r) => r.name);
  let removed = 0;
  for (let i = 0; i < names.length; i += REMOVE_CHUNK) {
    const chunk = names.slice(i, i + REMOVE_CHUNK);
    const { error: storageError } = await admin.storage.from(BUCKET).remove(chunk);
    if (storageError) {
      console.error("❌ [cleanup-documents] Error borrando huérfanos:", storageError.message);
      continue;
    }
    removed += chunk.length;
  }
  if (removed > 0) console.log(`🧹 [cleanup-documents] ${removed} archivos huérfanos borrados`);
  return removed;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  if (!(await isInternalCall(req))) {
    return json({ error: "unauthorized" }, 401);
  }

  const startedAt = new Date().toISOString();
  let deleted = 0;
  let failed = 0;
  const byReason: Record<string, number> = {};

  try {
    const { data, error } = await admin.rpc("guest_documents_due_for_deletion", {
      p_limit: BATCH_LIMIT,
    });
    if (error) throw error;

    const due = (data ?? []) as DueDocument[];
    if (due.length === 0) {
      const orphans = await removeOrphanFiles();
      return json({ success: true, startedAt, deleted: 0, failed: 0, orphans });
    }

    console.log(`🧹 [cleanup-documents] ${due.length} documentos a borrar`);

    for (let i = 0; i < due.length; i += REMOVE_CHUNK) {
      const chunk = due.slice(i, i + REMOVE_CHUNK);

      // 1. Archivos. Un archivo que ya no existe no da error: se marca igual.
      const { error: storageError } = await admin.storage
        .from(BUCKET)
        .remove(chunk.map((d) => d.storage_path));

      if (storageError) {
        // No se marca nada: el siguiente pase lo reintentará.
        console.error("❌ [cleanup-documents] Error de Storage:", storageError.message);
        failed += chunk.length;
        continue;
      }

      // 2. Filas, agrupadas por motivo
      const reasons = new Map<string, string[]>();
      for (const d of chunk) {
        reasons.set(d.reason, [...(reasons.get(d.reason) ?? []), d.id]);
      }

      for (const [reason, ids] of reasons) {
        const { error: updateError } = await admin
          .from("guest_documents")
          .update({ deleted_at: new Date().toISOString(), deleted_reason: reason })
          .in("id", ids)
          .is("deleted_at", null);

        if (updateError) {
          // Los archivos ya no están; el siguiente pase volverá a marcarlos.
          console.error("❌ [cleanup-documents] Error marcando filas:", updateError.message);
          failed += ids.length;
          continue;
        }

        deleted += ids.length;
        byReason[reason] = (byReason[reason] ?? 0) + ids.length;
      }
    }

    const orphans = await removeOrphanFiles();

    console.log(`✅ [cleanup-documents] Borrados ${deleted}, fallidos ${failed}`, byReason);
    return json({ success: failed === 0, startedAt, deleted, failed, byReason, orphans });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("❌ [cleanup-documents] Error general:", message);
    return json({ success: false, startedAt, deleted, failed, error: message }, 500);
  }
});
