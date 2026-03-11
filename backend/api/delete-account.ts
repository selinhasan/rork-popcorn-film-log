import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase";
import { handleCors, requireAuth } from "../lib/auth";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = await requireAuth(req, res);
  if (!userId) return;

  const { error } = await supabase
    .from("users")
    .delete()
    .eq("id", userId);

  if (error) {
    return res.status(500).json({ error: "FAILED_TO_DELETE_ACCOUNT" });
  }

  return res.status(200).json({ success: true });
}
