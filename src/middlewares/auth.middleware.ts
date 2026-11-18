import type { Request, Response, NextFunction } from "express";
import { supabaseDoUsuario } from "../config/supabase";

export interface RequestAutenticado extends Request {
  usuario?: { id: string; email?: string; token: string };
}

/** Lê o token "Bearer ..." da sessão do Supabase e confirma quem é o usuário. */
export async function identificar(req: RequestAutenticado) {
  const h = req.headers.authorization;
  if (!h?.startsWith("Bearer ")) return null;
  const token = h.slice(7);
  if (token.split(".").length !== 3) return null;
  const sb = supabaseDoUsuario(token);
  const { data, error } = await sb.auth.getClaims(token);
  if (error || !data?.claims?.sub) return null;
  req.usuario = { id: data.claims.sub, email: data.claims.email as string | undefined, token };
  return { supabase: sb, userId: data.claims.sub, claims: data.claims };
}

export async function autenticar(req: RequestAutenticado, res: Response, next: NextFunction) {
  const ctx = await identificar(req);
  if (!ctx) return res.status(401).json({ error: "Token inválido ou ausente" });
  next();
}
