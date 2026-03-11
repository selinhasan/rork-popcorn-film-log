import { Hono } from "hono";
import { cors } from "hono/cors";
import { createClient } from "@supabase/supabase-js";
import { jwtVerify, SignJWT } from "jose";
import { v4 as uuidv4 } from "uuid";

const app = new Hono();

app.use("*", cors());

const ACCESS_TOKEN_EXPIRY = "7d";
const LOCK_DURATION_MS = 15 * 60 * 1000;
const MAX_LOGIN_ATTEMPTS = 10;
const JWT_ISSUER = "popcorn-film-log";
const JWT_AUDIENCE = "popcorn-film-log-app";

function getSupabase() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) throw new Error("Missing Supabase credentials");
  return createClient(url, key);
}

function getJwtSecret(): Uint8Array {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is required");
  return new TextEncoder().encode(secret);
}

type UserRow = {
  id: string;
  username: string;
  username_lower: string;
  email: string;
  password_hash: string;
  profile_image_name: string | null;
  custom_profile_image_url: string | null;
  bio: string | null;
  top_five_films: any[] | null;
  golden_popcorn_film_id: string | null;
  buddy_ids: string[] | null;
  watchlist: any[] | null;
  diary_entries: any[] | null;
  film_lists: any[] | null;
  status: string;
  login_attempts: number | null;
  last_failed_login: string | null;
  last_login_at: string | null;
  created_at: string;
  updated_at: string;
};

async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
  const bits = await crypto.subtle.deriveBits({ name: "PBKDF2", salt, iterations: 100000, hash: "SHA-256" }, keyMaterial, 256);
  const hashArray = Array.from(new Uint8Array(bits));
  const saltArray = Array.from(salt);
  return btoa(JSON.stringify({ salt: saltArray, hash: hashArray }));
}

async function verifyPassword(password: string, stored: string): Promise<boolean> {
  try {
    const { salt, hash } = JSON.parse(atob(stored));
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey("raw", encoder.encode(password), "PBKDF2", false, ["deriveBits"]);
    const bits = await crypto.subtle.deriveBits({ name: "PBKDF2", salt: new Uint8Array(salt), iterations: 100000, hash: "SHA-256" }, keyMaterial, 256);
    const newHash = Array.from(new Uint8Array(bits));
    return JSON.stringify(newHash) === JSON.stringify(hash);
  } catch {
    return false;
  }
}

async function generateToken(userId: string): Promise<string> {
  return new SignJWT({ userId })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setIssuedAt()
    .setExpirationTime(ACCESS_TOKEN_EXPIRY)
    .sign(getJwtSecret());
}

function sanitizeUser(user: UserRow) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    profileImageName: user.profile_image_name,
    customProfileImageURL: user.custom_profile_image_url,
    bio: user.bio,
    topFiveFilms: user.top_five_films || [],
    goldenPopcornFilmId: user.golden_popcorn_film_id,
    buddyIds: user.buddy_ids || [],
    watchlist: user.watchlist || [],
    diaryEntries: user.diary_entries || [],
    filmLists: user.film_lists || [],
    joinDate: user.created_at,
  };
}

async function authenticateRequest(authHeader: string | undefined): Promise<string | null> {
  if (!authHeader?.startsWith("Bearer ")) return null;
  try {
    const token = authHeader.slice(7);
    const { payload } = await jwtVerify(token, getJwtSecret(), { issuer: JWT_ISSUER, audience: JWT_AUDIENCE });
    if (typeof payload.userId === "string") return payload.userId;
    if (typeof payload.sub === "string") return payload.sub;
    return null;
  } catch {
    return null;
  }
}

app.get("/", (c) => c.json({ status: "ok", message: "Popcorn Film Log API" }));

app.post("/login", async (c) => {
  const body = await c.req.json();
  const { email, password } = body;

  if (!email || !password) {
    return c.json({ error: "Email and password are required" }, 400);
  }

  const supabase = getSupabase();
  const identifier = email.toLowerCase().trim();

  let { data: user, error: userError } = await supabase
    .from("users")
    .select("*")
    .eq("email", identifier)
    .maybeSingle();

  if (userError) return c.json({ error: "FAILED_TO_LOAD_USER" }, 500);

  if (!user) {
    const { data: byUsername, error: usernameErr } = await supabase
      .from("users")
      .select("*")
      .eq("username_lower", identifier)
      .maybeSingle();

    if (usernameErr) return c.json({ error: "FAILED_TO_LOAD_USER" }, 500);
    user = byUsername;
  }

  if (!user) return c.json({ error: "INVALID_CREDENTIALS" }, 401);

  let userRow = user as UserRow;

  if (userRow.status === "locked") {
    const lastFailed = userRow.last_failed_login ? new Date(userRow.last_failed_login).getTime() : null;
    const lockExpired = lastFailed !== null && Date.now() - lastFailed > LOCK_DURATION_MS;

    if (lockExpired) {
      const { data: reset, error: resetErr } = await supabase
        .from("users")
        .update({ status: "active", login_attempts: 0, last_failed_login: null, updated_at: new Date().toISOString() })
        .eq("id", userRow.id)
        .select("*")
        .single();

      if (resetErr || !reset) return c.json({ error: "FAILED_TO_RESET_LOCK" }, 500);
      userRow = reset as UserRow;
    } else {
      return c.json({ error: "ACCOUNT_LOCKED" }, 403);
    }
  }

  if (userRow.status === "suspended") return c.json({ error: "ACCOUNT_SUSPENDED" }, 403);
  if (userRow.status !== "active") return c.json({ error: "ACCOUNT_DISABLED" }, 403);

  const valid = await verifyPassword(password, userRow.password_hash);

  if (!valid) {
    const newAttempts = (userRow.login_attempts || 0) + 1;
    const now = new Date().toISOString();
    const updates: Record<string, unknown> = { login_attempts: newAttempts, last_failed_login: now, updated_at: now };
    if (newAttempts >= MAX_LOGIN_ATTEMPTS) updates.status = "locked";
    await supabase.from("users").update(updates).eq("id", userRow.id);
    return c.json({ error: "INVALID_CREDENTIALS" }, 401);
  }

  const now = new Date().toISOString();
  const { data: updatedUser, error: loginUpdateErr } = await supabase
    .from("users")
    .update({ status: "active", login_attempts: 0, last_failed_login: null, last_login_at: now, updated_at: now })
    .eq("id", userRow.id)
    .select("*")
    .single();

  if (loginUpdateErr || !updatedUser) return c.json({ error: "FAILED_TO_UPDATE_LOGIN_STATE" }, 500);

  const token = await generateToken(userRow.id);
  return c.json({ token, user: sanitizeUser(updatedUser as UserRow) });
});

app.post("/register", async (c) => {
  const body = await c.req.json();
  const { username, email, password } = body;

  if (!username || !email || !password) {
    return c.json({ error: "Username, email, and password are required" }, 400);
  }

  if (username.length < 3 || username.length > 20 || !/^[a-zA-Z0-9._]+$/.test(username)) {
    return c.json({ error: "INVALID_USERNAME", message: "Username must be 3-20 characters (letters, numbers, dots, underscores)." }, 400);
  }

  if (password.length < 6 || password.length > 128) {
    return c.json({ error: "INVALID_PASSWORD", message: "Password must be between 6 and 128 characters." }, 400);
  }

  const supabase = getSupabase();
  const emailLower = email.toLowerCase().trim();
  const usernameLower = username.toLowerCase().trim();

  const { data: existingEmail } = await supabase.from("users").select("id").eq("email", emailLower).maybeSingle();
  if (existingEmail) return c.json({ error: "EMAIL_EXISTS", message: "This email is already connected to an account." }, 409);

  const { data: existingUsername } = await supabase.from("users").select("id").eq("username_lower", usernameLower).maybeSingle();
  if (existingUsername) return c.json({ error: "USERNAME_EXISTS", message: "This username is already taken." }, 409);

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

  if (error || !newUser) return c.json({ error: "FAILED_TO_CREATE_ACCOUNT" }, 500);

  const token = await generateToken(userId);
  return c.json({ token, user: sanitizeUser(newUser as UserRow) }, 201);
});

app.get("/get-profile", async (c) => {
  const userId = await authenticateRequest(c.req.header("Authorization"));
  if (!userId) return c.json({ error: "UNAUTHORIZED" }, 401);

  const supabase = getSupabase();

  const { data: authUser } = await supabase
    .from("users")
    .select("id, status, last_failed_login, login_attempts")
    .eq("id", userId)
    .maybeSingle();

  if (!authUser) return c.json({ error: "UNAUTHORIZED" }, 401);
  if (authUser.status === "suspended") return c.json({ error: "ACCOUNT_SUSPENDED" }, 403);
  if (authUser.status !== "active" && authUser.status !== "locked") return c.json({ error: "ACCOUNT_DISABLED" }, 403);

  const { data: user, error } = await supabase.from("users").select("*").eq("id", userId).single();
  if (error || !user) return c.json({ error: "USER_NOT_FOUND" }, 404);

  return c.json({ user: sanitizeUser(user as UserRow) });
});

export default app;
