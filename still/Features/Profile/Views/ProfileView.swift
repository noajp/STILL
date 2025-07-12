//======================================================================
// MARK: - 6. プロフィール画面の作成
// Path: foodai/Features/Profile/Views/ProfileView.swift (新規作成)
//======================================================================
import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // プロフィールヘッダー
                    VStack {
                        if let avatarUrl = viewModel.userProfile?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                        }
                        
                        Text(viewModel.userProfile?.displayName ?? viewModel.userProfile?.username ?? "Unknown")
                            .font(.system(size: 24, weight: .bold))
                        
                        if let bio = viewModel.userProfile?.bio {
                            Text(bio)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    // 投稿一覧
                    if viewModel.posts.isEmpty {
                        Text("まだ投稿がありません")
                            .foregroundColor(.secondary)
                            .padding(.top, 50)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2),
                            GridItem(.flexible(), spacing: 2)
                        ], spacing: 2) {
                            ForEach(viewModel.posts) { post in
                                RemoteImageView(imageURL: post.mediaUrl)
                                    .aspectRatio(1, contentMode: .fill)
                                    .clipped()
                            }
                        }
                    }
                }
            }
            .refreshable {
                viewModel.loadUserData()
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("ログアウト") {
                        Task {
                            try? await authManager.signOut()
                        }
                    }
                }
            }
        }
    }
}

