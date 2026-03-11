import type { VercelRequest, VercelResponse } from "@vercel/node";
import { supabase } from "../lib/supabase.js";
import {
  handleCors,
  verifyPassword,
  generateToken,
  sanitizeUser,
  MAX_LOGIN_ATTEMPTS,
  LOCK_DURATION_MS,
  type UserRow,
} from "../lib/auth.js";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (handleCors(req, res)) return;

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  const identifier = email.toLowerCase().trim();

  let { data: user, error: userError } = await supabase
    .from("users")
    .select("*")
    .eq("email", identifier)
    .maybeSingle();

  if (userError) {
    return res.status(500).json({ error: "FAILED_TO_LOAD_USER" });
  }

  if (!user) {
    const { data: byUsername, error: usernameErr } = await supabase
      .from("users")
      .select("*")
      .eq("username_lower", identifier)
      .maybeSingle();

    if (usernameErr) {
      return res.status(500).json({ error: "FAILED_TO_LOAD_USER" });
    }

    user = byUsername;
  }

  if (!user) {
    return res.status(401).json({ error: "INVALID_CREDENTIALS" });
  }

  let userRow = user as UserRow;

  if (userRow.status === "locked") {
    const lastFailed = userRow.last_failed_login
      ? new Date(userRow.last_failed_login).getTime()
      : null;
    const lockExpired = lastFailed !== null && Date.now() - lastFailed > LOCK_DURATION_MS;

    if (lockExpired) {
      const { data: reset, error: resetErr } = await supabase
        .from("users")
        .update({
          status: "active",
          login_attempts: 0,
          last_failed_login: null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userRow.id)
        .select("*")
        .single();

      if (resetErr || !reset) {
        return res.status(500).json({ error: "FAILED_TO_RESET_LOCK" });
      }

      userRow = reset as UserRow;
    } else {
      return res.status(403).json({ error: "ACCOUNT_LOCKED" });
    }
  }

  if (userRow.status === "suspended") {
    return res.status(403).json({ error: "ACCOUNT_SUSPENDED" });
  }

  if (userRow.status !== "active") {
    return res.status(403).json({ error: "ACCOUNT_DISABLED" });
  }

  const valid = await verifyPassword(password, userRow.password_hash);

  if (!valid) {
    const newAttempts = (userRow.login_attempts || 0) + 1;
    const now = new Date().toISOString();

    const updates: Record<string, unknown> = {
      login_attempts: newAttempts,
      last_failed_login: now,
      updated_at: now,
    };

    if (newAttempts >= MAX_LOGIN_ATTEMPTS) {
      updates.status = "locked";
    }

    await supabase.from("users").update(updates).eq("id", userRow.id);

    return res.status(401).json({ error: "INVALID_CREDENTIALS" });
  }

  const now = new Date().toISOString();

  const { data: updatedUser, error: loginUpdateErr } = await supabase
    .from("users")
    .update({
      status: "active",
      login_attempts: 0,
      last_failed_login: null,
      last_login_at: now,
      updated_at: now,
    })
    .eq("id", userRow.id)
    .select("*")
    .single();

  if (loginUpdateErr || !updatedUser) {
    return res.status(500).json({ error: "FAILED_TO_UPDATE_LOGIN_STATE" });
  }

  const token = await generateToken(userRow.id);

  return res.status(200).json({
    token,
    user: sanitizeUser(updatedUser as UserRow),
  });
}
