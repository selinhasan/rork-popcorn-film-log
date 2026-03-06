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
    @State private var failedLoginAttempts: Int = 0
    @State private var showForgotPassword = false
    @State private var showEmailExistsAlert = false
    @State private var forgotPasswordEmail = ""
    @State private var showResetConfirmation = false

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

                if !isSignUp && failedLoginAttempts >= 2 {
                    Button {
                        showForgotPassword = true
                        forgotPasswordEmail = email
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(PopcornTheme.warmRed)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if showEmailExistsAlert {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("This email is already connected to an account.")
                                .font(.subheadline)
                                .foregroundStyle(PopcornTheme.darkBrown)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1), in: .rect(cornerRadius: 12))

                        Button {
                            withAnimation(.spring(duration: 0.35)) {
                                isSignUp = false
                                showEmailExistsAlert = false
                                password = ""
                                confirmPassword = ""
                                username = ""
                            }
                        } label: {
                            Text("Go to Log In")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(PopcornTheme.sepiaBrown, in: .rect(cornerRadius: 10))
                        }
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Button {
                    withAnimation(.spring(duration: 0.35)) {
                        isSignUp.toggle()
                        clearFields()
                        showEmailExistsAlert = false
                        failedLoginAttempts = 0
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
        .sheet(isPresented: $showForgotPassword) {
            forgotPasswordSheet
        }
        .alert("Check Your Email", isPresented: $showResetConfirmation) {
            Button("OK") { showForgotPassword = false }
        } message: {
            Text("If an account exists for that email, we've sent password reset instructions.")
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

            let registeredEmails = UserDefaults.standard.stringArray(forKey: "registeredEmails") ?? []
            if registeredEmails.contains(email.lowercased()) {
                withAnimation(.spring(duration: 0.35)) {
                    showEmailExistsAlert = true
                }
                return
            }

            var updated = registeredEmails
            updated.append(email.lowercased())
            UserDefaults.standard.set(updated, forKey: "registeredEmails")

            viewModel.signUp(username: username, email: email, password: password)
        } else {
            guard !email.isEmpty else { showValidation("Please enter your email."); return }
            guard !password.isEmpty else { showValidation("Please enter a password."); return }

            failedLoginAttempts += 1

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

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundStyle(PopcornTheme.warmRed)

                    Text("Reset Password")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(PopcornTheme.darkBrown)

                    Text("Enter your email and we'll send you instructions to reset your password.")
                        .font(.subheadline)
                        .foregroundStyle(PopcornTheme.sepiaBrown)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 32)

                fieldContainer {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(PopcornTheme.sepiaBrown)
                            .frame(width: 20)
                        TextField("Email", text: $forgotPasswordEmail)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .padding(.horizontal)

                Button {
                    showResetConfirmation = true
                } label: {
                    Text("Send Reset Link")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            forgotPasswordEmail.isEmpty
                                ? PopcornTheme.warmRed.opacity(0.4)
                                : PopcornTheme.warmRed,
                            in: .rect(cornerRadius: 14)
                        )
                }
                .disabled(forgotPasswordEmail.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .background(PopcornTheme.cream.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showForgotPassword = false
                    }
                    .foregroundStyle(PopcornTheme.warmRed)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
