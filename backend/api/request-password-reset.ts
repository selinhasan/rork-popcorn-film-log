import type { VercelRequest, VercelResponse } from "@vercel/node";
import { handleCors } from "../lib/auth";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  return res.status(200).json({
    success: false,
    message: "Password reset is not configured on this server.",
  });
}
