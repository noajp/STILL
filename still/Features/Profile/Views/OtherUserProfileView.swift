//======================================================================
// MARK: - OtherUserProfileView.swift
// Purpose: View for displaying other users' profiles with follow functionality
// Path: still/Features/Profile/Views/OtherUserProfileView.swift
//======================================================================
import SwiftUI

struct OtherUserProfileView: View {
    let userId: String
    @StateObject private var viewModel = OtherUserProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    // Computed properties for follow button
    private var followButtonText: String {
        switch viewModel.followStatus {
        case .accepted:
            return "Following"
        case .pending:
            return "Requested"
        case .declined, .none:
            return "Follow"
        }
    }
    
    private var buttonTextColor: Color {
        switch viewModel.followStatus {
        case .accepted:
            return MinimalDesign.Colors.primary
        case .pending:
            return .gray
        case .declined, .none:
            return .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch viewModel.followStatus {
        case .accepted:
            return Color.clear
        case .pending:
            return Color.gray.opacity(0.2)
        case .declined, .none:
            return MinimalDesign.Colors.accentRed
        }
    }
    
    private var buttonBorderColor: Color {
        switch viewModel.followStatus {
        case .accepted:
            return MinimalDesign.Colors.primary.opacity(0.3)
        case .pending:
            return Color.gray.opacity(0.5)
        case .declined, .none:
            return Color.clear
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.accentRed)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("Profile")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.primary)
                        
                        // Lock icon for private accounts
                        if viewModel.userProfile?.isPrivate == true {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color(hex: "121212"))
                
                // Profile section
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 16) {
                        // Profile image (compressed for performance)
                        if let avatarUrl = viewModel.userProfile?.avatarUrl {
                            CompressedAsyncImage(
                                urlString: avatarUrl,
                                quality: .medium
                            ) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Profile info and follow button
                        VStack(alignment: .leading, spacing: 8) {
                            // Display name
                            if let displayName = viewModel.userProfile?.displayName, !displayName.isEmpty {
                                Text(displayName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .lineLimit(1)
                            } else if let username = viewModel.userProfile?.username {
                                Text(username)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(MinimalDesign.Colors.primary)
                                    .lineLimit(1)
                            }
                            
                            // Username
                            if let username = viewModel.userProfile?.username {
                                Text("@\(username)")
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer(minLength: 8)
                            
                            // Follow/Unfollow/Accept button with request status (only for other users)
                            if !viewModel.isCurrentUser {
                                Button(action: {
                                    Task {
                                        if viewModel.followStatus == .accepted {
                                            await viewModel.unfollowUser()
                                        } else if viewModel.followStatus == .pending {
                                            await viewModel.cancelFollowRequest()
                                        } else {
                                            await viewModel.followUser()
                                        }
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        if viewModel.followStatus == .pending {
                                            Image(systemName: "clock")
                                                .font(.system(size: 12))
                                        }
                                        
                                        Text(followButtonText)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(buttonTextColor)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(buttonBackgroundColor)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(buttonBorderColor, lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                                }
                                .disabled(viewModel.isLoading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 32) {
                        StatItem(value: viewModel.postsCount, label: "Posts")
                        
                        Button(action: {
                            viewModel.showFollowersList = true
                        }) {
                            StatItem(value: viewModel.followersCount, label: "Followers")
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            viewModel.showFollowingList = true
                        }) {
                            StatItem(value: viewModel.followingCount, label: "Following")
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Bio
                    if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Posts grid or private account message
                if viewModel.userProfile?.isPrivate == true && viewModel.followStatus != .accepted {
                    // Private account - show restricted access message
                    VStack(spacing: 16) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("This Account is Private")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.primary)
                        
                        Text("Follow this account to see their photos and articles")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(height: 300)
                } else if viewModel.userPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Posts Yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                    .frame(height: 300)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 7),
                        GridItem(.flexible(), spacing: 7),
                        GridItem(.flexible(), spacing: 7)
                    ], spacing: 7) {
                        ForEach(viewModel.userPosts) { post in
                            GeometryReader { geometry in
                                CompressedAsyncImage(
                                    urlString: post.mediaUrl,
                                    quality: .medium
                                ) {
                                    Rectangle()
                                        .fill(Color(.tertiarySystemBackground))
                                        .overlay(
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .tint(.secondary)
                                        )
                                }
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.width)
                                .clipped()
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal, 1.5)
                }
            }
        }
        .background(Color(hex: "121212"))
        .navigationBarHidden(true)
        .onAppear {
            print("🔵 OtherUserProfileView appeared - userId: \(userId)")
        }
        .task {
            print("🔵 OtherUserProfileView loading data for userId: \(userId)")
            await viewModel.loadUserData(userId: userId)
        }
        .fullScreenCover(isPresented: $viewModel.showFollowersList) {
            FollowListView(userId: userId, listType: .followers)
                .environmentObject(AuthManager.shared)
        }
        .fullScreenCover(isPresented: $viewModel.showFollowingList) {
            FollowListView(userId: userId, listType: .following)
                .environmentObject(AuthManager.shared)
        }
    }
}

