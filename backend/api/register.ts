console.log("SUPABASE_URL:", process.env.SUPABASE_URL);
console.log("SUPABASE_SERVICE_ROLE_KEY:", process.env.SUPABASE_SERVICE_ROLE_KEY);
//testing end
import type { VercelRequest, VercelResponse } from "@vercel/node";
import { v4 as uuidv4 } from "uuid";
import { supabase } from "../lib/supabase.ts";
import { handleCors, hashPassword, generateToken, sanitizeUser, type UserRow } from "../lib/auth.ts";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { username, email, password } = req.body;

  if (!username || !email || !password) {
    return res.status(400).json({ error: "Username, email, and password are required" });
  }

  if (username.length < 3 || username.length > 20 || !/^[a-zA-Z0-9._]+$/.test(username)) {
    return res.status(400).json({ error: "Invalid username format" });
  }

  if (password.length < 6 || password.length > 128) {
    return res.status(400).json({ error: "Password must be between 6 and 128 characters" });
  }

  const emailLower = email.toLowerCase().trim();
  const usernameLower = username.toLowerCase().trim();

  const { data: existingEmail, error: emailErr } = await supabase
    .from("users")
    .select("id")
    .eq("email", emailLower)
    .maybeSingle();

  if (emailErr) {
    return res.status(500).json({ error: "FAILED_TO_CHECK_EMAIL" });
  }

  if (existingEmail) {
    return res.status(409).json({ error: "EMAIL_EXISTS", message: "This email is already connected to an account." });
  }

  const { data: existingUsername, error: usernameErr } = await supabase
    .from("users")
    .select("id")
    .eq("username_lower", usernameLower)
    .maybeSingle();

  if (usernameErr) {
    return res.status(500).json({ error: "FAILED_TO_CHECK_USERNAME" });
  }

  if (existingUsername) {
    return res.status(409).json({ error: "USERNAME_EXISTS", message: "This username is already taken." });
  }

  const passwordHash = await hashPassword(password);
  const userId = uuidv4();
  const now = new Date().toISOString();

  const { data: newUser, error } = await supabase
    .from("users")
    .insert({
      id: userId,
      username: username.trim(),
      username_lower: usernameLower,
      email: emailLower,
      password_hash: passwordHash,
      profile_image_name: "avatar_1",
      custom_profile_image_url: null,
      bio: "",
      top_five_films: [],
      golden_popcorn_film_id: null,
      buddy_ids: [],
      watchlist: [],
      diary_entries: [],
      film_lists: [],
      status: "active",
      login_attempts: 0,
      last_failed_login: null,
      last_login_at: now,
      created_at: now,
      updated_at: now,
    })
    .select("*")
    .single();

  if (error || !newUser) {
    return res.status(500).json({ error: "FAILED_TO_CREATE_ACCOUNT" });
  }

  const token = await generateToken(userId);

  return res.status(201).json({
    token,
    user: sanitizeUser(newUser as UserRow),
  }
                             
                             
                             
                             );
}
