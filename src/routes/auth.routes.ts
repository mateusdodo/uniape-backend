import { Router } from "express";
import { z } from "zod";
import { supabasePublico } from "../config/supabase";

const router = Router();

router.post("/login", async (req, res) => {
  const p = z.object({ email: z.string().email(), senha: z.string().min(6) }).safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "Informe e-mail e senha" });
  const { data, error } = await supabasePublico.auth.signInWithPassword({ email: p.data.email, password: p.data.senha });
  if (error || !data.session) return res.status(401).json({ error: error?.message ?? "Login inválido" });
  res.json({ token: data.session.access_token, refresh_token: data.session.refresh_token, usuario: data.user });
});

router.post("/cadastro", async (req, res) => {
  const p = z
    .object({
      nome: z.string().min(2),
      email: z.string().email(),
      senha: z.string().min(6),
      telefone: z.string().max(30).optional(),
      tipo_conta: z.enum(["comum", "proprietario"]).default("comum"),
    })
    .safeParse(req.body);
  if (!p.success) return res.status(400).json({ error: "Dados inválidos", detalhes: p.error.issues });
  const { nome, email, senha, telefone, tipo_conta } = p.data;
  const { data, error } = await supabasePublico.auth.signUp({
    email,
    password: senha,
    options: { data: { nome, telefone, tipo_conta } },
  });
  if (error) return res.status(400).json({ error: error.message });
  res.status(201).json({ usuario: data.user, mensagem: "Confirme seu e-mail para entrar." });
});

export default router;
