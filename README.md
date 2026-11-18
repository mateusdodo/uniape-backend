# UniApê — Backend (API)

API em Node.js + Express do UniApê, plataforma de moradia estudantil em Quixadá.
Ela traz as mesmas regras de negócio do app: imóveis, grupos, solicitações, moradias,
avaliações às cegas, divulgações, diretório de pessoas, perfis e o cálculo a pé até as paradas de ônibus.

## Requisitos
- Node.js 20 ou mais recente
- Um projeto Supabase (o mesmo que o app usa)

## 1. Subir para o GitHub
1. Descompacte `uniape-backend.zip`.
2. No GitHub, clique em **New repository**, dê o nome `uniape-backend` e crie (sem README).
3. No terminal, dentro da pasta descompactada:
```bash
git init
git add .
git commit -m "UniApê backend v2"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/uniape-backend.git
git push -u origin main
```

## 2. Instalar
```bash
git clone https://github.com/SEU-USUARIO/uniape-backend.git
cd uniape-backend
npm install
```

## 3. Configurar
Copie `.env.example` para `.env` e preencha:

| Variável | Onde achar |
|---|---|
| `SUPABASE_URL` | Supabase → Project Settings → API → Project URL |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase → Project Settings → API → chave `anon` / publishable |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API → chave `service_role` (secreta, nunca coloque no navegador nem no GitHub) |
| `PORT` | Porta da API (padrão 3000) |
| `CORS_ORIGIN` | Endereços do site que podem chamar a API, separados por vírgula |

## 4. Banco de dados
Se o banco já é o do app, pule esta etapa. Para um banco Supabase novo, abra
Supabase → SQL Editor, cole o conteúdo de `database/schema.sql` e execute.
Depois crie o bucket privado `documentos` em Storage.

## 5. Rodar
```bash
npm run dev     # desenvolvimento (recarrega ao salvar)
npm start       # produção
```
Abra http://localhost:3000 — deve aparecer `Backend do UniApê funcionando!`.

## 6. Login
O login usa as contas do Supabase (as mesmas do app).
```bash
curl -X POST localhost:3000/auth/login -H "content-type: application/json" \
  -d '{"email":"voce@email.com","senha":"suasenha"}'
```
Use o `token` da resposta nas rotas protegidas: `Authorization: Bearer <token>`.

## Rotas principais
| Método | Caminho | O que faz |
|---|---|---|
| POST | /auth/cadastro | Cria conta (nome, email, senha, telefone, tipo_conta) |
| POST | /auth/login | Entra e devolve o token |
| GET | /imoveis · /imoveis/:id | Lista e detalha imóveis |
| POST | /imoveis | Anuncia imóvel (proprietário) |
| GET | /imoveis/meus | Imóveis do proprietário, moradores e divulgações |
| POST | /imoveis/:id/anuncio | Abre/fecha anúncio `{aberto}` |
| POST | /imoveis/:id/moradores | Vincula morador `{usuario_id}` |
| GET | /usuarios?q=&tipo= · /usuarios/:id | Diretório e perfil público |
| GET | /perfil | Meu perfil |
| GET/POST | /grupos | Meus grupos / criar `{nome_grupo}` |
| POST · DELETE | /grupos/:id/membros(/:usuarioId) | Adiciona / remove membro |
| GET/POST | /solicitacoes | Minhas solicitações / solicitar |
| PUT | /solicitacoes/:id/status | Aceitar ou recusar `{decisao, whatsapp_url}` |
| GET | /moradias | Minhas moradias e avaliações |
| POST | /moradias/:id/encerrar · /confirmar-encerramento · /contestar-encerramento | Encerramento dos dois lados |
| POST | /moradias/:id/avaliacoes | Avaliar `{avaliados, estrelas, comentario}` |
| POST | /divulgacoes · PUT /divulgacoes/:id/aprovacao | Divulgar vagas / proprietário aprova |

`GET /rpc` lista todas as funções; `POST /rpc/<nome>` com `{ "data": {...} }` chama
qualquer uma delas — é assim que o app conversa com a API.

## 7. Ligar o app a esta API
1. Publique a API num endereço público (ex.: Render ou Railway): conecte o repositório,
   comando de instalação `npm install`, comando de início `npm start`, e cadastre as variáveis do passo 3.
2. No projeto do app (Lovable), peça para criar o segredo `UNIAPE_API_URL` com o endereço da API
   (ex.: `https://uniape-api.onrender.com`).
3. A partir daí todas as telas do app passam pela API. Sem esse segredo, o app
   continua funcionando sozinho.

## Estrutura
```
src/
  app.ts                  servidor Express
  config/supabase.ts      conexões com o Supabase
  middlewares/            verificação do login
  routes/                 rotas REST e /rpc
  funcoes/                regras de negócio (as mesmas do app)
  lib/server-fn.ts        adaptador que permite reaproveitar essas regras
database/schema.sql       todas as migrações do banco
```
