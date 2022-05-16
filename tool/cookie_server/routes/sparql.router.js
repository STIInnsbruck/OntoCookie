import express from "express";
import { annotate } from "../controllers/insert.controller.js";
import { getData } from "../controllers/select.controller.js";
import { deleteData } from "../controllers/delete.controller.js";

const router = express.Router();

router.post("/api/insert", annotate);
router.post("/api/select", getData);
router.post("/api/delete", deleteData);

export { router as sparqlRouter };
