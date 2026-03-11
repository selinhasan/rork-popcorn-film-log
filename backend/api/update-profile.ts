import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase.js";
import { handleCors, requireAuth, sanitizeUser, type UserRow } from "../lib/auth.js";

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

  if (input.username !== undefined) {
    const newLower = input.username.toLowerCase().trim();

    const { data: current, error: currentErr } = await supabase
      .from("users")
      .select("username")
      .eq("id", userId)
      .single();

    if (currentErr) {
      return res.status(404).json({ error: "USER_NOT_FOUND" });
    }

    if (current && typeof current.username === "string" && current.username.toLowerCase() !== newLower) {
      const { data: existing, error: existingErr } = await supabase
        .from("users")
        .select("id")
        .eq("username_lower", newLower)
        .neq("id", userId)
        .maybeSingle();

      if (existingErr) {
        return res.status(500).json({ error: "FAILED_TO_CHECK_USERNAME" });
      }

      if (existing) {
        return res.status(409).json({ error: "USERNAME_EXISTS" });
      }

      updates.username = input.username.trim();
      updates.username_lower = newLower;
    }
  }

  if (input.profileImageName !== undefined) updates.profile_image_name = input.profileImageName;
  if (input.customProfileImageURL !== undefined) updates.custom_profile_image_url = input.customProfileImageURL;
  if (input.bio !== undefined) updates.bio = input.bio;
  if (input.topFiveFilms !== undefined) updates.top_five_films = input.topFiveFilms;
  if (input.goldenPopcornFilmId !== undefined) updates.golden_popcorn_film_id = input.goldenPopcornFilmId;
  if (input.watchlist !== undefined) updates.watchlist = input.watchlist;
  if (input.buddyIds !== undefined) updates.buddy_ids = input.buddyIds;

  const { data: user, error } = await supabase
    .from("users")
    .update(updates)
    .eq("id", userId)
    .select("*")
    .single();

  if (error || !user) {
    return res.status(404).json({ error: "USER_NOT_FOUND" });
  }

  return res.status(200).json({ user: sanitizeUser(user as UserRow) });
}
