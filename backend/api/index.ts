import type { VercelRequest, VercelResponse } from "@vercel/node";
import app from "../hono";

function getHeaderValue(
  value: string | string[] | undefined
): string | undefined {
  if (Array.isArray(value)) {
    return value.join(", ");
  }

  return value;
}

function getProtocol(req: VercelRequest, host: string): string {
  const forwardedProto = getHeaderValue(req.headers["x-forwarded-proto"]);

  if (forwardedProto) {
    return forwardedProto;
  }

  return host.includes("localhost") ? "http" : "https";
}

function getBody(req: VercelRequest): BodyInit | undefined {
  if (req.method === "GET" || req.method === "HEAD") {
    return undefined;
  }

  if (req.body == null) {
    return undefined;
  }

  if (typeof req.body === "string" || Buffer.isBuffer(req.body)) {
    return req.body;
  }

  return JSON.stringify(req.body);
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  const host = req.headers.host || "localhost";
  const protocol = getProtocol(req, host);
  const url = `${protocol}://${host}${req.url}`;
  const headers = new Headers();

  for (const [key, rawValue] of Object.entries(req.headers)) {
    const value = getHeaderValue(rawValue);

    if (!value) {
      continue;
    }

    if (key.toLowerCase() === "content-length") {
      continue;
    }

    headers.set(key, value);
  }

  const body = getBody(req);

  const webRequest = new Request(url, {
    method: req.method,
    headers,
    body,
  });

  const response = await app.fetch(webRequest);

  res.status(response.status);

  response.headers.forEach((value, key) => {
    if (key.toLowerCase() === "content-length") {
      return;
    }

    res.setHeader(key, value);
  });

  res.send(await response.text());
}
