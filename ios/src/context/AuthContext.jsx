import {
  createContext,
  useContext,
  useEffect,
  useState,
} from "react";

import { Linking } from "react-native";
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
// Parse parameters from a Supabase deep-link URL
// Handles both query parameters and URL fragments
// ---------------------------------------------------------

function getParamsFromUrl(url) {
  const params = {};

  if (!url) return params;

  const queryIndex = url.indexOf("?");
  const hashIndex = url.indexOf("#");

  const sections = [];

  if (queryIndex !== -1) {
    const end = hashIndex !== -1 ? hashIndex : url.length;
    sections.push(url.slice(queryIndex + 1, end));
  }

  if (hashIndex !== -1) {
    sections.push(url.slice(hashIndex + 1));
  }

  sections
    .join("&")
    .split("&")
    .filter(Boolean)
    .forEach((part) => {
      const [rawKey, ...rawValueParts] = part.split("=");

      const rawValue = rawValueParts.join("=");

      if (!rawKey) return;

      const key = decodeURIComponent(rawKey);
      const value = decodeURIComponent(
        (rawValue || "").replace(/\+/g, " ")
      );

      params[key] = value;
    });

  return params;
}


// ---------------------------------------------------------
// Auth provider
// ---------------------------------------------------------

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  // When true, App.jsx displays ResetPasswordScreen
  // instead of the normal logged-in application.
  const [isPasswordRecovery, setIsPasswordRecovery] =
    useState(false);


  // -------------------------------------------------------
  // Session + authentication listener + deep links
  // -------------------------------------------------------

  useEffect(() => {
    let mounted = true;


    async function handleAuthUrl(url) {
      if (!url) return;

      console.log("Auth deep link:", url);

      const params = getParamsFromUrl(url);

      if (params.error) {
        console.error(
          "Supabase auth link error:",
          params.error_description || params.error
        );

        return;
      }

      try {
        /*
         * Depending on your Supabase auth configuration,
         * the recovery link may return either:
         *
         * 1. a PKCE code
         * 2. access_token + refresh_token
         */

        if (params.code) {
          const { error } =
            await supabase.auth.exchangeCodeForSession(
              params.code
            );

          if (error) {
            console.error(
              "Supabase code exchange error:",
              error
            );

            return;
          }
        } else if (
          params.access_token &&
          params.refresh_token
        ) {
          const { error } = await supabase.auth.setSession({
            access_token: params.access_token,
            refresh_token: params.refresh_token,
          });

          if (error) {
            console.error(
              "Supabase setSession error:",
              error
            );

            return;
          }
        }

        // Mark the app as being in password recovery mode.
        if (params.type === "recovery") {
          setIsPasswordRecovery(true);
        }
      } catch (error) {
        console.error(
          "Error processing authentication URL:",
          error
        );
      }
    }


    async function initialiseAuth() {
      try {
        // Load an existing stored Supabase session.
        const {
          data: { session },
          error,
        } = await supabase.auth.getSession();

        if (error) {
          console.error(
            "Supabase getSession error:",
            error
          );
        }

        if (mounted) {
          setUser(session?.user ?? null);
        }

        // Check whether the app was launched from
        // a password-reset email.
        const initialUrl = await Linking.getInitialURL();

        if (initialUrl) {
          await handleAuthUrl(initialUrl);
        }
      } catch (error) {
        console.error(
          "Error initialising authentication:",
          error
        );
      } finally {
        if (mounted) {
          setIsLoading(false);
        }
      }
    }


    initialiseAuth();


    // Listen for Supabase authentication changes.
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(
      (event, session) => {
        console.log("Supabase auth event:", event);

        setUser(session?.user ?? null);

        if (event === "PASSWORD_RECOVERY") {
          setIsPasswordRecovery(true);
        }

        if (event === "SIGNED_OUT") {
          setIsPasswordRecovery(false);
        }
      }
    );


    // Handle a reset link clicked while the app
    // is already running.
    const linkingSubscription =
      Linking.addEventListener(
        "url",
        ({ url }) => {
          handleAuthUrl(url);
        }
      );


    return () => {
      mounted = false;

      subscription.unsubscribe();
      linkingSubscription.remove();
    };
  }, []);


  // -------------------------------------------------------
  // Register
  // -------------------------------------------------------

  async function register({
    username,
    email,
    password,
  }) {
    if (!username?.trim() || !email?.trim()) {
      return {
        ok: false,
        error: "Please fill in every field.",
      };
    }

    const passwordError =
      getPasswordError(password);

    if (passwordError) {
      return {
        ok: false,
        error: passwordError,
      };
    }

    try {
      const { data, error } =
        await supabase.auth.signUp({
          email: email.trim().toLowerCase(),
          password,

          options: {
            data: {
              username: username
                .trim()
                .toLowerCase(),
            },
          },
        });

      if (error) {
        console.error(
          "Supabase signup error:",
          error
        );

        return {
          ok: false,
          error: error.message,
        };
      }

      if (!data.user) {
        return {
          ok: false,
          error:
            "Account could not be created.",
        };
      }

      return {
        ok: true,
        user: data.user,
        session: data.session,
      };
    } catch (error) {
      console.error(
        "Unexpected signup error:",
        error
      );

      return {
        ok: false,
        error:
          "Something went wrong. Please try again.",
      };
    }
  }


  // -------------------------------------------------------
  // Login
  // -------------------------------------------------------

  async function login({
    identifier,
    password,
  }) {
    if (!identifier?.trim() || !password) {
      return {
        ok: false,
        error:
          "Please enter your email and password.",
      };
    }

    try {
      const {
        data: { user: loggedInUser },
        error,
      } =
        await supabase.auth.signInWithPassword({
          email: identifier
            .trim()
            .toLowerCase(),

          password,
        });

      if (error) {
        console.error(
          "Supabase login error:",
          error
        );

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
      console.error(
        "Unexpected login error:",
        error
      );

      return {
        ok: false,
        error:
          "Something went wrong. Please try again.",
      };
    }
  }


  // -------------------------------------------------------
  // Send password reset email
  // -------------------------------------------------------

  async function forgotPassword(
    email,
    redirectTo
  ) {
    if (!email?.trim()) {
      return {
        ok: false,
        error:
          "Please enter your email address.",
      };
    }

    try {
      const { error } =
        await supabase.auth.resetPasswordForEmail(
          email.trim().toLowerCase(),
          {
            redirectTo,
          }
        );

      if (error) {
        console.error(
          "Supabase password reset error:",
          error
        );

        return {
          ok: false,
          error: error.message,
        };
      }

      return {
        ok: true,
      };
    } catch (error) {
      console.error(
        "Unexpected password reset error:",
        error
      );

      return {
        ok: false,
        error:
          "Could not send password reset email. Please try again.",
      };
    }
  }


  // -------------------------------------------------------
  // Set new password after recovery link
  // -------------------------------------------------------

  async function updatePassword(password) {
    const passwordError =
      getPasswordError(password);

    if (passwordError) {
      return {
        ok: false,
        error: passwordError,
      };
    }

    try {
      const { data, error } =
        await supabase.auth.updateUser({
          password,
        });

      if (error) {
        console.error(
          "Supabase update password error:",
          error
        );

        return {
          ok: false,
          error: error.message,
        };
      }

      setIsPasswordRecovery(false);

      return {
        ok: true,
        user: data.user,
      };
    } catch (error) {
      console.error(
        "Unexpected update password error:",
        error
      );

      return {
        ok: false,
        error:
          "Could not update password. Please try again.",
      };
    }
  }


  // -------------------------------------------------------
  // Logout
  // -------------------------------------------------------

  async function logout() {
    try {
      const { error } =
        await supabase.auth.signOut();

      if (error) {
        console.error(
          "Supabase logout error:",
          error
        );

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
      console.error(
        "Unexpected logout error:",
        error
      );

      return {
        ok: false,
        error:
          "Could not log out. Please try again.",
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
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}


export function useAuth() {
  return useContext(AuthContext);
}
