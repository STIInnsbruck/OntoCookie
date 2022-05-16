import express from 'express';
import cors from 'cors';

import { sparqlRouter } from "./routes/sparql.router.js";

const PORT = 58080;
const app = express();

app.use(cors());
app.use(express.json());
app.use(sparqlRouter);

app.get("/", (req, res) => {
  res.send("API is running...");
});

app.listen(PORT, () => {
  console.log(`⚡️[server]: Server is running at http://localhost:${PORT}`);
});

