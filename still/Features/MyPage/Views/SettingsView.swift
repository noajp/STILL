//======================================================================
// MARK: - SettingsView.swift (設定画面)
// Path: foodai/Features/MyPage/Views/SettingsView.swift
//======================================================================
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("enableNotifications") private var enableNotifications = true
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
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.accentRed)
            }
            .padding()
            .background(Color(.systemBackground))
            
            Form {
                Section(header: Text("Account")) {
                    NavigationLink(destination: EmptyView()) {
                        Label("Change Password", systemImage: "lock")
                    }
                    
                    NavigationLink(destination: EmptyView()) {
                        Label("Change Email", systemImage: "envelope")
                    }
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Push Notifications", isOn: $enableNotifications)
                        .toggleStyle(SwitchToggleStyle(tint: MinimalDesign.Colors.accentRed))
                    
                    if enableNotifications {
                        VStack(alignment: .leading, spacing: 8) {
                            ToggleRow(title: "New Followers", isOn: .constant(true))
                            ToggleRow(title: "Likes", isOn: .constant(true))
                            ToggleRow(title: "Comments", isOn: .constant(true))
                            ToggleRow(title: "Messages", isOn: .constant(true))
                        }
                        .padding(.leading, 16)
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
                
                Section {
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
                            .destructiveTextButtonStyle()
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
            .accentColor(MinimalDesign.Colors.accentRed)
        }
        .navigationBarHidden(true)
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
            .font(.system(size: 14))
            .toggleStyle(SwitchToggleStyle(tint: MinimalDesign.Colors.accentRed))
    }
}