import type { VercelRequest, VercelResponse } from "@vercel/node";
import { jwtVerify, SignJWT } from "jose";
import { supabase } from "./supabase";

const ACCESS_TOKEN_EXPIRY = "7d";
const LOCK_DURATION_MS = 15 * 60 * 1000;
const MAX_LOGIN_ATTEMPTS = 10;
const JWT_ISSUER = "popcorn-film-log";
const JWT_AUDIENCE = "popcorn-film-log-app";

function getJwtSecret(): Uint8Array {
  const jwtSecret = process.env.JWT_SECRET;
  if (!jwtSecret) {
    throw new Error("JWT_SECRET is required");
  }
  return new TextEncoder().encode(jwtSecret);
}

const JWT_SECRET = getJwtSecret();

export type UserRow = {
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

export async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"]
  );
  const bits = await crypto.subtle.deriveBits(
    { name: "PBKDF2", salt, iterations: 100000, hash: "SHA-256" },
    keyMaterial,
    256
  );
  const hashArray = Array.from(new Uint8Array(bits));
  const saltArray = Array.from(salt);
  return btoa(JSON.stringify({ salt: saltArray, hash: hashArray }));
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  try {
    const { salt, hash } = JSON.parse(atob(stored));
    const encoder = new TextEncoder();
    const keyMaterial = await crypto.subtle.importKey(
      "raw",
      encoder.encode(password),
      "PBKDF2",
      false,
      ["deriveBits"]
    );
    const bits = await crypto.subtle.deriveBits(
      { name: "PBKDF2", salt: new Uint8Array(salt), iterations: 100000, hash: "SHA-256" },
      keyMaterial,
      256
    );
    const newHash = Array.from(new Uint8Array(bits));
    return JSON.stringify(newHash) === JSON.stringify(hash);
  } catch {
    return false;
  }
}

export async function generateToken(userId: string): Promise<string> {
  return new SignJWT({ userId })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuer(JWT_ISSUER)
    .setAudience(JWT_AUDIENCE)
    .setIssuedAt()
    .setExpirationTime(ACCESS_TOKEN_EXPIRY)
    .sign(JWT_SECRET);
}

export function sanitizeUser(user: UserRow) {
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

export async function authenticateRequest(req: VercelRequest): Promise<string | null> {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith("Bearer ")) return null;

  try {
    const token = authHeader.slice(7);
    const { payload } = await jwtVerify(token, JWT_SECRET, {
      issuer: JWT_ISSUER,
      audience: JWT_AUDIENCE,
    });
    if (typeof payload.userId === "string") return payload.userId;
    if (typeof payload.sub === "string") return payload.sub;
    return null;
  } catch {
    return null;
  }
}

export async function requireAuth(req: VercelRequest, res: VercelResponse): Promise<string | null> {
  const userId = await authenticateRequest(req);
  if (!userId) {
    res.status(401).json({ error: "UNAUTHORIZED" });
    return null;
  }

  const { data: user, error } = await supabase
    .from("users")
    .select("id, status, last_failed_login, login_attempts")
    .eq("id", userId)
    .maybeSingle();

  if (error || !user) {
    res.status(401).json({ error: "UNAUTHORIZED" });
    return null;
  }

  if (user.status === "locked") {
    const lastFailed = user.last_failed_login ? new Date(user.last_failed_login).getTime() : null;
    const lockExpired = lastFailed !== null && Date.now() - lastFailed > LOCK_DURATION_MS;

    if (lockExpired) {
      await supabase.from("users").update({
        status: "active",
        login_attempts: 0,
        last_failed_login: null,
        updated_at: new Date().toISOString(),
      }).eq("id", userId);
    } else {
      res.status(403).json({ error: "ACCOUNT_LOCKED" });
      return null;
    }
  } else if (user.status === "suspended") {
    res.status(403).json({ error: "ACCOUNT_SUSPENDED" });
    return null;
  } else if (user.status !== "active") {
    res.status(403).json({ error: "ACCOUNT_DISABLED" });
    return null;
  }

  return userId;
}

export function corsHeaders(res: VercelResponse) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

export function handleCors(req: VercelRequest, res: VercelResponse): boolean {
  corsHeaders(res);
  if (req.method === "OPTIONS") {
    res.status(204).end();
    return true;
  }
  return false;
}

export { MAX_LOGIN_ATTEMPTS, LOCK_DURATION_MS };
