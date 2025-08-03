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
            
            Form {
                Section(header: Text("Account")) {
                    NavigationLink(destination: PrivacySettingsView()) {
                        Label("Privacy Settings", systemImage: "lock.shield")
                            .foregroundColor(.white)
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Change Password", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Change Email", systemImage: "envelope")
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                    }
                }
                
                Section(header: Text("")) {
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                            Text("Sign Out")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: {}) {
                        Text("Delete Account")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
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
        .navigationBarHidden(true)
    }
}

