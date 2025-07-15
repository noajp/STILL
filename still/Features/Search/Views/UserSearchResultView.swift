//======================================================================
// MARK: - UserSearchResultView.swift
// Path: still/Features/Search/Views/UserSearchResultView.swift
//======================================================================
import SwiftUI

struct UserSearchResultView: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var isLoading = false
    
    var body: some View {
        HStack(spacing: 12) {
            // プロフィール画像
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
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
                    toggleFollow()
                }) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else if isFollowing {
                            Text("フォロー中")
                                .font(.system(size: 14, weight: .medium))
                        } else {
                            Text("フォロー")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? .primary : .white)
                    .frame(width: 80, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFollowing ? Color.clear : Color.blue)
                            .stroke(isFollowing ? Color.gray : Color.clear, lineWidth: 1)
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            // プロフィール画面に遷移
            navigateToProfile()
        }
    }
    
    private var isCurrentUser: Bool {
        return user.id == AuthManager.shared.currentUser?.id
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
        // TODO: プロフィール画面への遷移を実装
        print("Navigate to profile: \(user.username)")
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