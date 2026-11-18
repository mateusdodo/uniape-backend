import type { Funcao } from "../lib/server-fn";
import * as moradia from "./moradia.functions";
import * as painel from "./painel.functions";
import * as usuarios from "./usuarios.functions";

export const funcoes: Record<string, Funcao> = {};
for (const mod of [moradia, painel, usuarios]) {
  for (const [nome, valor] of Object.entries(mod)) {
    if (valor && typeof valor === "object" && (valor as Funcao).__funcao) funcoes[nome] = valor as Funcao;
  }
}
