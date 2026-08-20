import { useState } from "react";
import {
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { useNavigation } from "@react-navigation/native";
import { useAuth } from "../context/AuthContext";

export default function LoginScreen() {
  const navigation = useNavigation();
  const { login } = useAuth();

  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  async function handleLogin() {
    setError("");
    setSubmitting(true);

    const result = await login({ identifier, password });

    setSubmitting(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }
  }

  return (
    <KeyboardAvoidingView
      style={styles.screen}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <Text style={styles.title}>Log in</Text>

      <TextInput
        style={styles.input}
        placeholder="Email or username"
        placeholderTextColor="#8a8a85"
        autoCapitalize="none"
        autoCorrect={false}
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
        onPress={() => navigation.navigate("ForgotPassword")}
        style={styles.forgotButton}
      >
        <Text style={styles.forgotText}>Forgot password?</Text>
      </TouchableOpacity>

      {!!error && <Text style={styles.error}>{error}</Text>}

      <TouchableOpacity
        style={[styles.button, styles.primaryButton]}
        onPress={handleLogin}
        disabled={submitting}
      >
        <Text style={styles.primaryButtonText}>
          {submitting ? "Logging in..." : "Log in"}
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.button}
        onPress={() => navigation.navigate("Register")}
      >
        <Text style={styles.linkText}>Create account</Text>
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

  forgotButton: {
    alignSelf: "flex-end",
    marginBottom: 16,
  },

  forgotText: {
    color: "#1c1c1a",
    fontSize: 14,
    textDecorationLine: "underline",
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
