import "dotenv/config";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../types/database";

const URL = process.env.SUPABASE_URL;
const PUBLICA = process.env.SUPABASE_PUBLISHABLE_KEY;
const SERVICE = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!URL || !PUBLICA || !SERVICE) {
  throw new Error(
    "Configure SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY e SUPABASE_SERVICE_ROLE_KEY no arquivo .env",
  );
}

function fetchComChave(chave: string): typeof fetch {
  return (input, init) => {
    const h = new Headers(init?.headers);
    if (chave.startsWith("sb_") && h.get("Authorization") === `Bearer ${chave}`) h.delete("Authorization");
    h.set("apikey", chave);
    return fetch(input, { ...init, headers: h });
  };
}

const semSessao = { storage: undefined, persistSession: false, autoRefreshToken: false };

/** Cliente administrativo (ignora RLS) — usado só em operações já verificadas. */
export const supabaseAdmin = createClient<Database>(URL, SERVICE, {
  auth: semSessao,
  global: { fetch: fetchComChave(SERVICE) },
});

/** Cliente público, sem login. */
export const supabasePublico = createClient<Database>(URL, PUBLICA, {
  auth: semSessao,
  global: { fetch: fetchComChave(PUBLICA) },
});

/** Cliente que age como o usuário logado (RLS aplicada). */
export function supabaseDoUsuario(token: string) {
  return createClient<Database>(URL!, PUBLICA!, {
    auth: semSessao,
    global: { fetch: fetchComChave(PUBLICA!), headers: { Authorization: `Bearer ${token}` } },
  });
}
