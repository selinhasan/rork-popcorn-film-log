import { z } from "zod";
import bcrypt from "bcryptjs";
import { SignJWT } from "jose";
import { v4 as uuidv4 } from "uuid";
import { TRPCError } from "@trpc/server";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "../create-context";
import { supabase } from "../../lib/supabase";

const JWT_SECRET = process.env.JWT_SECRET || "popcorn-film-log-jwt-secret-2026";
const ACCESS_TOKEN_EXPIRY = "7d";
const BCRYPT_ROUNDS = 12;
const JWT_SECRET = new TextEncoder().encode(
  process.env.JWT_SECRET || "popcorn-film-log-jwt-secret-2026"
);

async function generateToken(userId: string): Promise<string> {
  return new SignJWT({ userId })
    .setProtectedHeader({ alg: "HS256" })
    .setExpirationTime("7d")
    .sign(JWT_SECRET);
}

function sanitizeUser(user: any) {
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

function isAccountLocked(user: any): boolean {
  if (user.status === "locked" && user.last_failed_login) {
    const lockDuration = 15 * 60 * 1000;
    const elapsed = Date.now() - new Date(user.last_failed_login).getTime();
    if (elapsed > lockDuration) {
      return false;
    }
    return true;
  }
  return user.status === "suspended";
}

export const authRouter = createTRPCRouter({
  register: publicProcedure
    .input(
      z.object({
        username: z.string().min(3).max(20).regex(/^[a-zA-Z0-9._]+$/),
        email: z.string().email(),
        password: z.string().min(6).max(128),
      })
    )
    .mutation(async ({ input }) => {
      const emailLower = input.email.toLowerCase().trim();
      const usernameLower = input.username.toLowerCase().trim();

      const { data: existingEmail } = await supabase
        .from("users")
        .select("id")
        .eq("email", emailLower)
        .maybeSingle();

      if (existingEmail) {
        throw new TRPCError({ code: "CONFLICT", message: "EMAIL_EXISTS" });
      }

      const { data: existingUsername } = await supabase
        .from("users")
        .select("id")
        .eq("username_lower", usernameLower)
        .maybeSingle();

      if (existingUsername) {
        throw new TRPCError({ code: "CONFLICT", message: "USERNAME_EXISTS" });
      }

      const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);
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
        .select()
        .single();

      if (error || !newUser) {
        throw new TRPCError({ code: "INTERNAL_SERVER_ERROR", message: "Failed to create account" });
      }

      const token = await generateToken(userId);
      return { token, user: sanitizeUser(newUser) };
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

      let { data: user } = await supabase
        .from("users")
        .select("*")
        .eq("email", identifier)
        .maybeSingle();

      if (!user) {
        const { data: byUsername } = await supabase
          .from("users")
          .select("*")
          .eq("username_lower", identifier)
          .maybeSingle();
        user = byUsername;
      }

      if (!user) {
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      if (isAccountLocked(user)) {
        if (user.status === "locked") {
          const lockDuration = 15 * 60 * 1000;
          const elapsed = Date.now() - new Date(user.last_failed_login).getTime();
          if (elapsed > lockDuration) {
            await supabase
              .from("users")
              .update({ status: "active", login_attempts: 0, updated_at: new Date().toISOString() })
              .eq("id", user.id);
            user.status = "active";
            user.login_attempts = 0;
          } else {
            throw new TRPCError({ code: "FORBIDDEN", message: "ACCOUNT_LOCKED" });
          }
        } else {
          throw new TRPCError({ code: "FORBIDDEN", message: "ACCOUNT_LOCKED" });
        }
      }

      const valid = await bcrypt.compare(input.password, user.password_hash);
      if (!valid) {
        const newAttempts = (user.login_attempts || 0) + 1;
        const updates: any = {
          login_attempts: newAttempts,
          last_failed_login: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };
        if (newAttempts >= 10) {
          updates.status = "locked";
        }
        await supabase.from("users").update(updates).eq("id", user.id);
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      const now = new Date().toISOString();
      await supabase
        .from("users")
        .update({ login_attempts: 0, last_failed_login: null, last_login_at: now, updated_at: now })
        .eq("id", user.id);

      const token = await generateToken(user.id);
      return { token, user: sanitizeUser(user) };
    }),

  getProfile: protectedProcedure.query(async ({ ctx }) => {
    const { data: user, error } = await supabase
      .from("users")
      .select("*")
      .eq("id", ctx.userId)
      .single();

    if (error || !user) {
      throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
    }
    return { user: sanitizeUser(user) };
  }),

  updateProfile: protectedProcedure
    .input(
      z.object({
        username: z.string().min(3).max(20).regex(/^[a-zA-Z0-9._]+$/).optional(),
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
      const updates: any = { updated_at: new Date().toISOString() };

      if (input.username !== undefined) {
        const newLower = input.username.toLowerCase().trim();

        const { data: current } = await supabase
          .from("users")
          .select("username")
          .eq("id", ctx.userId)
          .single();

        if (current && current.username.toLowerCase() !== newLower) {
          const { data: existing } = await supabase
            .from("users")
            .select("id")
            .eq("username_lower", newLower)
            .neq("id", ctx.userId)
            .maybeSingle();

          if (existing) {
            throw new TRPCError({ code: "CONFLICT", message: "USERNAME_EXISTS" });
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
        .eq("id", ctx.userId)
        .select()
        .single();

      if (error || !user) {
        throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
      }

      return { user: sanitizeUser(user) };
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
      const updates: any = { updated_at: new Date().toISOString() };

      if (input.diaryEntries !== undefined) updates.diary_entries = input.diaryEntries;
      if (input.filmLists !== undefined) updates.film_lists = input.filmLists;
      if (input.watchlist !== undefined) updates.watchlist = input.watchlist;

      const { error } = await supabase
        .from("users")
        .update(updates)
        .eq("id", ctx.userId);

      if (error) {
        throw new TRPCError({ code: "INTERNAL_SERVER_ERROR", message: "Failed to sync data" });
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
      throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
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
        throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
      }

      const valid = await bcrypt.compare(input.currentPassword, user.password_hash);
      if (!valid) {
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      const newHash = await bcrypt.hash(input.newPassword, BCRYPT_ROUNDS);
      await supabase
        .from("users")
        .update({ password_hash: newHash, updated_at: new Date().toISOString() })
        .eq("id", ctx.userId);

      return { success: true };
    }),

  requestPasswordReset: publicProcedure
    .input(z.object({ email: z.string().email() }))
    .mutation(async () => {
      return {
        success: true,
        message: "If an account exists for that email, reset instructions have been sent.",
      };
    }),

  deleteAccount: protectedProcedure.mutation(async ({ ctx }) => {
    await supabase.from("users").delete().eq("id", ctx.userId);
    return { success: true };
  }),
});
