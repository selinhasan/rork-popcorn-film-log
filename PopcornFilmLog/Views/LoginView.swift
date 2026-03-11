import SwiftUI

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authViewModel
    @State private var isRegistering = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case username, email, password, confirmPassword
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                VStack(spacing: 8) {
                    Image(systemName: "popcorn.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(PopcornTheme.popcornYellow)
                        .shadow(color: PopcornTheme.warmRed.opacity(0.3), radius: 8, y: 4)

                    Text("Popcorn")
                        .font(.largeTitle.bold())
                        .foregroundStyle(PopcornTheme.darkBrown)

                    Text("Film Log")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                }
                .padding(.bottom, 40)

                VStack(spacing: 16) {
                    if isRegistering {
                        fieldRow(icon: "person.fill", placeholder: "Username", text: $username, field: .username)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                    }

                    fieldRow(icon: "envelope.fill", placeholder: "Email", text: $email, field: .email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)

                    fieldRow(icon: "lock.fill", placeholder: "Password", text: $password, field: .password, isSecure: true)
                        .textContentType(isRegistering ? .newPassword : .password)

                    if isRegistering {
                        fieldRow(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword, field: .confirmPassword, isSecure: true)
                            .textContentType(.newPassword)
                    }
                }
                .padding(.horizontal, 24)

                if let error = authViewModel.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.footnote)
                    }
                    .foregroundStyle(PopcornTheme.warmRed)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .multilineTextAlignment(.center)
                }

                Button {
                    focusedField = nil
                    Task { await performAction() }
                } label: {
                    Group {
                        if authViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(isRegistering ? "Create Account" : "Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
                .disabled(authViewModel.isLoading || !isFormValid)
                .opacity(isFormValid ? 1 : 0.6)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        isRegistering.toggle()
                        authViewModel.errorMessage = nil
                        confirmPassword = ""
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isRegistering ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                        Text(isRegistering ? "Sign In" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(PopcornTheme.warmRed)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 20)

                Spacer().frame(height: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PopcornTheme.backgroundGradient.ignoresSafeArea())
    }

    private var isFormValid: Bool {
        if isRegistering {
            return !username.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword && password.count >= 6
        }
        return !email.isEmpty && !password.isEmpty
    }

    private func performAction() async {
        if isRegistering {
            guard password == confirmPassword else {
                authViewModel.errorMessage = "Passwords don't match."
                return
            }
            await authViewModel.register(username: username, email: email, password: password)
        } else {
            await authViewModel.login(email: email, password: password)
        }
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>, field: Field, isSecure: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(PopcornTheme.sepiaBrown)
                .frame(width: 24)

            if isSecure {
                SecureField(placeholder, text: text)
                    .focused($focusedField, equals: field)
            } else {
                TextField(placeholder, text: text)
                    .focused($focusedField, equals: field)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white, in: .rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
