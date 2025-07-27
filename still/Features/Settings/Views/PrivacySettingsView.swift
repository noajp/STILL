//======================================================================
// MARK: - PrivacySettingsView.swift
// Purpose: Privacy settings view for account privacy controls including private account toggle (プライベートアカウントトグルを含むアカウントプライバシー制御のためのプライバシー設定ビュー)
// Path: still/Features/Settings/Views/PrivacySettingsView.swift
//======================================================================

import SwiftUI

struct PrivacySettingsView: View {
    @StateObject private var viewModel = PrivacySettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                    
                    Spacer()
                    
                    Text("Privacy Settings")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Private Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(MinimalDesign.Colors.accentRed)
                                    .font(.system(size: 20))
                                
                                Text("Private Account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Red Toggle
                                Toggle("", isOn: $viewModel.isPrivateAccount)
                                    .toggleStyle(CustomToggleStyle())
                                    .onChange(of: viewModel.isPrivateAccount) { oldValue, newValue in
                                        viewModel.updatePrivacySetting()
                                    }
                            }
                            
                            Text("When your account is private, only followers you approve can see your photos, articles, and profile information. Your existing followers won't be affected.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(16)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        
                        // Follow Requests Section (only show if private)
                        if viewModel.isPrivateAccount && viewModel.pendingRequestsCount > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                        .foregroundColor(MinimalDesign.Colors.accentRed)
                                        .font(.system(size: 20))
                                    
                                    Text("Follow Requests")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Text("\(viewModel.pendingRequestsCount)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(MinimalDesign.Colors.accentRed)
                                        .cornerRadius(12)
                                }
                                
                                // Show pending requests list
                                ForEach(viewModel.pendingRequests) { request in
                                    FollowRequestRow(request: request, viewModel: viewModel)
                                }
                            }
                            .padding(16)
                            .background(Color.gray.opacity(0.05))
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .background(MinimalDesign.Colors.background)
            .task {
                if let currentUser = authManager.currentUser {
                    await viewModel.loadPrivacySettings(for: currentUser.id)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Custom Red Toggle Style
struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            Spacer()
            
            Button(action: {
                configuration.isOn.toggle()
            }) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(configuration.isOn ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.3))
                    .frame(width: 50, height: 30)
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 26, height: 26)
                            .offset(x: configuration.isOn ? 10 : -10)
                            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// Follow Request Row Component
struct FollowRequestRow: View {
    let request: FollowRequest
    let viewModel: PrivacySettingsViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Picture
            if let avatarUrl = request.followerProfile?.avatarUrl {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(request.followerProfile?.username.prefix(1) ?? "?").uppercased())
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    )
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 2) {
                Text(request.followerProfile?.profileDisplayName ?? "Unknown")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("@\(request.followerProfile?.username ?? "unknown")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Reject Button
                Button(action: {
                    Task {
                        await viewModel.rejectFollowRequest(request)
                    }
                }) {
                    Text("Decline")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                }
                
                // Accept Button
                Button(action: {
                    Task {
                        await viewModel.acceptFollowRequest(request)
                    }
                }) {
                    Text("Accept")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(MinimalDesign.Colors.accentRed)
                        .cornerRadius(20)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#if DEBUG
struct PrivacySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacySettingsView()
            .environmentObject(AuthManager.shared)
    }
}
#endif