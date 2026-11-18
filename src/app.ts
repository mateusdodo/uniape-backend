import "dotenv/config";
import express from "express";
import cors from "cors";
import authRoutes from "./routes/auth.routes";
import funcoesRoutes from "./routes/funcoes.routes";
import { autenticar, type RequestAutenticado } from "./middlewares/auth.middleware";

const app = express();
app.use(cors({ origin: process.env.CORS_ORIGIN ? process.env.CORS_ORIGIN.split(",") : "*" }));
app.use(express.json({ limit: "2mb" }));

app.get("/", (_req, res) => res.json({ message: "Backend do UniApê funcionando!" }));
app.use("/auth", authRoutes);
app.get("/teste-auth", autenticar, (req: RequestAutenticado, res) =>
  res.json({ message: "Você está autenticado!", usuario: { id: req.usuario?.id, email: req.usuario?.email } }),
);
app.use("/", funcoesRoutes);

const porta = Number(process.env.PORT ?? 3000);
app.listen(porta, () => console.log(`Servidor rodando em http://localhost:${porta}`));
