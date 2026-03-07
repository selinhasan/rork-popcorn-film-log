import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import { TRPCError } from "@trpc/server";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "../create-context";

const JWT_SECRET = process.env.JWT_SECRET || "popcorn-film-log-jwt-secret-2026";
const ACCESS_TOKEN_EXPIRY = "7d";
const BCRYPT_ROUNDS = 12;

interface UserRecord {
  id: string;
  username: string;
  email: string;
  passwordHash: string;
  profileImageName: string;
  customProfileImageURL: string | null;
  bio: string;
  topFiveFilms: any[];
  goldenPopcornFilmId: string | null;
  buddyIds: string[];
  watchlist: any[];
  diaryEntries: any[];
  filmLists: any[];
  joinDate: string;
  lastLoginAt: string;
  status: "active" | "locked" | "suspended";
  loginAttempts: number;
  lastFailedLogin: string | null;
  createdAt: string;
  updatedAt: string;
}

const users = new Map<string, UserRecord>();
const emailIndex = new Map<string, string>();
const usernameIndex = new Map<string, string>();

function generateToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: ACCESS_TOKEN_EXPIRY });
}

function sanitizeUser(user: UserRecord) {
  return {
    id: user.id,
    username: user.username,
    email: user.email,
    profileImageName: user.profileImageName,
    customProfileImageURL: user.customProfileImageURL,
    bio: user.bio,
    topFiveFilms: user.topFiveFilms,
    goldenPopcornFilmId: user.goldenPopcornFilmId,
    buddyIds: user.buddyIds,
    watchlist: user.watchlist,
    diaryEntries: user.diaryEntries,
    filmLists: user.filmLists,
    joinDate: user.joinDate,
  };
}

function isAccountLocked(user: UserRecord): boolean {
  if (user.status === "locked" && user.lastFailedLogin) {
    const lockDuration = 15 * 60 * 1000;
    const elapsed = Date.now() - new Date(user.lastFailedLogin).getTime();
    if (elapsed > lockDuration) {
      user.status = "active";
      user.loginAttempts = 0;
      return false;
    }
    return true;
  }
  return user.status === "suspended";
}

function validatePasswordStrength(password: string): string | null {
  if (password.length < 6) return "Password must be at least 6 characters";
  return null;
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

      if (emailIndex.has(emailLower)) {
        throw new TRPCError({ code: "CONFLICT", message: "EMAIL_EXISTS" });
      }

      if (usernameIndex.has(usernameLower)) {
        throw new TRPCError({ code: "CONFLICT", message: "USERNAME_EXISTS" });
      }

      const strengthError = validatePasswordStrength(input.password);
      if (strengthError) {
        throw new TRPCError({ code: "BAD_REQUEST", message: strengthError });
      }

      const passwordHash = await bcrypt.hash(input.password, BCRYPT_ROUNDS);
      const userId = uuidv4();
      const now = new Date().toISOString();

      const user: UserRecord = {
        id: userId,
        username: input.username.trim(),
        email: emailLower,
        passwordHash,
        profileImageName: "avatar_1",
        customProfileImageURL: null,
        bio: "",
        topFiveFilms: [],
        goldenPopcornFilmId: null,
        buddyIds: [],
        watchlist: [],
        diaryEntries: [],
        filmLists: [],
        joinDate: now,
        lastLoginAt: now,
        status: "active",
        loginAttempts: 0,
        lastFailedLogin: null,
        createdAt: now,
        updatedAt: now,
      };

      users.set(userId, user);
      emailIndex.set(emailLower, userId);
      usernameIndex.set(usernameLower, userId);

      const token = generateToken(userId);

      return { token, user: sanitizeUser(user) };
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

      let userId = emailIndex.get(identifier);
      if (!userId) {
        userId = usernameIndex.get(identifier);
      }

      if (!userId) {
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      const user = users.get(userId);
      if (!user) {
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      if (isAccountLocked(user)) {
        throw new TRPCError({
          code: "FORBIDDEN",
          message: "ACCOUNT_LOCKED",
        });
      }

      const valid = await bcrypt.compare(input.password, user.passwordHash);
      if (!valid) {
        user.loginAttempts += 1;
        user.lastFailedLogin = new Date().toISOString();

        if (user.loginAttempts >= 10) {
          user.status = "locked";
        }

        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      user.loginAttempts = 0;
      user.lastFailedLogin = null;
      user.lastLoginAt = new Date().toISOString();
      user.updatedAt = new Date().toISOString();

      const token = generateToken(userId);
      return { token, user: sanitizeUser(user) };
    }),

  getProfile: protectedProcedure.query(({ ctx }) => {
    const user = users.get(ctx.userId);
    if (!user) {
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
    .mutation(({ ctx, input }) => {
      const user = users.get(ctx.userId);
      if (!user) {
        throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
      }

      if (input.username !== undefined) {
        const newLower = input.username.toLowerCase().trim();
        const currentLower = user.username.toLowerCase();
        if (newLower !== currentLower) {
          if (usernameIndex.has(newLower)) {
            throw new TRPCError({ code: "CONFLICT", message: "USERNAME_EXISTS" });
          }
          usernameIndex.delete(currentLower);
          usernameIndex.set(newLower, user.id);
          user.username = input.username.trim();
        }
      }

      if (input.profileImageName !== undefined) user.profileImageName = input.profileImageName;
      if (input.customProfileImageURL !== undefined) user.customProfileImageURL = input.customProfileImageURL;
      if (input.bio !== undefined) user.bio = input.bio;
      if (input.topFiveFilms !== undefined) user.topFiveFilms = input.topFiveFilms;
      if (input.goldenPopcornFilmId !== undefined) user.goldenPopcornFilmId = input.goldenPopcornFilmId;
      if (input.watchlist !== undefined) user.watchlist = input.watchlist;
      if (input.buddyIds !== undefined) user.buddyIds = input.buddyIds;
      user.updatedAt = new Date().toISOString();

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
    .mutation(({ ctx, input }) => {
      const user = users.get(ctx.userId);
      if (!user) {
        throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
      }

      if (input.diaryEntries !== undefined) user.diaryEntries = input.diaryEntries;
      if (input.filmLists !== undefined) user.filmLists = input.filmLists;
      if (input.watchlist !== undefined) user.watchlist = input.watchlist;
      user.updatedAt = new Date().toISOString();

      return { success: true };
    }),

  getData: protectedProcedure.query(({ ctx }) => {
    const user = users.get(ctx.userId);
    if (!user) {
      throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
    }
    return {
      diaryEntries: user.diaryEntries,
      filmLists: user.filmLists,
      watchlist: user.watchlist,
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
      const user = users.get(ctx.userId);
      if (!user) {
        throw new TRPCError({ code: "NOT_FOUND", message: "USER_NOT_FOUND" });
      }

      const valid = await bcrypt.compare(input.currentPassword, user.passwordHash);
      if (!valid) {
        throw new TRPCError({ code: "UNAUTHORIZED", message: "INVALID_CREDENTIALS" });
      }

      const strengthError = validatePasswordStrength(input.newPassword);
      if (strengthError) {
        throw new TRPCError({ code: "BAD_REQUEST", message: strengthError });
      }

      user.passwordHash = await bcrypt.hash(input.newPassword, BCRYPT_ROUNDS);
      user.updatedAt = new Date().toISOString();

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

  deleteAccount: protectedProcedure.mutation(({ ctx }) => {
    const user = users.get(ctx.userId);
    if (user) {
      emailIndex.delete(user.email);
      usernameIndex.delete(user.username.toLowerCase());
      users.delete(ctx.userId);
    }
    return { success: true };
  }),
});
