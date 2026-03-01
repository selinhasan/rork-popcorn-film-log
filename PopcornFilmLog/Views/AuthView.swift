import SwiftUI

struct AuthView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isSignUp = true
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showError = false
    @State private var errorMessage = ""

    enum FocusField { case username, email, password, confirm }
    @FocusState private var focusedField: FocusField?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 20)

                PopcornLogoView(size: 100)
                    .shadow(color: PopcornTheme.popcornYellow.opacity(0.3), radius: 20, y: 8)

                Text("Popcorn")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(PopcornTheme.darkBrown)

                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.title3)
                    .foregroundStyle(PopcornTheme.sepiaBrown)

                VStack(spacing: 16) {
                    if isSignUp {
                        fieldContainer {
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                                    .frame(width: 20)
                                TextField("Username", text: $username)
                                    .textContentType(.username)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                                    .focused($focusedField, equals: .username)
                                    .submitLabel(.next)
                                    .onSubmit { focusedField = .email }
                            }
                        }
                    }

                    fieldContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .frame(width: 20)
                            TextField("Email", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .email)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .password }
                        }
                    }

                    fieldContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(PopcornTheme.sepiaBrown)
                                .frame(width: 20)
                            SecureField("Password", text: $password)
                                .textContentType(isSignUp ? .newPassword : .password)
                                .focused($focusedField, equals: .password)
                                .submitLabel(isSignUp ? .next : .done)
                                .onSubmit {
                                    if isSignUp {
                                        focusedField = .confirm
                                    } else {
                                        handleAuth()
                                    }
                                }
                        }
                    }

                    if isSignUp {
                        fieldContainer {
                            HStack(spacing: 12) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(PopcornTheme.sepiaBrown)
                                    .frame(width: 20)
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirm)
                                    .submitLabel(.done)
                                    .onSubmit { handleAuth() }
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Button {
                    handleAuth()
                } label: {
                    Text(isSignUp ? "Create Account" : "Log In")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(PopcornTheme.warmRed, in: .rect(cornerRadius: 14))
                }
                .padding(.horizontal)
                .sensoryFeedback(.impact(weight: .medium), trigger: isSignUp)

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        isSignUp.toggle()
                        clearFields()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                        Text(isSignUp ? "Log In" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(PopcornTheme.warmRed)
                    }
                    .font(.subheadline)
                }

                Spacer()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(PopcornTheme.cream.ignoresSafeArea())
        .alert("Oops", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func fieldContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(14)
            .background(Color.white, in: .rect(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(PopcornTheme.sepiaBrown.opacity(0.15), lineWidth: 1)
            )
    }

    private func handleAuth() {
        if isSignUp {
            guard !username.isEmpty else { showValidation("Please enter a username."); return }
            guard !email.isEmpty else { showValidation("Please enter your email."); return }
            guard !password.isEmpty else { showValidation("Please enter a password."); return }
            guard password == confirmPassword else { showValidation("Passwords don't match."); return }
            guard password.count >= 6 else { showValidation("Password must be at least 6 characters."); return }
            viewModel.signUp(username: username, email: email, password: password)
        } else {
            guard !email.isEmpty else { showValidation("Please enter your email."); return }
            guard !password.isEmpty else { showValidation("Please enter a password."); return }
            viewModel.logIn(email: email, password: password)
        }
    }

    private func showValidation(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func clearFields() {
        username = ""
        email = ""
        password = ""
        confirmPassword = ""
        focusedField = nil
    }
}
