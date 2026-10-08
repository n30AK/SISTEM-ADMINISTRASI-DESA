import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  const count = async (table: string) => {
    const { count, error } = await supabase.from(table).select("*", { count: "exact", head: true });
    return { count: count ?? 0, error: error?.message ?? null };
  };

  const [core, requests, documents, sync] = await Promise.all([
    supabase.from("platform_core").select("platform_name,platform_version,environment").limit(1).maybeSingle(),
    count("demo_requests"),
    count("demo_documents"),
    count("opensid_sync_batches"),
  ]);

  return new Response(JSON.stringify({
    status: "ok",
    service: "Sistem Administrasi Desa Preview API",
    generated_at: new Date().toISOString(),
    supabase: {
      connected: true,
      platform: core.data ?? null,
      demo_requests: requests.count,
      demo_documents: documents.count,
      opensid_sync_batches: sync.count,
    },
  }), {
    headers: { ...cors, "Content-Type": "application/json; charset=utf-8" },
  });
});