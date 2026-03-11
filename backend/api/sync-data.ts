import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase.js";
import { handleCors, requireAuth } from "../lib/auth.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = await requireAuth(req, res);
  if (!userId) return;

  const input = req.body || {};
  const updates: Record<string, unknown> = {
    updated_at: new Date().toISOString(),
  };

  if (input.diaryEntries !== undefined) updates.diary_entries = input.diaryEntries;
  if (input.filmLists !== undefined) updates.film_lists = input.filmLists;
  if (input.watchlist !== undefined) updates.watchlist = input.watchlist;

  const { error } = await supabase
    .from("users")
    .update(updates)
    .eq("id", userId);

  if (error) {
    return res.status(500).json({ error: "FAILED_TO_SYNC_DATA" });
  }

  return res.status(200).json({ success: true });
}
