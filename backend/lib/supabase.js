import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseKey);


import { supabase } from "../lib/supabase";

export async function signUp(email, password) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password
  });

  return { data, error };
}

export async function login(email, password) {
    const { data, error } =
      await supabase.auth.signInWithPassword({
        email,
        password
      });
  
    return { data, error };
  }

;