import { handle } from "hono/vercel";
import app from "../hono";

export const runtime = "nodejs";

export default handle(app);
