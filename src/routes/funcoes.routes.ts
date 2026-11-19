import { Router, type Response } from "express";
import { funcoes } from "../funcoes";
import { identificar, type RequestAutenticado } from "../middlewares/auth.middleware";

export async function executar(nome: string, data: unknown, req: RequestAutenticado, res: Response) {
  const f = funcoes[nome];
  if (!f) return res.status(404).json({ error: `Função "${nome}" não existe` });
  try {
    let context: unknown = {};
    if (f.exigeLogin) {
      const ctx = await identificar(req);
      if (!ctx) return res.status(401).json({ error: "Faça login para continuar" });
      context = ctx;
    }
    const entrada = f.validar ? f.validar(data ?? {}) : data;
    const resultado = await f.executar({ data: entrada, context });
    res.json({ data: resultado ?? null });
  } catch (e: any) {
    const status = /Unauthorized/.test(e?.message ?? "") ? 401 : 400;
    res.status(status).json({ error: e?.issues ? "Dados inválidos" : (e?.message ?? String(e)), detalhes: e?.issues });
  }
}

const router = Router();

/** Lista as funções disponíveis. */
router.get("/rpc", (_req, res) => {
  res.json(Object.entries(funcoes).map(([nome, f]) => ({ nome, metodo: f.method, exigeLogin: f.exigeLogin })));
});

/** Chamada genérica usada pelo app: POST /rpc/<nome> { data } */
router.post("/rpc/:nome", (req, res) => executar(String(req.params.nome), req.body?.data, req, res));

/** Rotas REST amigáveis (mesmo estilo do backend original). */
type Rota = [metodo: "get" | "post" | "put" | "delete", caminho: string, funcao: string, montar?: (req: RequestAutenticado) => unknown];
const corpo = (req: RequestAutenticado) => req.body;
const comId = (campo: string) => (req: RequestAutenticado) => ({ ...req.body, [campo]: req.params.id });

const rotas: Rota[] = [
  ["get", "/imoveis", "listImoveis"],
  ["get", "/imoveis/meus", "listMeusImoveis"],
  ["get", "/imoveis/:id", "getImovel", (r) => ({ id: r.params.id })],
  ["post", "/imoveis", "createImovel", corpo],
  ["delete", "/imoveis/:id", "excluirImovel", (r) => ({ imovel_id: r.params.id })],
  ["post", "/imoveis/:id/anuncio", "alternarAnuncio", comId("imovel_id")],
  ["post", "/imoveis/:id/moradores", "vincularMorador", comId("imovel_id")],
  ["get", "/usuarios", "listUsuarios", (r) => ({ q: r.query.q ?? "", tipo: r.query.tipo ?? "todos" })],
  ["get", "/usuarios/buscar", "buscarPessoas", (r) => ({ termo: r.query.q ?? "" })],
  ["get", "/usuarios/:id", "getPerfilPublico", (r) => ({ id: r.params.id })],
  ["get", "/perfil", "getMeuPerfil"],
  ["put", "/perfil/tipo-conta", "definirTipoConta", corpo],
  ["put", "/perfil/documento", "salvarDocumento", corpo],
  ["get", "/grupos", "listMeusGrupos"],
  ["post", "/grupos", "createGrupo", corpo],
  ["post", "/grupos/:id/membros", "adicionarMembro", comId("grupo_id")],
  ["delete", "/grupos/:id/membros/:usuarioId", "removerMembro", (r) => ({ grupo_id: r.params.id, usuario_id: r.params.usuarioId })],
  ["get", "/solicitacoes", "listSolicitacoes"],
  ["post", "/solicitacoes", "createSolicitacao", corpo],
  ["put", "/solicitacoes/:id/status", "responderSolicitacao", comId("solicitacao_id")],
  ["post", "/solicitacoes/:id/cancelar", "cancelarSolicitacao", comId("solicitacao_id")],
  ["get", "/moradias", "listMinhasMoradias"],
  ["post", "/moradias/:id/encerrar", "pedirEncerramento", comId("moradia_id")],
  ["post", "/moradias/:id/confirmar-encerramento", "confirmarEncerramento", comId("moradia_id")],
  ["post", "/moradias/:id/contestar-encerramento", "contestarEncerramento", comId("moradia_id")],
  ["post", "/moradias/:id/avaliacoes", "avaliarMoradia", comId("moradia_id")],
  ["post", "/divulgacoes", "criarChamado", corpo],
  ["post", "/divulgacoes/:id/encerrar", "encerrarChamado", comId("chamado_id")],
  ["put", "/divulgacoes/:id/aprovacao", "aprovarChamado", comId("chamado_id")],
];

for (const [metodo, caminho, nome, montar] of rotas) {
  router[metodo](caminho, (req, res) => executar(nome, montar ? montar(req) : undefined, req, res));
}

export default router;
