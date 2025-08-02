//======================================================================
// MARK: - MyProfileView.swift
// Purpose: User's own profile display extracted from MyPageView
// Path: still/Features/MyPage/Views/MyProfileView.swift
//======================================================================
import SwiftUI
import PhotosUI

/**
 * User's own profile view displaying profile info and posts
 * Handles profile editing, photo updates, and post management
 */
@MainActor
struct MyProfileView: View {
    // MARK: - Properties
    @StateObject var viewModel: MyPageViewModel
    @EnvironmentObject var authManager: AuthManager
    @Binding var isInProfileSingleView: Bool
    @State private var showEditProfile = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPost: Post?
    @State private var navigateToSingleView: Bool = false
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    
    // MARK: - Body
    var body: some View {
        LazyVStack(spacing: 0) {
            // Profile Section
            ModernProfileSection(
                profile: viewModel.userProfile,
                isLoading: viewModel.isLoading,
                postsCount: viewModel.postsCount,
                followersCount: viewModel.followersCount,
                followingCount: viewModel.followingCount,
                hasNewFollowers: viewModel.hasNewFollowers,
                onEditProfile: { showEditProfile = true },
                onFollowersTapped: onFollowersTapped,
                onFollowingTapped: onFollowingTapped,
                selectedPhotoItem: $selectedPhotoItem
            )
            
            // Posts Tab Section
            ModernPostsTabSection(
                posts: viewModel.userPosts,
                selectedPost: $selectedPost,
                navigateToSingleView: $navigateToSingleView,
                onDeletePost: { post in
                    Task {
                        await viewModel.deletePost(post)
                    }
                },
                onReorderPosts: { reorderedPosts in
                    Task {
                        await viewModel.reorderPosts(reorderedPosts)
                    }
                }
            )
            .onAppear {
                print("🔵 MyProfileView: ModernPostsTabSection appeared with \(viewModel.userPosts.count) posts")
                for (index, post) in viewModel.userPosts.enumerated() {
                    print("📋 UI Post \(index + 1): ID=\(post.id)")
                }
            }
            
            // Bottom padding for tab bar
            Color.clear
                .frame(height: 110)
        }
        .navigationDestination(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showFollowersList) {
            FollowListView(
                isShowingFollowers: true,
                userId: authManager.currentUser?.id ?? "",
                hasNewFollowers: viewModel.hasNewFollowers
            )
            .onDisappear {
                Task {
                    await viewModel.markFollowersAsSeen()
                }
            }
        }
        .navigationDestination(isPresented: $showFollowingList) {
            FollowListView(
                isShowingFollowers: false,
                userId: authManager.currentUser?.id ?? ""
            )
        }
        .task {
            print("🔵 MyProfileView: Task started")
            print("🔵 MyProfileView: Current user ID from AuthManager: \(authManager.currentUser?.id ?? "nil")")
            await viewModel.loadUserDataIfNeeded()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await viewModel.updateProfilePhoto(item: newItem)
            }
        }
        .navigationDestination(isPresented: $navigateToSingleView) {
            if let selectedPost = selectedPost {
                ProfileSinglePostView(
                    initialPost: selectedPost,
                    allPosts: viewModel.userPosts,
                    viewModel: viewModel
                )
                .onAppear {
                    isInProfileSingleView = true
                }
                .onDisappear {
                    isInProfileSingleView = false
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    private func onFollowersTapped() {
        showFollowersList = true
        print("🔵 MyProfileView: Followers tapped")
    }
    
    private func onFollowingTapped() {
        showFollowingList = true
        print("🔵 MyProfileView: Following tapped")
    }
}