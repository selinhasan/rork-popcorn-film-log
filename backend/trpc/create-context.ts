import { initTRPC, TRPCError } from "@trpc/server";
import type { FetchCreateContextFnOptions } from "@trpc/server/adapters/fetch";
import { jwtVerify } from "jose";
import { supabase } from "../lib/supabase";

const LOCK_DURATION_MS = 15 * 60 * 1000;
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

async function assertActiveAccount(userId: string): Promise<void> {
  const { data: user, error } = await supabase
    .from("users")
    .select("id, status, last_failed_login")
    .eq("id", userId)
    .maybeSingle();

  if (error || !user) {
    throw new TRPCError({
      code: "UNAUTHORIZED",
      message: "UNAUTHORIZED",
    });
  }

  if (user.status === "locked") {
    const lastFailedLogin = user.last_failed_login
      ? new Date(user.last_failed_login).getTime()
      : null;

    const lockExpired =
      lastFailedLogin !== null &&
      Date.now() - lastFailedLogin > LOCK_DURATION_MS;

    if (lockExpired) {
      const { error: resetError } = await supabase
        .from("users")
        .update({
          status: "active",
          login_attempts: 0,
          last_failed_login: null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);

      if (resetError) {
        throw new TRPCError({
          code: "INTERNAL_SERVER_ERROR",
          message: "FAILED_TO_RESET_LOCK",
        });
      }

      return;
    }

    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_LOCKED",
    });
  }

  if (user.status === "suspended") {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_SUSPENDED",
    });
  }

  if (user.status !== "active") {
    throw new TRPCError({
      code: "FORBIDDEN",
      message: "ACCOUNT_DISABLED",
    });
  }
}

export const createContext = async (opts: FetchCreateContextFnOptions) => {
  const authHeader = opts.req.headers.get("authorization");
  let userId: string | null = null;

  if (authHeader?.startsWith("Bearer ")) {
    try {
      const token = authHeader.slice(7);

      const { payload } = await jwtVerify(token, JWT_SECRET, {
        issuer: JWT_ISSUER,
        audience: JWT_AUDIENCE,
      });

      if (typeof payload.userId === "string") {
        userId = payload.userId;
      } else if (typeof payload.sub === "string") {
        userId = payload.sub;
      }
    } catch {
      userId = null;
    }
  }

  return {
    req: opts.req,
    userId,
  };
};

export type Context = Awaited<ReturnType<typeof createContext>>;

const t = initTRPC.context<Context>().create();

export const createTRPCRouter = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({
      code: "UNAUTHORIZED",
      message: "UNAUTHORIZED",
    });
  }

  await assertActiveAccount(ctx.userId);

  return next({
    ctx: {
      ...ctx,
      userId: ctx.userId,
    },
  });
});
