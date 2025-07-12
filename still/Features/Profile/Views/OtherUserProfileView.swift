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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Spacer()
                    
                    Text("Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Spacer()
                    
                    // Placeholder for balance
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Profile section
                VStack(spacing: 24) {
                    HStack(alignment: .top, spacing: 16) {
                        // Profile image
                        if let avatarUrl = viewModel.userProfile?.avatarUrl {
                            AsyncImage(url: URL(string: avatarUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            }
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
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .lineLimit(1)
                            } else if let username = viewModel.userProfile?.username {
                                Text(username)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
                            
                            // Follow/Unfollow button
                            Button(action: {
                                Task {
                                    await viewModel.toggleFollow()
                                }
                            }) {
                                Text(viewModel.isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(viewModel.isFollowing ? (colorScheme == .dark ? .white : .black) : .white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(viewModel.isFollowing ? Color.clear : Color(red: 0.949, green: 0.098, blue: 0.020))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(viewModel.isFollowing ? (colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)) : Color.clear, lineWidth: 1)
                                    )
                                    .cornerRadius(6)
                            }
                            .disabled(viewModel.isLoading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 32) {
                        StatItem(value: viewModel.postsCount, label: "Posts")
                        StatItem(value: viewModel.followersCount, label: "Followers")
                        StatItem(value: viewModel.followingCount, label: "Following")
                    }
                    .padding(.horizontal)
                    
                    // Bio
                    if let bio = viewModel.userProfile?.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                
                // Posts grid
                if viewModel.userPosts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "camera")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No Posts Yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .frame(height: 300)
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 1.5),
                        GridItem(.flexible(), spacing: 1.5),
                        GridItem(.flexible(), spacing: 1.5)
                    ], spacing: 1.5) {
                        ForEach(viewModel.userPosts) { post in
                            GeometryReader { geometry in
                                AsyncImage(url: URL(string: post.mediaUrl)) { phase in
                                    switch phase {
                                    case .empty:
                                        Rectangle()
                                            .fill(Color(.tertiarySystemBackground))
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                            .clipped()
                                    case .failure(_):
                                        Rectangle()
                                            .fill(Color(.tertiarySystemBackground))
                                            .frame(width: geometry.size.width, height: geometry.size.width)
                                            .overlay(
                                                Image(systemName: "photo")
                                                    .foregroundColor(.gray)
                                            )
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .padding(.horizontal, 1.5)
                }
            }
        }
        .background(Color(.systemBackground))
        .navigationBarHidden(true)
        .task {
            await viewModel.loadUserData(userId: userId)
        }
    }
}

// MARK: - ViewModel

@MainActor
class OtherUserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var userPosts: [Post] = []
    @Published var isFollowing: Bool = false
    @Published var isLoading: Bool = false
    @Published var postsCount: Int = 0
    @Published var followersCount: Int = 0
    @Published var followingCount: Int = 0
    
    private let userRepository = UserRepository()
    private let followService = FollowService.shared
    
    func loadUserData(userId: String) async {
        isLoading = true
        
        do {
            // Load profile
            userProfile = try await userRepository.fetchUserProfile(userId: userId)
            
            // Load posts
            userPosts = try await userRepository.fetchUserPosts(userId: userId)
            
            // Update counts
            postsCount = userPosts.count
            followersCount = userProfile?.followersCount ?? 0
            followingCount = userProfile?.followingCount ?? 0
            
            // Check follow status
            let followStatus = try await followService.checkFollowStatus(userId: userId)
            isFollowing = followStatus.isFollowing
            
        } catch {
            print("Error loading user data: \(error)")
        }
        
        isLoading = false
    }
    
    func toggleFollow() async {
        guard let userId = userProfile?.id else { return }
        
        isLoading = true
        
        do {
            if isFollowing {
                try await followService.unfollowUser(userId: userId)
                isFollowing = false
                followersCount = max(0, followersCount - 1)
            } else {
                try await followService.followUser(userId: userId)
                isFollowing = true
                followersCount += 1
            }
        } catch {
            print("Error toggling follow: \(error)")
        }
        
        isLoading = false
    }
}