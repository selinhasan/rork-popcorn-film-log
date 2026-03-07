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
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var authSuccess = false

    @State private var usernameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var confirmPasswordError: String?

    enum FocusField { case username, email, password, confirm }
    @FocusState private var focusedField: FocusField?

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 32)

                headerSection

                Text(isSignUp ? "Create your account" : "Welcome back")
                    .font(.title3)
                    .foregroundStyle(PopcornTheme.sepiaBrown)

                formFields
                    .padding(.horizontal)

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

                actionButton
                    .padding(.horizontal)

                if showEmailExistsAlert {
                    emailExistsBanner
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                switchModeButton

                Spacer().frame(height: 16)
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

    private var headerSection: some View {
        VStack(spacing: 12) {
            PopcornLogoView(size: 90)
                .shadow(color: PopcornTheme.popcornYellow.opacity(0.3), radius: 20, y: 8)

            Text("Popcorn")
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .foregroundStyle(PopcornTheme.darkBrown)
        }
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            if isSignUp {
                VStack(alignment: .leading, spacing: 4) {
                    fieldContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "person.fill")
                                .foregroundStyle(usernameError != nil ? .red : PopcornTheme.sepiaBrown)
                                .frame(width: 20)
                            TextField("Username", text: $username)
                                .textContentType(.username)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                                .onSubmit { focusedField = .email }
                                .onChange(of: username) { _, _ in validateUsername() }
                                .accessibilityLabel("Username")
                        }
                    }
                    if let error = usernameError {
                        errorLabel(error)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                fieldContainer {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(emailError != nil ? .red : PopcornTheme.sepiaBrown)
                            .frame(width: 20)
                        TextField(isSignUp ? "Email" : "Email or Username", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                            .onChange(of: email) { _, _ in validateEmail() }
                            .accessibilityLabel(isSignUp ? "Email address" : "Email or username")
                    }
                }
                if let error = emailError {
                    errorLabel(error)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                fieldContainer {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(passwordError != nil ? .red : PopcornTheme.sepiaBrown)
                            .frame(width: 20)
                        Group {
                            if showPassword {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
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
                        .onChange(of: password) { _, _ in validatePassword() }
                        .accessibilityLabel("Password")

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundStyle(PopcornTheme.subtleGray)
                                .font(.subheadline)
                        }
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }
                }
                if let error = passwordError {
                    errorLabel(error)
                }
                if isSignUp {
                    passwordStrengthIndicator
                }
            }

            if isSignUp {
                VStack(alignment: .leading, spacing: 4) {
                    fieldContainer {
                        HStack(spacing: 12) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(confirmPasswordError != nil ? .red : PopcornTheme.sepiaBrown)
                                .frame(width: 20)
                            Group {
                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                }
                            }
                            .textContentType(.newPassword)
                            .focused($focusedField, equals: .confirm)
                            .submitLabel(.done)
                            .onSubmit { handleAuth() }
                            .onChange(of: confirmPassword) { _, _ in validateConfirmPassword() }
                            .accessibilityLabel("Confirm password")

                            Button {
                                showConfirmPassword.toggle()
                            } label: {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(PopcornTheme.subtleGray)
                                    .font(.subheadline)
                            }
                            .accessibilityLabel(showConfirmPassword ? "Hide confirm password" : "Show confirm password")
                        }
                    }
                    if let error = confirmPasswordError {
                        errorLabel(error)
                    }
                }
            }
        }
    }

    private var passwordStrengthIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { index in
                Capsule()
                    .fill(index < passwordStrength ? strengthColor : PopcornTheme.subtleGray.opacity(0.2))
                    .frame(height: 3)
            }
            if !password.isEmpty {
                Text(strengthLabel)
                    .font(.caption2)
                    .foregroundStyle(strengthColor)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.2), value: passwordStrength)
    }

    private var passwordStrength: Int {
        var strength = 0
        if password.count >= 6 { strength += 1 }
        if password.count >= 10 { strength += 1 }
        if password.range(of: "[A-Z]", options: .regularExpression) != nil &&
           password.range(of: "[0-9]", options: .regularExpression) != nil { strength += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { strength += 1 }
        return strength
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return PopcornTheme.freshGreen
        default: return PopcornTheme.freshGreen
        }
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 0: return "Weak"
        case 1: return "Fair"
        case 2: return "Good"
        case 3...4: return "Strong"
        default: return ""
        }
    }

    private var actionButton: some View {
        Button {
            handleAuth()
        } label: {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                } else {
                    Text(isSignUp ? "Create Account" : "Log In")
                }
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isFormValid ? PopcornTheme.warmRed : PopcornTheme.warmRed.opacity(0.4),
                in: .rect(cornerRadius: 14)
            )
        }
        .disabled(!isFormValid || isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: authSuccess)
    }

    private var emailExistsBanner: some View {
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
                    clearErrors()
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
    }

    private var switchModeButton: some View {
        Button {
            withAnimation(.spring(duration: 0.35)) {
                isSignUp.toggle()
                clearFields()
                showEmailExistsAlert = false
                failedLoginAttempts = 0
                clearErrors()
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

    private func errorLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
            Text(text)
                .font(.caption)
        }
        .foregroundStyle(.red)
        .padding(.leading, 4)
        .transition(.opacity)
    }

    private var isFormValid: Bool {
        if isSignUp {
            return !username.isEmpty && !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
                   usernameError == nil && emailError == nil && passwordError == nil && confirmPasswordError == nil
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }

    private func validateUsername() {
        let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            usernameError = nil
            return
        }
        if trimmed.count < 3 {
            usernameError = "Username must be at least 3 characters"
        } else if trimmed.count > 20 {
            usernameError = "Username must be 20 characters or less"
        } else if trimmed.range(of: "^[a-zA-Z0-9._]+$", options: .regularExpression) == nil {
            usernameError = "Only letters, numbers, dots and underscores"
        } else {
            usernameError = nil
        }
    }

    private func validateEmail() {
        if !isSignUp { emailError = nil; return }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { emailError = nil; return }
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        if trimmed.range(of: emailRegex, options: .regularExpression) == nil {
            emailError = "Please enter a valid email address"
        } else {
            emailError = nil
        }
    }

    private func validatePassword() {
        let trimmed = password
        if trimmed.isEmpty { passwordError = nil; return }
        if isSignUp && trimmed.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = nil
        }
        if !confirmPassword.isEmpty {
            validateConfirmPassword()
        }
    }

    private func validateConfirmPassword() {
        if confirmPassword.isEmpty { confirmPasswordError = nil; return }
        if confirmPassword != password {
            confirmPasswordError = "Passwords don't match"
        } else {
            confirmPasswordError = nil
        }
    }

    private func clearErrors() {
        usernameError = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
    }

    private func handleAuth() {
        focusedField = nil

        if isSignUp {
            validateUsername()
            validateEmail()
            validatePassword()
            validateConfirmPassword()

            guard usernameError == nil, emailError == nil, passwordError == nil, confirmPasswordError == nil else { return }
            guard !username.isEmpty else { showValidation("Please enter a username."); return }
            guard !email.isEmpty else { showValidation("Please enter your email."); return }
            guard !password.isEmpty else { showValidation("Please enter a password."); return }
            guard !confirmPassword.isEmpty else { showValidation("Please confirm your password."); return }

            isLoading = true
            Task {
                do {
                    try await viewModel.signUp(username: username, email: email, password: password)
                    authSuccess.toggle()
                } catch let error as AuthError {
                    if case .emailExists = error {
                        withAnimation(.spring(duration: 0.35)) {
                            showEmailExistsAlert = true
                        }
                    } else if case .usernameExists = error {
                        usernameError = "This username is already taken"
                    } else {
                        showValidation(error.localizedDescription)
                    }
                } catch {
                    showValidation("Connection error. Please check your internet and try again.")
                }
                isLoading = false
            }
        } else {
            guard !email.isEmpty else { showValidation("Please enter your email or username."); return }
            guard !password.isEmpty else { showValidation("Please enter your password."); return }

            isLoading = true
            Task {
                do {
                    try await viewModel.logIn(email: email, password: password)
                    authSuccess.toggle()
                } catch let error as AuthError {
                    if case .invalidCredentials = error {
                        failedLoginAttempts += 1
                        showValidation("Incorrect email or password. Please try again.")
                    } else {
                        showValidation(error.localizedDescription)
                    }
                } catch {
                    showValidation("Connection error. Please check your internet and try again.")
                }
                isLoading = false
            }
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
        showPassword = false
        showConfirmPassword = false
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
                            .accessibilityLabel("Email for password reset")
                    }
                }
                .padding(.horizontal)

                Button {
                    Task {
                        let _ = await viewModel.requestPasswordReset(email: forgotPasswordEmail)
                        showResetConfirmation = true
                    }
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
