import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { v4 as uuidv4 } from "uuid";
import { createTRPCRouter, publicProcedure, protectedProcedure } from "../create-context";

const JWT_SECRET = process.env.JWT_SECRET || "popcorn-film-log-secret-key-change-in-production";
const TOKEN_EXPIRY = "30d";

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
  createdAt: string;
  updatedAt: string;
}

const users = new Map<string, UserRecord>();
const emailIndex = new Map<string, string>();

function generateToken(userId: string): string {
  return jwt.sign({ userId }, JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
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

export const authRouter = createTRPCRouter({
  register: publicProcedure
    .input(
      z.object({
        username: z.string().min(3).max(20),
        email: z.string().email(),
        password: z.string().min(6),
      })
    )
    .mutation(async ({ input }) => {
      const emailLower = input.email.toLowerCase();

      if (emailIndex.has(emailLower)) {
        throw new Error("EMAIL_EXISTS");
      }

      for (const user of users.values()) {
        if (user.username.toLowerCase() === input.username.toLowerCase()) {
          throw new Error("USERNAME_EXISTS");
        }
      }

      const passwordHash = await bcrypt.hash(input.password, 12);
      const userId = uuidv4();
      const now = new Date().toISOString();

      const user: UserRecord = {
        id: userId,
        username: input.username,
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
        createdAt: now,
        updatedAt: now,
      };

      users.set(userId, user);
      emailIndex.set(emailLower, userId);

      const token = generateToken(userId);

      return {
        token,
        user: sanitizeUser(user),
      };
    }),

  login: publicProcedure
    .input(
      z.object({
        email: z.string(),
        password: z.string(),
      })
    )
    .mutation(async ({ input }) => {
      const emailLower = input.email.toLowerCase();
      const userId = emailIndex.get(emailLower);

      if (!userId) {
        let foundUser: UserRecord | null = null;
        for (const user of users.values()) {
          if (user.username.toLowerCase() === emailLower) {
            foundUser = user;
            break;
          }
        }
        if (!foundUser) {
          throw new Error("INVALID_CREDENTIALS");
        }
        const valid = await bcrypt.compare(input.password, foundUser.passwordHash);
        if (!valid) {
          throw new Error("INVALID_CREDENTIALS");
        }
        const token = generateToken(foundUser.id);
        return { token, user: sanitizeUser(foundUser) };
      }

      const user = users.get(userId);
      if (!user) {
        throw new Error("INVALID_CREDENTIALS");
      }

      const valid = await bcrypt.compare(input.password, user.passwordHash);
      if (!valid) {
        throw new Error("INVALID_CREDENTIALS");
      }

      const token = generateToken(userId);
      return { token, user: sanitizeUser(user) };
    }),

  getProfile: protectedProcedure.query(({ ctx }) => {
    const user = users.get(ctx.userId);
    if (!user) {
      throw new Error("USER_NOT_FOUND");
    }
    return { user: sanitizeUser(user) };
  }),

  updateProfile: protectedProcedure
    .input(
      z.object({
        username: z.string().min(3).max(20).optional(),
        profileImageName: z.string().optional(),
        customProfileImageURL: z.string().nullable().optional(),
        bio: z.string().optional(),
        topFiveFilms: z.array(z.any()).optional(),
        goldenPopcornFilmId: z.string().nullable().optional(),
        watchlist: z.array(z.any()).optional(),
        buddyIds: z.array(z.string()).optional(),
      })
    )
    .mutation(({ ctx, input }) => {
      const user = users.get(ctx.userId);
      if (!user) {
        throw new Error("USER_NOT_FOUND");
      }

      if (input.username !== undefined) user.username = input.username;
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
        throw new Error("USER_NOT_FOUND");
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
      throw new Error("USER_NOT_FOUND");
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
        currentPassword: z.string(),
        newPassword: z.string().min(6),
      })
    )
    .mutation(async ({ ctx, input }) => {
      const user = users.get(ctx.userId);
      if (!user) {
        throw new Error("USER_NOT_FOUND");
      }

      const valid = await bcrypt.compare(input.currentPassword, user.passwordHash);
      if (!valid) {
        throw new Error("INVALID_CREDENTIALS");
      }

      user.passwordHash = await bcrypt.hash(input.newPassword, 12);
      user.updatedAt = new Date().toISOString();

      return { success: true };
    }),

  requestPasswordReset: publicProcedure
    .input(z.object({ email: z.string().email() }))
    .mutation(async ({ input }) => {
      return { success: true, message: "If an account exists for that email, reset instructions have been sent." };
    }),

  deleteAccount: protectedProcedure.mutation(({ ctx }) => {
    const user = users.get(ctx.userId);
    if (user) {
      emailIndex.delete(user.email);
      users.delete(ctx.userId);
    }
    return { success: true };
  }),
});
