//======================================================================
// MARK: - UserSearchResultView.swift
// Path: still/Features/Search/Views/UserSearchResultView.swift
//======================================================================
import SwiftUI

struct UserSearchResultView: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var isLoading = false
    @State private var showProfile = false
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // ユーザー情報
            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName ?? user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // フォローボタン
            if !isCurrentUser {
                Button(action: {
                    navigateToProfile()
                }) {
                    Text("Follow")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red)
                        )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .fullScreenCover(isPresented: $showProfile) {
            OtherUserProfileView(userId: user.id)
        }
    }
    
    private var isCurrentUser: Bool {
        guard let currentUser = AuthManager.shared.currentUser else {
            return false
        }
        return user.id == currentUser.id
    }
    
    private func toggleFollow() {
        isLoading = true
        
        // TODO: フォロー/フォロー解除の実装
        Task {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000)
            isFollowing.toggle()
            isLoading = false
        }
    }
    
    private func navigateToProfile() {
        // プロフィール画面への遷移を実装
        showProfile = true
    }
}

#Preview {
    UserSearchResultView(user: UserProfile(
        id: "1",
        username: "johndoe",
        displayName: "John Doe",
        avatarUrl: nil,
        bio: "Hello world! This is my bio.",
        followersCount: 100,
        followingCount: 50,
        createdAt: Date()
    ))
}