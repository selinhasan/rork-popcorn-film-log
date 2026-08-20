import { useState } from "react";

import {
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from "react-native";

import { useNavigation } from "@react-navigation/native";
import { useAuth } from "../context/AuthContext";


// This must match the URL scheme
// configured for the app.
const PASSWORD_RESET_REDIRECT =
  "popcorn://reset-password";


export default function LoginScreen() {
  const navigation = useNavigation();

  const {
    login,
    forgotPassword,
  } = useAuth();

  const [identifier, setIdentifier] =
    useState("");

  const [password, setPassword] =
    useState("");

  const [error, setError] =
    useState("");

  const [submitting, setSubmitting] =
    useState(false);

  const [sendingReset, setSendingReset] =
    useState(false);


  // -------------------------------------------------------
  // Login
  // -------------------------------------------------------

  async function handleLogin() {
    setError("");
    setSubmitting(true);

    const result = await login({
      identifier,
      password,
    });

    setSubmitting(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }

    // No manual navigation required.
    // AuthContext updates `user`,
    // causing RootNavigator to switch
    // to the main app automatically.
  }


  // -------------------------------------------------------
  // Forgot password
  // -------------------------------------------------------

  async function handleForgotPassword() {
    setError("");

    const email = identifier.trim();

    if (!email) {
      setError(
        "Enter your email address first."
      );

      return;
    }

    if (!email.includes("@")) {
      setError(
        "Please enter a valid email address."
      );

      return;
    }

    setSendingReset(true);

    const result =
      await forgotPassword(
        email,
        PASSWORD_RESET_REDIRECT
      );

    setSendingReset(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }

    Alert.alert(
      "Check your email",
      "We've sent you a password reset link."
    );
  }


  return (
    <KeyboardAvoidingView
      style={styles.screen}
      behavior={
        Platform.OS === "ios"
          ? "padding"
          : undefined
      }
    >
      <Text style={styles.title}>
        Log in
      </Text>


      <TextInput
        style={styles.input}
        placeholder="Email"
        placeholderTextColor="#8a8a85"
        autoCapitalize="none"
        autoCorrect={false}
        keyboardType="email-address"
        value={identifier}
        onChangeText={setIdentifier}
      />


      <TextInput
        style={styles.input}
        placeholder="Password"
        placeholderTextColor="#8a8a85"
        secureTextEntry
        value={password}
        onChangeText={setPassword}
      />


      <TouchableOpacity
        style={
          styles.forgotPasswordButton
        }
        onPress={
          handleForgotPassword
        }
        disabled={sendingReset}
      >
        <Text style={styles.linkText}>
          {sendingReset
            ? "Sending..."
            : "Forgot password?"}
        </Text>
      </TouchableOpacity>


      {!!error && (
        <Text style={styles.error}>
          {error}
        </Text>
      )}


      <TouchableOpacity
        style={[
          styles.button,
          styles.primaryButton,
          submitting &&
            styles.disabledButton,
        ]}
        onPress={handleLogin}
        disabled={
          submitting ||
          sendingReset
        }
      >
        <Text
          style={
            styles.primaryButtonText
          }
        >
          {submitting
            ? "Logging in..."
            : "Log in"}
        </Text>
      </TouchableOpacity>


      <TouchableOpacity
        style={styles.button}
        onPress={() =>
          navigation.navigate(
            "Register"
          )
        }
      >
        <Text style={styles.linkText}>
          Create account
        </Text>
      </TouchableOpacity>

    </KeyboardAvoidingView>
  );
}


const styles = StyleSheet.create({
  screen: {
    flex: 1,
    justifyContent: "center",
    padding: 24,
  },

  title: {
    fontSize: 26,
    fontWeight: "600",
    marginBottom: 20,
  },

  input: {
    borderWidth: 1,
    borderColor: "#d8d8d4",
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    marginBottom: 12,
  },

  forgotPasswordButton: {
    alignSelf: "flex-end",
    marginBottom: 16,
    marginTop: -2,
  },

  button: {
    padding: 14,
    borderRadius: 8,
    alignItems: "center",
    marginBottom: 8,
  },

  primaryButton: {
    backgroundColor: "#1c1c1a",
  },

  disabledButton: {
    opacity: 0.6,
  },

  primaryButtonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 15,
  },

  linkText: {
    color: "#1c1c1a",
    textDecorationLine: "underline",
  },

  error: {
    color: "#b3261e",
    fontSize: 13,
    marginBottom: 8,
  },
});
