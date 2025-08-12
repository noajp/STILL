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
    @State private var showingComments = false
    @State private var isImageLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 画像部分のみ
            imageSection
            
            // ユーザー情報セクション - Only show when image is loaded
            if isImageLoaded {
                userInfoSection
            } else {
                // Placeholder while loading
                HStack(spacing: 8) {
                    // Avatar placeholder
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: 24, height: 24)
                        .shimmerEffect()
                    
                    // Username placeholders
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 120, height: 16)
                            .shimmerEffect()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 80, height: 14)
                            .shimmerEffect()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color(hex: "121212"))
            }
            
            // アクション部分 - Only show when image is loaded
            if isImageLoaded {
                actionSection
            }
            
            // キャプション - Only show when image is loaded
            if isImageLoaded, let caption = post.caption, !caption.isEmpty {
                captionSection(caption: caption)
            }
        }
        .background(Color(hex: "121212"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .sheet(isPresented: $showingComments) {
            CommentListView(post: post)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(20)
        }
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
                                .fill(Color(hex: "1e1e1e")) // 少し明るくして区別
                        }
                    }
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let user = post.user {
                VStack(alignment: .leading, spacing: 2) {
                    // ユーザー名とロケーション
                    HStack(alignment: .center, spacing: 6) {
                        if let displayName = user.displayName, !displayName.isEmpty {
                            Text(displayName)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(Color(hex: "1e1e1e"))
                                )
                        }
                        
                        Text("@\(user.username)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 0)
                                    .fill(Color(hex: "1e1e1e"))
                            )
                    }
                    
                    // ロケーション
                    if let locationName = post.locationName, !locationName.isEmpty {
                        Text(locationName)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // 時間表示
            Text(formatRelativeTime(post.createdAt))
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - ユーザー情報セクション
    private var userInfoSection: some View {
        ZStack {
            // プレースホルダー背景（常に表示）
            HStack(spacing: 8) {
                // プロフィールアイコン用の正方形背景
                Rectangle()
                    .fill(Color(hex: "121212"))
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    // ユーザー名用の長方形背景
                    Rectangle()
                        .fill(Color(hex: "121212"))
                        .frame(width: 120, height: 16)
                    
                    // ユーザーID用の長方形背景
                    Rectangle()
                        .fill(Color(hex: "121212"))
                        .frame(width: 80, height: 14)
                }
                
                Spacer()
                
                // 時間表示用の背景
                Rectangle()
                    .fill(Color(hex: "121212"))
                    .frame(width: 40, height: 12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            
            // 実際のユーザー情報（データがロードされたら表示）
            if post.user != nil {
                userHeader
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
        }
        .background(Color(hex: "121212"))
    }
    
    // MARK: - 画像セクション
    private var imageSection: some View {
        VStack(spacing: 0) {
            // メイン画像エリア - 常に背景を表示
            ZStack {
                // 常に表示される背景
                Rectangle()
                    .fill(Color(hex: "121212"))
                    .frame(maxWidth: .infinity)
                    .aspectRatio(contentMode: .fit)
                
                // 画像がある場合のみオーバーレイ
                if let _ = URL(string: post.mediaUrl) {
                    OptimizedAsyncImage(urlString: post.mediaUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .onAppear {
                                    isImageLoaded = true
                                }
                        case .failure(_):
                            Rectangle()
                                .fill(Color(hex: "1A1A1A"))
                                .shimmerEffect()
                        case .empty:
                            Rectangle()
                                .fill(Color(hex: "1A1A1A"))
                                .shimmerEffect()
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // URLがない場合はプレースホルダーを表示
                    Rectangle()
                        .fill(Color(hex: "1A1A1A"))
                        .shimmerEffect()
                }
            }
            .background(Color(hex: "121212"))
        }
    }
    
    // MARK: - アクションセクション
    private var actionSection: some View {
        HStack(spacing: 12) {
            // いいねボタン
            Button(action: { onLikeTapped(post) }) {
                HStack(spacing: 4) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 14))
                        .foregroundColor(post.isLikedByMe ? .red : .white)
                    
                    if post.likeCount > 0 {
                        Text("\(post.likeCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // コメントボタン
            Button(action: { showingComments = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    if post.commentCount > 0 {
                        Text("\(post.commentCount)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // シェアボタン
            Button(action: {}) {
                Image(systemName: "paperplane")
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
    
    // MARK: - キャプションセクション
    private func captionSection(caption: String) -> some View {
        HStack {
            Text(caption)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 12)
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