import { z } from "zod";
import { SignJWT } from "jose";
import { v4 as uuidv4 } from "uuid";
import { TRPCError } from "@trpc/server";
import {
  createTRPCRouter,
  publicProcedure,
  protectedProcedure,
} from "../create-context";
import { supabase } from "../../lib/supabase";

const ACCESS_TOKEN_EXPIRY = "7d";
const LOCK_DURATION_MS = 15 * 60 * 1000;
const MAX_LOGIN_ATTEMPTS = 10;
const JWT_ISSUER = "popcorn-film-log";
const JWT_AUDIENCE = "popcorn-film-log-app";

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

function getJwtSecret(): Uint8Array {
  const jwtSecret = process.env.JWT_SECRET;

  if (!jwtSecret) {
    throw new Error("JWT_SECRET is required");
  }

  return new TextEncoder().encode(jwtSecret);
}

const JWT_SECRET = getJwtSecret();

async function hashPassword(password: string): Promise<string> {
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
    {
      name: "PBKDF2",
      salt,
      iterations: 100000,
      hash: "SHA-256",
    },
    keyMaterial,
    256
  );

  const hashArray = Array.from(new Uint8Array(bits));
  const saltArray = Array.from(salt);

  return btoa(JSON.stringify({ salt: saltArray, hash: hashArray }));
}

async function verifyPassword(
  password: string,
  stored: string
): Promise<boolean> {
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
      {
        name: "PBKDF2",
        salt: new Uint8Array(salt),
        iterations: 100000,
        hash: "SHA-256",
      },
      keyMaterial,
      256
    );

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
    .sign(JWT_SECRET);
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

function isLockExpired(lastFailedLogin: string | null): boolean {
  if (!lastFailedLogin) {
    return false;
  }

  const elapsed = Date.now() - new Date(lastFailedLogin).getTime();
  return elapsed > LOCK_DURATION_MS;
}

async function clearExpiredLock(user: UserRow): Promise<UserRow> {
  if (user.status !== "locked") {
    return user;
  }

  if (!isLockExpired(user.last_failed_login)) {
    return user;
  }

  const now = new Date().toISOString();

  const { data, error } = await supabase
    .from("users")
    .update({
      status: "active",
      login_attempts: 0,
      last_failed_login: null,
      updated_at: now,
    })
    .eq("id", user.id)
    .select("*")
    .single();

  if (error || !data) {
    throw new TRPCError({
      code: "INTERNAL_SERVER_ERROR",
      message: "FAILED_TO_RESET_LOCK",
    });
  }

  return data as UserRow;
}

function assertLoginAllowed(user: UserRow): void {
  if (user.status === "suspended") {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_SUSPENDED",
    });
  }

  if (user.status === "locked") {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_LOCKED",
    });
  }

  if (user.status !== "active") {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_DISABLED",
    });
  }
}

export const authRouter = createTRPCRouter({
  register: publicProcedure
    .input(
      z.object({
        username: z
          .string()
          .min(3)
          .max(20)
          .regex(/^[a-zA-Z0-9._]+$/),
        email: z.string().email(),
        password: z.string().min(6).max(128),
      })
    )
    .mutation(async ({ input }) => {
      const emailLower = input.email.toLowerCase().trim();
      const usernameLower = input.username.toLowerCase().trim();

      const { data: existingEmail, error: existingEmailError } = await supabase
        .from("users")
        .select("id")
        .eq("email", emailLower)
        .maybeSingle();

      if (existingEmailError) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_CHECK_EMAIL",
        });
      }

      if (existingEmail) {
        throw new TRPCError({
          code: "CONFLICT",
          message: "EMAIL_EXISTS",
        });
      }

      const { data: existingUsername, error: existingUsernameError } =
        await supabase
          .from("users")
          .select("id")
          .eq("username_lower", usernameLower)
          .maybeSingle();

      if (existingUsernameError) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_CHECK_USERNAME",
        });
      }

      if (existingUsername) {
        throw new TRPCError({
          code: "CONFLICT",
          message: "USERNAME_EXISTS",
        });
      }

      const passwordHash = await hashPassword(input.password);
      const userId = uuidv4();
      const now = new Date().toISOString();

      const { data: newUser, error } = await supabase
        .from("users")
        .insert({
          id: userId,
          username: input.username.trim(),
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
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_CREATE_ACCOUNT",
        });
      }

      const token = await generateToken(userId);

      return {
        token,
        user: sanitizeUser(newUser as UserRow),
      };
    }),

  login: publicProcedure
    .input(
      z.object({
        email: z.string().min(1),
        password: z.string().min(1),
      })
    )
    .mutation(async ({ input }) => {
      const identifier = input.email.toLowerCase().trim();

      let { data: user, error: userError } = await supabase
        .from("users")
        .select("*")
        .eq("email", identifier)
        .maybeSingle();

      if (userError) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_LOAD_USER",
        });
      }

      if (!user) {
        const { data: byUsername, error: usernameLookupError } = await supabase
          .from("users")
          .select("*")
          .eq("username_lower", identifier)
          .maybeSingle();

        if (usernameLookupError) {
          throw new TRPCError({
            code: "INTERNAL_SERVER_ERROR",
            message: "FAILED_TO_LOAD_USER",
          });
        }

        user = byUsername;
      }

      if (!user) {
        throw new TRPCError({
          code: "UNAUTHORIZED",
          message: "INVALID_CREDENTIALS",
        });
      }

      let userRow = (await clearExpiredLock(user as UserRow)) as UserRow;
      assertLoginAllowed(userRow);

      const valid = await verifyPassword(input.password, userRow.password_hash);

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

        const { error: failedLoginError } = await supabase
          .from("users")
          .update(updates)
          .eq("id", userRow.id);

        if (failedLoginError) {
          throw new TRPCError({
            code: "INTERNAL_SERVER_ERROR",
            message: "FAILED_TO_RECORD_LOGIN_ATTEMPT",
          });
        }

        throw new TRPCError({
          code: "UNAUTHORIZED",
          message: "INVALID_CREDENTIALS",
        });
      }

      const now = new Date().toISOString();

      const { data: updatedUser, error: loginUpdateError } = await supabase
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

      if (loginUpdateError || !updatedUser) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_UPDATE_LOGIN_STATE",
        });
      }

      const token = await generateToken(userRow.id);

      return {
        token,
        user: sanitizeUser(updatedUser as UserRow),
      };
    }),

  getProfile: protectedProcedure.query(async ({ ctx }) => {
    const { data: user, error } = await supabase
      .from("users")
      .select("*")
      .eq("id", ctx.userId)
      .single();

    if (error || !user) {
      throw new TRPCError({
        code: "NOT_FOUND",
        message: "USER_NOT_FOUND",
      });
    }

    return { user: sanitizeUser(user as UserRow) };
  }),

  updateProfile: protectedProcedure
    .input(
      z.object({
        username: z
          .string()
          .min(3)
          .max(20)
          .regex(/^[a-zA-Z0-9._]+$/)
          .optional(),
        profileImageName: z.string().optional(),
        customProfileImageURL: z.string().nullable().optional(),
        bio: z.string().max(500).optional(),
        topFiveFilms: z.array(z.any()).optional(),
        goldenPopcornFilmId: z.string().nullable().optional(),
        watchlist: z.array(z.any()).optional(),
        buddyIds: z.array(z.string()).optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const updates: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
      };

      if (input.username !== undefined) {
        const newLower = input.username.toLowerCase().trim();

        const { data: current, error: currentError } = await supabase
          .from("users")
          .select("username")
          .eq("id", ctx.userId)
          .single();

        if (currentError) {
          throw new TRPCError({
            code: "NOT_FOUND",
            message: "USER_NOT_FOUND",
          });
        }

        if (
          current &&
          typeof current.username === "string" &&
          current.username.toLowerCase() !== newLower
        ) {
          const { data: existing, error: existingError } = await supabase
            .from("users")
            .select("id")
            .eq("username_lower", newLower)
            .neq("id", ctx.userId)
            .maybeSingle();

          if (existingError) {
            throw new TRPCError({
              code: "INTERNAL_SERVER_ERROR",
              message: "FAILED_TO_CHECK_USERNAME",
            });
          }

          if (existing) {
            throw new TRPCError({
              code: "CONFLICT",
              message: "USERNAME_EXISTS",
            });
          }

          updates.username = input.username.trim();
          updates.username_lower = newLower;
        }
      }

      if (input.profileImageName !== undefined) {
        updates.profile_image_name = input.profileImageName;
      }

      if (input.customProfileImageURL !== undefined) {
        updates.custom_profile_image_url = input.customProfileImageURL;
      }

      if (input.bio !== undefined) {
        updates.bio = input.bio;
      }

      if (input.topFiveFilms !== undefined) {
        updates.top_five_films = input.topFiveFilms;
      }

      if (input.goldenPopcornFilmId !== undefined) {
        updates.golden_popcorn_film_id = input.goldenPopcornFilmId;
      }

      if (input.watchlist !== undefined) {
        updates.watchlist = input.watchlist;
      }

      if (input.buddyIds !== undefined) {
        updates.buddy_ids = input.buddyIds;
      }

      const { data: user, error } = await supabase
        .from("users")
        .update(updates)
        .eq("id", ctx.userId)
        .select("*")
        .single();

      if (error || !user) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "USER_NOT_FOUND",
        });
      }

      return { user: sanitizeUser(user as UserRow) };
    }),

  syncData: protectedProcedure
    .input(
      z.object({
        diaryEntries: z.array(z.any()).optional(),
        filmLists: z.array(z.any()).optional(),
        watchlist: z.array(z.any()).optional(),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const updates: Record<string, unknown> = {
        updated_at: new Date().toISOString(),
      };

      if (input.diaryEntries !== undefined) {
        updates.diary_entries = input.diaryEntries;
      }

      if (input.filmLists !== undefined) {
        updates.film_lists = input.filmLists;
      }

      if (input.watchlist !== undefined) {
        updates.watchlist = input.watchlist;
      }

      const { error } = await supabase
        .from("users")
        .update(updates)
        .eq("id", ctx.userId);

      if (error) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_SYNC_DATA",
        });
      }

      return { success: true };
    }),

  getData: protectedProcedure.query(async ({ ctx }) => {
    const { data: user, error } = await supabase
      .from("users")
      .select("diary_entries, film_lists, watchlist")
      .eq("id", ctx.userId)
      .single();

    if (error || !user) {
      throw new TRPCError({
        code: "NOT_FOUND",
        message: "USER_NOT_FOUND",
      });
    }

    return {
      diaryEntries: user.diary_entries || [],
      filmLists: user.film_lists || [],
      watchlist: user.watchlist || [],
    };
  }),

  changePassword: protectedProcedure
    .input(
      z.object({
        currentPassword: z.string().min(1),
        newPassword: z.string().min(6).max(128),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const { data: user, error } = await supabase
        .from("users")
        .select("password_hash")
        .eq("id", ctx.userId)
        .single();

      if (error || !user) {
        throw new TRPCError({
          code: "NOT_FOUND",
          message: "USER_NOT_FOUND",
        });
      }

      const valid = await verifyPassword(
        input.currentPassword,
        user.password_hash
      );

      if (!valid) {
        throw new TRPCError({
          code: "UNAUTHORIZED",
          message: "INVALID_CREDENTIALS",
        });
      }

      const newHash = await hashPassword(input.newPassword);

      const { error: updateError } = await supabase
        .from("users")
        .update({
          password_hash: newHash,
          updated_at: new Date().toISOString(),
        })
        .eq("id", ctx.userId);

      if (updateError) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_CHANGE_PASSWORD",
        });
      }

      return { success: true };
    }),

  requestPasswordReset: publicProcedure
    .input(z.object({ email: z.string().email() }))
    .mutation(async () => {
      return {
        success: false,
        message: "Password reset is not configured on this server.",
      };
    }),

  deleteAccount: protectedProcedure.mutation(async ({ ctx }) => {
    const { error } = await supabase
      .from("users")
      .delete()
      .eq("id", ctx.userId);

    if (error) {
      throw new TRPCError({
        code: "INTERNAL_SERVER_ERROR",
        message: "FAILED_TO_DELETE_ACCOUNT",
      });
    }

    return { success: true };
  }),
});
