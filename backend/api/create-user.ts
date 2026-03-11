// backend/api/create-user.ts

import { createClient } from "@supabase/supabase-js";
import { VercelRequest, VercelResponse } from "@vercel/node";

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  const { email } = req.body;

  const { data, error } = await supabase
    .from("users")
    .insert([{ email }]);

  if (error) return res.status(500).json(error);

  res.status(200).json(data);
}
