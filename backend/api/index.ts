import type { VercelRequest, VercelResponse } from "@vercel/node";
import { handleCors } from "../lib/auth";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  return res.status(200).json({ status: "ok", message: "Popcorn Film Log API is running" });
}
