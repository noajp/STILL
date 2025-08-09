//======================================================================
// MARK: - SettingsView.swift (設定画面)
// Path: foodai/Features/MyPage/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var showSignOutAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.accentRed)
                }
                
                Spacer()
                
                Text("Settings")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(MinimalDesign.Colors.background)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Account Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Account")
                            .font(.caption)
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: PrivacySettingsView()) {
                                HStack {
                                    Label("Privacy Settings", systemImage: "lock.shield")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: EmptyView()) {
                                HStack {
                                    Label("Change Password", systemImage: "lock")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: EmptyView()) {
                                HStack {
                                    Label("Change Email", systemImage: "envelope")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                        }
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Support")
                            .font(.caption)
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        VStack(spacing: 0) {
                            NavigationLink(destination: EmptyView()) {
                                HStack {
                                    Label("Help & Support", systemImage: "questionmark.circle")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: EmptyView()) {
                                HStack {
                                    Label("Terms of Service", systemImage: "doc.text")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            NavigationLink(destination: EmptyView()) {
                                HStack {
                                    Label("Privacy Policy", systemImage: "hand.raised")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(MinimalDesign.Colors.secondary)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.1))
                            
                            HStack {
                                Text("Version")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundColor(MinimalDesign.Colors.secondary)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                        }
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Sign Out & Delete Account Section
                    VStack(spacing: 12) {
                        Button(action: { showSignOutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Button(action: {}) {
                            Text("Delete Account")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding(.top)
            }
            .background(MinimalDesign.Colors.background)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .accentColor(.white)
        }
        .background(MinimalDesign.Colors.background)
        .navigationBarHidden(true)
    }
}

