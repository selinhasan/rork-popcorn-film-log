import type { VercelRequest, VercelResponse } from "@vercel/node";
import app from "../hono";

export default async function handler(req: VercelRequest, res: VercelResponse) {
  const host = req.headers.host || "localhost";
  const url = `https://${host}${req.url}`;

  const headers = new Headers();
  for (const [key, value] of Object.entries(req.headers)) {
    if (value) headers.set(key, Array.isArray(value) ? value.join(", ") : value);
  }

  let body: string | undefined;
  if (req.method !== "GET" && req.method !== "HEAD") {
    // req.body is already parsed by Vercel — re-stringify it
    body = req.body ? JSON.stringify(req.body) : undefined;
    // Ensure content-type is set correctly
    headers.set("content-type", "application/json");
  }

  const webRequest = new Request(url, { method: req.method, headers, body });
  const response = await app.fetch(webRequest);

  res.status(response.status);
  response.headers.forEach((value, key) => res.setHeader(key, value));
  res.send(await response.text());
}
