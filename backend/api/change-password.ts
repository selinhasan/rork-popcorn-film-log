import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase";
import { handleCors, requireAuth, verifyPassword, hashPassword } from "../lib/auth";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = await requireAuth(req, res);
  if (!userId) return;

  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ error: "Current and new password are required" });
  }

  if (newPassword.length < 6 || newPassword.length > 128) {
    return res.status(400).json({ error: "New password must be between 6 and 128 characters" });
  }

  const { data: user, error } = await supabase
    .from("users")
    .select("password_hash")
    .eq("id", userId)
    .single();

  if (error || !user) {
    return res.status(404).json({ error: "USER_NOT_FOUND" });
  }

  const valid = await verifyPassword(currentPassword, user.password_hash);

  if (!valid) {
    return res.status(401).json({ error: "INVALID_CREDENTIALS" });
  }

  const newHash = await hashPassword(newPassword);

  const { error: updateErr } = await supabase
    .from("users")
    .update({
      password_hash: newHash,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (updateErr) {
    return res.status(500).json({ error: "FAILED_TO_CHANGE_PASSWORD" });
  }

  return res.status(200).json({ success: true });
}
