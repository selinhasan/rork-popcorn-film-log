// backend/api/trpc.ts
import { appRouter } from "../lib/app-router";
import { createContext } from "../lib/create-context";
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";

export default async function handler(req: Request) {
  return fetchRequestHandler({
    router: appRouter,
    createContext,
    req,
    endpoint: "/api/trpc",
  });
}
