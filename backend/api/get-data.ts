import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase.js";
import { handleCors, requireAuth } from "../lib/auth.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "GET") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const userId = await requireAuth(req, res);
  if (!userId) return;

  const { data: user, error } = await supabase
    .from("users")
    .select("diary_entries, film_lists, watchlist")
    .eq("id", userId)
    .single();

  if (error || !user) {
    return res.status(404).json({ error: "USER_NOT_FOUND" });
  }

  return res.status(200).json({
    diaryEntries: user.diary_entries || [],
    filmLists: user.film_lists || [],
    watchlist: user.watchlist || [],
  });
}
