/**
 * Adaptador: permite reaproveitar no Express exatamente as mesmas regras de
 * negócio escritas para o app (createServerFn), sem duplicar lógica.
 */
export const requireSupabaseAuth = Symbol("requireSupabaseAuth");

export type Funcao = {
  __funcao: true;
  method: "GET" | "POST";
  exigeLogin: boolean;
  validar?: (data: any) => any;
  executar: (args: { data: any; context: any }) => Promise<any>;
};

export function createServerFn(opts: { method: "GET" | "POST" }) {
  const f: Partial<Funcao> = { __funcao: true, method: opts.method, exigeLogin: false };
  const builder = {
    middleware(lista: unknown[]) {
      f.exigeLogin = lista.includes(requireSupabaseAuth);
      return builder;
    },
    inputValidator(v: (data: any) => any) {
      f.validar = v;
      return builder;
    },
    handler(h: (args: { data: any; context: any }) => Promise<any>) {
      f.executar = h;
      return f as Funcao;
    },
  };
  return builder;
}
