//======================================================================
// MARK: - ForgotPasswordView.swift (Simple & Modern)
// Path: foodai/Core/Auth/Views/ForgotPasswordView.swift
//======================================================================
import SwiftUI

struct ForgotPasswordView: View {
    @State private var email = ""
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button("←") {
                    dismiss()
                }
                .font(.system(size: 24))
                .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 40) {
                // Title
                Text("RESET PASSWORD")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.white)
                
                // Description
                Text("Please enter your registered email address. We will send you a password reset link.")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(nil)
                
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
                        .disabled(isLoading)
                        .padding(.bottom, 10)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.white.opacity(0.5)),
                            alignment: .bottom
                        )
                }
                
                // Send Reset Link Button
                Button(action: {
                    Task {
                        await resetPassword()
                    }
                }) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("SEND RESET LINK")
                                .font(.system(size: 18, weight: .medium))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(email.contains("@") ? MinimalDesign.Colors.accentRed : Color.gray)
                }
                .disabled(!email.contains("@") || isLoading)
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .background(MinimalDesign.Colors.background)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .alert("Success", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset link has been sent to \(email). Please check your email.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func resetPassword() async {
        isLoading = true
        
        do {
            try await authManager.resetPassword(email: email)
            await MainActor.run {
                showSuccess = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Password reset failed: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
}