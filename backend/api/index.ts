import { handle } from "hono/vercel";
import app from "../hono";

export const runtime = "edge";
export default handle(app);
