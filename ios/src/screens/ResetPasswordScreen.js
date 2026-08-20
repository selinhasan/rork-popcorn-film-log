import { useState } from "react";

import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
} from "react-native";

import { useAuth } from "../context/AuthContext";


export default function ResetPasswordScreen() {
  const { updatePassword } =
    useAuth();

  const [password, setPassword] =
    useState("");

  const [
    confirmPassword,
    setConfirmPassword,
  ] = useState("");

  const [error, setError] =
    useState("");

  const [submitting, setSubmitting] =
    useState(false);


  async function handleUpdatePassword() {
    setError("");

    if (!password) {
      setError(
        "Please enter a new password."
      );

      return;
    }

    if (password !== confirmPassword) {
      setError(
        "Passwords do not match."
      );

      return;
    }

    setSubmitting(true);

    const result =
      await updatePassword(password);

    setSubmitting(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }

    Alert.alert(
      "Password updated",
      "Your password has been changed successfully."
    );

    /*
      updatePassword() sets
      isPasswordRecovery to false.

      Because the recovery session
      already contains a logged-in user,
      App.jsx will automatically switch
      from this screen to the main app.
    */
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
      <View style={styles.container}>

        <Text style={styles.title}>
          Reset password
        </Text>

        <Text style={styles.description}>
          Enter a new password for
          your account.
        </Text>


        <TextInput
          style={styles.input}
          placeholder="New password"
          placeholderTextColor="#8a8a85"
          secureTextEntry
          autoCapitalize="none"
          value={password}
          onChangeText={setPassword}
        />


        <TextInput
          style={styles.input}
          placeholder="Confirm new password"
          placeholderTextColor="#8a8a85"
          secureTextEntry
          autoCapitalize="none"
          value={confirmPassword}
          onChangeText={
            setConfirmPassword
          }
        />


        {!!error && (
          <Text style={styles.error}>
            {error}
          </Text>
        )}


        <TouchableOpacity
          style={[
            styles.button,
            submitting &&
              styles.disabledButton,
          ]}
          onPress={
            handleUpdatePassword
          }
          disabled={submitting}
        >
          {submitting ? (
            <ActivityIndicator
              color="#fff"
            />
          ) : (
            <Text
              style={
                styles.buttonText
              }
            >
              Update password
            </Text>
          )}
        </TouchableOpacity>

      </View>
    </KeyboardAvoidingView>
  );
}


const styles = StyleSheet.create({
  screen: {
    flex: 1,
    justifyContent: "center",
    padding: 24,
  },

  container: {
    width: "100%",
  },

  title: {
    fontSize: 26,
    fontWeight: "600",
    marginBottom: 8,
  },

  description: {
    fontSize: 15,
    color: "#666",
    marginBottom: 24,
  },

  input: {
    borderWidth: 1,
    borderColor: "#d8d8d4",
    borderRadius: 8,
    padding: 14,
    fontSize: 16,
    marginBottom: 12,
  },

  error: {
    color: "#b3261e",
    fontSize: 13,
    marginBottom: 12,
  },

  button: {
    backgroundColor: "#1c1c1a",
    padding: 14,
    borderRadius: 8,
    alignItems: "center",
    marginTop: 4,
  },

  disabledButton: {
    opacity: 0.6,
  },

  buttonText: {
    color: "#fff",
    fontWeight: "600",
    fontSize: 15,
  },
});
