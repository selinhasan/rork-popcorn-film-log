import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "../lib/supabase";

const AuthContext = createContext(null);

// ---------------------------------------------------------
// Password validation
// ---------------------------------------------------------

function getPasswordError(password) {
  if (!password) {
    return "Please enter a password.";
  }

  if (password.length < 8) {
    return "Password must be at least 8 characters.";
  }

  if (!/[A-Z]/.test(password)) {
    return "Password needs at least one uppercase letter.";
  }

  if (!/[a-z]/.test(password)) {
    return "Password needs at least one lowercase letter.";
  }

  if (!/[0-9]/.test(password)) {
    return "Password needs at least one number.";
  }

  return null;
}

// ---------------------------------------------------------
// Auth provider
// ---------------------------------------------------------

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // True when the user has entered the app through
  // a Supabase password recovery link.
  const [isPasswordRecovery, setIsPasswordRecovery] = useState(false);

  // -------------------------------------------------------
  // Load existing session and listen for auth changes
  // -------------------------------------------------------

  useEffect(() => {
    let mounted = true;

    async function loadSession() {
      try {
        const {
          data: { session },
          error,
        } = await supabase.auth.getSession();

        if (error) {
          console.error("Supabase getSession error:", error);
        }

        if (mounted) {
          setUser(session?.user ?? null);
          setIsLoading(false);
        }
      } catch (error) {
        console.error("Error loading Supabase session:", error);

        if (mounted) {
          setUser(null);
          setIsLoading(false);
        }
      }
    }

    loadSession();

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((event, session) => {
      console.log("Supabase auth event:", event);

      setUser(session?.user ?? null);

      // Supabase fires this when the user follows
      // a valid password-reset link.
      if (event === "PASSWORD_RECOVERY") {
        setIsPasswordRecovery(true);
      }

      if (event === "SIGNED_OUT") {
        setIsPasswordRecovery(false);
      }
    });

    return () => {
      mounted = false;
      subscription.unsubscribe();
    };
  }, []);

  // -------------------------------------------------------
  // Register
  // -------------------------------------------------------

  async function register({ username, email, password }) {
    if (!username?.trim() || !email?.trim()) {
      return {
        ok: false,
        error: "Please fill in every field.",
      };
    }

    const passwordError = getPasswordError(password);

    if (passwordError) {
      return {
        ok: false,
        error: passwordError,
      };
    }

    try {
      const { data, error } = await supabase.auth.signUp({
        email: email.trim().toLowerCase(),
        password,
        options: {
          data: {
            username: username.trim().toLowerCase(),
          },
        },
      });

      if (error) {
        console.error("Supabase signup error:", error);

        return {
          ok: false,
          error: error.message,
        };
      }

      if (!data.user) {
        return {
          ok: false,
          error: "Account could not be created.",
        };
      }

      return {
        ok: true,
        user: data.user,
        session: data.session,
      };
    } catch (error) {
      console.error("Unexpected signup error:", error);

      return {
        ok: false,
        error: "Something went wrong. Please try again.",
      };
    }
  }

  // -------------------------------------------------------
  // Login
  // -------------------------------------------------------

  async function login({ identifier, password }) {
    if (!identifier?.trim() || !password) {
      return {
        ok: false,
        error: "Please enter your email and password.",
      };
    }

    try {
      const {
        data: { user: loggedInUser },
        error,
      } = await supabase.auth.signInWithPassword({
        email: identifier.trim().toLowerCase(),
        password,
      });

      if (error) {
        console.error("Supabase login error:", error);

        return {
          ok: false,
          error: error.message,
        };
      }

      setUser(loggedInUser);

      return {
        ok: true,
      };
    } catch (error) {
      console.error("Unexpected login error:", error);

      return {
        ok: false,
        error: "Something went wrong. Please try again.",
      };
    }
  }

  // -------------------------------------------------------
  // Forgot password
  // -------------------------------------------------------

  async function forgotPassword(email, redirectTo = null) {
    if (!email?.trim()) {
      return {
        ok: false,
        error: "Please enter your email address.",
      };
    }

    try {
      let result;

      // If we have configured an app deep-link URL,
      // tell Supabase where to send the user after
      // clicking the reset link.
      if (redirectTo) {
        result = await supabase.auth.resetPasswordForEmail(
          email.trim().toLowerCase(),
          {
            redirectTo,
          }
        );
      } else {
        result = await supabase.auth.resetPasswordForEmail(
          email.trim().toLowerCase()
        );
      }

      if (result.error) {
        console.error(
          "Supabase password reset error:",
          result.error
        );

        return {
          ok: false,
          error: result.error.message,
        };
      }

      return {
        ok: true,
      };
    } catch (error) {
      console.error("Unexpected password reset error:", error);

      return {
        ok: false,
        error: "Could not send password reset email. Please try again.",
      };
    }
  }

  // -------------------------------------------------------
  // Update password
  // Called after the user opens their recovery link.
  // -------------------------------------------------------

  async function updatePassword(password) {
    const passwordError = getPasswordError(password);

    if (passwordError) {
      return {
        ok: false,
        error: passwordError,
      };
    }

    try {
      const { data, error } = await supabase.auth.updateUser({
        password,
      });

      if (error) {
        console.error("Supabase update password error:", error);

        return {
          ok: false,
          error: error.message,
        };
      }

      // Password successfully changed, so recovery mode
      // is no longer required.
      setIsPasswordRecovery(false);

      return {
        ok: true,
        user: data.user,
      };
    } catch (error) {
      console.error("Unexpected update password error:", error);

      return {
        ok: false,
        error: "Could not update password. Please try again.",
      };
    }
  }

  // -------------------------------------------------------
  // Leave password recovery mode
  // -------------------------------------------------------

  function clearPasswordRecovery() {
    setIsPasswordRecovery(false);
  }

  // -------------------------------------------------------
  // Logout
  // -------------------------------------------------------

  async function logout() {
    try {
      const { error } = await supabase.auth.signOut();

      if (error) {
        console.error("Supabase logout error:", error);

        return {
          ok: false,
          error: error.message,
        };
      }

      setUser(null);
      setIsPasswordRecovery(false);

      return {
        ok: true,
      };
    } catch (error) {
      console.error("Unexpected logout error:", error);

      return {
        ok: false,
        error: "Could not log out. Please try again.",
      };
    }
  }

  // -------------------------------------------------------
  // Context
  // -------------------------------------------------------

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,

        register,
        login,
        logout,

        forgotPassword,
        updatePassword,

        isPasswordRecovery,
        clearPasswordRecovery,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// ---------------------------------------------------------
// Hook
// ---------------------------------------------------------

export function useAuth() {
  return useContext(AuthContext);
}
