import { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase";

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email, username } = req.body;

  if (!email || !username) {
    return res.status(400).json({ error: "Email and username are required" });
  }

  const emailLower = email.toLowerCase().trim();
  const usernameLower = username.toLowerCase().trim();

  const { data: existingEmail, error: emailCheckError } = await supabase
    .from("users")
    .select("id")
    .eq("email", emailLower)
    .maybeSingle();

  if (emailCheckError) {
    return res.status(500).json({ error: "Failed to check email" });
  }

  if (existingEmail) {
    return res.status(409).json({ error: "EMAIL_EXISTS", message: "This email is already connected to an account." });
  }

  const { data: existingUsername, error: usernameCheckError } = await supabase
    .from("users")
    .select("id")
    .eq("username_lower", usernameLower)
    .maybeSingle();

  if (usernameCheckError) {
    return res.status(500).json({ error: "Failed to check username" });
  }

  if (existingUsername) {
    return res.status(409).json({ error: "USERNAME_EXISTS", message: "This username is already taken." });
  }

  const now = new Date().toISOString();

  const { data, error } = await supabase
    .from("users")
    .insert({
      username: username.trim(),
      username_lower: usernameLower,
      email: emailLower,
      status: "active",
      login_attempts: 0,
      created_at: now,
      updated_at: now,
    })
    .select("*")
    .single();

  if (error) {
    return res.status(500).json({ error: "Failed to create account", details: error.message });
  }

  return res.status(201).json({
    user: data,
    needsOnboarding: true,
  });
}
