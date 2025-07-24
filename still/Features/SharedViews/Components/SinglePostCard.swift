//======================================================================
// MARK: - SinglePostCard.swift
// Purpose: Reusable single post card component
// Path: still/Features/SharedViews/Components/SinglePostCard.swift
//======================================================================
import SwiftUI

struct SinglePostCard: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    @State private var showingProfile = false
    
    var body: some View {
        VStack(spacing: 0) {
            // ユーザー情報ヘッダー
            userHeader
            
            // 画像部分
            imageSection
            
            // アクション部分
            actionSection
            
            // キャプション
            if let caption = post.caption, !caption.isEmpty {
                captionSection(caption: caption)
            }
        }
        .background(Color(.systemBackground))
        .onAppear {
            print("🔍 SinglePostCard - Post ID: \(post.id)")
            print("🔍 SinglePostCard - User ID: \(post.userId)")
            print("🔍 SinglePostCard - User object: \(post.user?.username ?? "nil")")
            print("🔍 SinglePostCard - Avatar URL: \(post.user?.avatarUrl ?? "nil")")
        }
    }
    
    // MARK: - ユーザーヘッダー
    private var userHeader: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // アバター
            if let user = post.user {
                NavigationLink(destination: OtherUserProfileView(userId: user.id)) {
                    Group {
                        if let avatarUrl = post.user?.avatarUrl {
                            RemoteImageView(imageURL: avatarUrl)
                        } else {
                            RoundedRectangle(cornerRadius: 0)
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // ユーザー名とロケーション
                HStack(alignment: .center, spacing: 6) {
                    if let displayName = post.user?.displayName, !displayName.isEmpty {
                        Text(displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    Text("@\(post.user?.username ?? "unknown")")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // ロケーション
                if let locationName = post.locationName, !locationName.isEmpty {
                    Text(locationName)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // 時間表示
            Text(formatRelativeTime(post.createdAt))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - 画像セクション
    private var imageSection: some View {
        Group {
            if let _ = URL(string: post.mediaUrl) {
                OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    case .empty:
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 300)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(1.2)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 300)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    )
            }
        }
    }
    
    // MARK: - アクションセクション
    private var actionSection: some View {
        HStack(spacing: 16) {
            // いいねボタン
            Button(action: { onLikeTapped(post) }) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(post.isLikedByMe ? .red : .primary)
                    
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // コメントボタン
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                    
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // シェアボタン
            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - キャプションセクション
    private func captionSection(caption: String) -> some View {
        HStack {
            Text(caption)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.locale = Locale.current
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}