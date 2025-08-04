//======================================================================
// MARK: - SignInView.swift (Simple & Modern)
// Path: foodai/Core/Auth/Views/SignInView.swift
//======================================================================
import SwiftUI



struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: 120)
                
                VStack(alignment: .leading, spacing: 40) {
                    // Title
                    Text("LOG IN")
                        .font(.system(size: 32, weight: .regular))
                        .foregroundColor(.white)
                
                // Form
                VStack(alignment: .leading, spacing: 25) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("EMAIL")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        TextField("", text: $email)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .padding(.bottom, 10)
                            .focused($isEmailFocused)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white.opacity(0.5)),
                                alignment: .bottom
                            )
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("PASSWORD")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        SecureField("", text: $password)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding(.bottom, 10)
                            .focused($isPasswordFocused)
                            .overlay(
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(.white.opacity(0.5)),
                                alignment: .bottom
                            )
                    }
                    
                    // Forgot Password
                    Button("Have you forgotten your password?") {
                        showForgotPassword = true
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.top, -10)
                }
                
                // Buttons
                VStack(spacing: 15) {
                    // Login Button
                    Button(action: {
                        Task {
                            await signInWithEmail()
                        }
                    }) {
                        Text("LOG IN")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(MinimalDesign.Colors.accentRed)
                            .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(email.isEmpty || password.isEmpty || authManager.isLoading)
                    
                    // OR Divider
                    HStack {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .padding(.vertical, 10)
                    
                    // OAuth Buttons
                    VStack(spacing: 12) {
                        // Google Sign In
                        Button(action: {
                            Task {
                                await signInWithGoogle()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                Text("Sign in with Google")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 1)
                                    .background(MinimalDesign.Colors.background)
                            )
                        }
                        .disabled(authManager.isLoading)
                        
                        // Apple Sign In
                        Button(action: {
                            Task {
                                await signInWithApple()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                Text("Sign in with Apple")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 1)
                                    .background(MinimalDesign.Colors.background)
                            )
                        }
                        .disabled(authManager.isLoading)
                    }
                    
                    // Register Button
                    Button(action: {
                        showSignUp = true
                    }) {
                        Text("REGISTER")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                Rectangle()
                                    .stroke(Color.white, lineWidth: 1)
                                    .background(MinimalDesign.Colors.background)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
        .onTapGesture {
            // キーボードを閉じる
            isEmailFocused = false
            isPasswordFocused = false
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authManager)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authManager)
        }
    }
    
    // MARK: - Authentication Methods
    
    private func signInWithEmail() async {
        do {
            try await authManager.signInWithEmail(email: email, password: password)
        } catch {
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
            }
        }
    }
    
    private func signInWithGoogle() async {
        do {
            try await authManager.signInWithGoogle()
        } catch {
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
            }
        }
    }
    
    private func signInWithApple() async {
        do {
            try await authManager.signInWithApple()
        } catch {
            await MainActor.run {
                errorMessage = handleAuthError(error)
                showError = true
            }
        }
    }
    
    private func handleAuthError(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid login credentials") {
            return "Invalid email or password"
        } else if errorDescription.contains("email not confirmed") {
            return "Email not confirmed"
        } else if errorDescription.contains("too many requests") {
            return "Too many attempts. Please try again later"
        } else if errorDescription.contains("network") {
            return "Please check your network connection"
        } else {
            return "Login failed: \(error.localizedDescription)"
        }
    }
}