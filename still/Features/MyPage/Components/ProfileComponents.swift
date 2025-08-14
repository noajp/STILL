//======================================================================
// MARK: - ProfileComponents.swift
// Purpose: Reusable profile UI components extracted from MyPageView
// Path: still/Features/MyPage/Components/ProfileComponents.swift
//======================================================================
import SwiftUI
import PhotosUI

// MARK: - Modern Profile Section
/**
 * Profile header section displaying user info, stats, and bio
 * Used in both MyProfileView and OtherUserProfileView
 */
@MainActor
struct ModernProfileSection: View {
    // MARK: - Properties
    let profile: UserProfile?
    let isLoading: Bool
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let hasNewFollowers: Bool
    let onEditProfile: () -> Void
    let onFollowersTapped: () -> Void
    let onFollowingTapped: () -> Void
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @State private var showGridMode = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                // Profile Image - Rounded Square (Left aligned)
                ProfileImagePicker(
                    profile: profile,
                    selectedPhotoItem: $selectedPhotoItem
                )
                .buttonStyle(PlainButtonStyle())
                
                // Profile Info
                VStack(alignment: .leading, spacing: 8) {
                    // Display Name (Priority display)
                    if let displayName = profile?.displayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    } else if let username = profile?.username {
                        // Show username if no display name
                        Text(username)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .lineLimit(1)
                    }
                    
                    // Username (Gray display)
                    if let username = profile?.username {
                        Text("@\(username)")
                            .font(.system(size: 14, weight: .regular, design: .default))
                            .foregroundColor(MinimalDesign.Colors.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // Edit Profile Button
                    Button(action: onEditProfile) {
                        Text("Edit Profile")
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(MinimalDesign.Colors.primary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Stats Section (Posts, Followers, Following)
            HStack(spacing: 32) {
                StatItem(value: postsCount, label: "Posts")
                
                // Followers with notification dot
                Button(action: onFollowersTapped) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(followersCount)")
                                .font(.system(size: 18, weight: .semibold, design: .default))
                                .foregroundColor(MinimalDesign.Colors.primary)
                            
                            if hasNewFollowers {
                                Circle()
                                    .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        Text("Followers")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(MinimalDesign.Colors.tertiary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onFollowingTapped) {
                    StatItem(value: followingCount, label: "Following")
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            
            // Bio Section
            if let bio = profile?.bio, !bio.isEmpty {
                Text(bio)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, MinimalDesign.Spacing.sm)
            }
        }
        .padding(.top, MinimalDesign.Spacing.sm)
        .padding(.bottom, MinimalDesign.Spacing.md)
        .background(MinimalDesign.Colors.background)
    }
}

// MARK: - Stat Item
/**
 * Individual stat display component for posts/followers/following counts
 */
struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .default))
                .foregroundColor(MinimalDesign.Colors.tertiary)
        }
    }
}

// MARK: - Modern Posts Tab Section
/**
 * Tabbed section for displaying user posts with grid/article views
 */
struct ModernPostsTabSection: View {
    // MARK: - Properties
    let posts: [Post]
    @Binding var selectedPost: Post?
    @Binding var navigateToSingleView: Bool
    let onDeletePost: ((Post) -> Void)?
    let onReorderPosts: (([Post]) -> Void)?
    @State private var selectedTab = 0
    @State private var showGridMode = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Tab Bar - Hidden (grid button removed)
            /*
            HStack(spacing: 0) {
                ProfileTabButton(
                    selectedIcon: "square.grid.3x3.fill",
                    unselectedIcon: "square.grid.3x3",
                    isSelected: selectedTab == 0,
                    action: { selectedTab = 0 }
                )
                

            }
            .padding(.horizontal, MinimalDesign.Spacing.sm)
            .padding(.vertical, 8)
            */
            
            // Content
            Group {
                switch selectedTab {
                case 0:
                    if posts.isEmpty {
                        EmptyStateView(
                            icon: "camera",
                            title: "No Posts Yet",
                            message: "Share your first photo to get started"
                        )
                        .frame(height: 300)
                        .onAppear {
                            print("🔵 ModernPostsTabSection: Showing empty state - posts.count = \(posts.count)")
                        }
                    } else {
                        if showGridMode {
                            GridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost, onReorderPosts: onReorderPosts)
                                .transition(AnyTransition.opacity)
                                .onAppear {
                                    print("🔵 ModernPostsTabSection: Showing GridView with \(posts.count) posts")
                                }
                        } else {
                            SingleCardGridView(posts: posts, onPostTapped: { post in
                                selectedPost = post
                                navigateToSingleView = true
                            }, onDeletePost: onDeletePost, onReorderPosts: onReorderPosts)
                                .transition(AnyTransition.opacity)
                                .onAppear {
                                    print("🔵 ModernPostsTabSection: Showing SingleCardGridView with \(posts.count) posts")
                                }
                        }
                    }

                default:
                    EmptyView()
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedTab)
        }
    }
}

// MARK: - Profile Tab Button
/**
 * Individual tab button for profile post/article sections
 */
struct ProfileTabButton: View {
    let selectedIcon: String
    let unselectedIcon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isSelected ? selectedIcon : unselectedIcon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? MinimalDesign.Colors.primary : MinimalDesign.Colors.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
/**
 * Empty state display for when there's no content
 */
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MinimalDesign.Colors.tertiary)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(MinimalDesign.Colors.primary)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(MinimalDesign.Colors.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Profile Image Picker
/**
 * Profile image picker component with PhotosPicker integration
 */
@MainActor
struct ProfileImagePicker: View {
    let profile: UserProfile?
    @Binding var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            if let avatarUrl = profile?.avatarUrl {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 3)
                    )
            }
        }
    }
}