//======================================================================
// MARK: - 7. ProfileViewModel の作成
// Path: foodai/Features/Profile/ViewModels/ProfileViewModel.swift
//======================================================================
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var posts: [Post] = []
    @Published var isLoading = false
    
    private let postService = PostService()
    private var hasLoadedInitially = false
    
    init() {
        loadUserDataIfNeeded()
    }
    
    func loadUserDataIfNeeded() {
        guard !hasLoadedInitially else { return }
        loadUserData()
    }
    
    func loadUserData() {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        Task {
            isLoading = true
            
            // ユーザープロフィールを取得
            // TODO: UserService を作成して取得
            
            // ユーザーの投稿を取得
            do {
                let userPosts = try await postService.fetchUserPosts(userId: userId)
                self.posts = userPosts
                self.hasLoadedInitially = true
            } catch {
                print("Error loading user posts: \(error)")
            }
            
            isLoading = false
        }
    }
}

