const EXTENSOES_IMAGEM = new Set(["jpg", "jpeg", "png", "webp", "gif"]);

function comecaCom(bytes: Uint8Array, assinatura: number[]) {
  return assinatura.every((byte, index) => bytes[index] === byte);
}

function imagemValida(bytes: Uint8Array) {
  const png = comecaCom(bytes, [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  const jpeg = comecaCom(bytes, [0xff, 0xd8, 0xff]);
  const gif = comecaCom(bytes, [0x47, 0x49, 0x46, 0x38]);
  const webp =
    comecaCom(bytes, [0x52, 0x49, 0x46, 0x46]) &&
    comecaCom(bytes.slice(8), [0x57, 0x45, 0x42, 0x50]);
  return png || jpeg || gif || webp;
}

/** Validação básica do conteúdo, sem afirmar que o documento é autêntico. */
export async function validarDocumento(arquivo: Blob, nomeArquivo = "") {
  if (arquivo.size === 0) {
    throw new Error("O documento está vazio. Escolha um PDF ou uma imagem com conteúdo.");
  }

  const tipo = arquivo.type.toLowerCase();
  const extensao = nomeArquivo.split(".").pop()?.toLowerCase() ?? "";
  const pdf = tipo === "application/pdf" || extensao === "pdf";
  const imagem = tipo.startsWith("image/") || EXTENSOES_IMAGEM.has(extensao);

  if (!pdf && !imagem) {
    throw new Error("Envie o documento em PDF, JPG, PNG, WebP ou GIF.");
  }

  const bytes = new Uint8Array(await arquivo.slice(0, 12).arrayBuffer());
  const pdfValido = pdf && comecaCom(bytes, [0x25, 0x50, 0x44, 0x46, 0x2d]);

  if (!pdfValido && !(imagem && imagemValida(bytes))) {
    throw new Error("O arquivo está vazio, corrompido ou não corresponde a um PDF ou imagem válida.");
  }
}
