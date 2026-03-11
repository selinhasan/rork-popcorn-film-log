import { supabase } from "./supabase"; // adjust path to your supabase client
import { TRPCError } from "@trpc/server";
import { initTRPC } from "@trpc/server";

export const createContext = async ({ req }: { req: Request }) => {
  const authHeader = req.headers.get("authorization");
  let userId: string | null = null;

  if (authHeader?.startsWith("Bearer ")) {
    const token = authHeader.slice(7);
    // Verify JWT or decode token
    userId = "user123"; // placeholder for demo
  }

  return {
    userId,
    db: supabase,
    req,
  };
};

export type Context = Awaited<ReturnType<typeof createContext>>;

const t = initTRPC.context<Context>().create();

export const createTRPCRouter = t.router;
export const publicProcedure = t.procedure;
export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.userId) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx });
});
