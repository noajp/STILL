//======================================================================
// MARK: - PostCardView.swift
// Purpose: Individual post card component for home feed display
// Path: still/Features/HomeFeed/Views/PostCardView.swift
//======================================================================

import SwiftUI

/**
 * PostCardView displays an individual post in the home feed.
 * 
 * Features:
 * - Optimized image loading with progressive display
 * - User profile interaction (avatar and username tapping)
 * - Like functionality with visual feedback
 * - Comment section access
 * - Location display when available
 * - Caption display with proper formatting
 * - Navigation to user profiles
 * - Sheet presentation for comments
 */
struct PostCardView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var authManager: AuthManager
    @State private var showProfile = false
    @State private var showingComments = false
    @State private var isImageLoaded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Image with optimized loading
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
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .shimmerEffect()
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                        .shimmerEffect()
                @unknown default:
                    Rectangle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1.0, contentMode: .fit)
                }
            }
            .frame(maxWidth: .infinity)
            .clipped()
            .background(MinimalDesign.Colors.background)
            
            // User Header (moved below image) - Only show when image is loaded
            if isImageLoaded {
                HStack(alignment: .top, spacing: 12) {
                // Avatar - タップ可能 (compressed for performance)
                Button(action: {
                    if post.user?.id != authManager.currentUser?.id {
                        showProfile = true
                    }
                }) {
                    if let avatarUrl = post.user?.avatarUrl {
                        CompressedAsyncImage(
                            urlString: avatarUrl,
                            quality: .low
                        ) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: "121212"))
                                .overlay(
                                    Text(post.user?.username.prefix(1).uppercased() ?? "?")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 24, height: 24)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white, lineWidth: 1.5)
                        )
                    } else {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: "121212"))
                            .overlay(
                                Text(post.user?.username.prefix(1).uppercased() ?? "?")
                                    .font(.caption)
                                    .foregroundColor(.white)
                            )
                            .frame(width: 24, height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 1.5)
                            )
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // User Info - タップ可能
                Button(action: {
                    if post.user?.id != authManager.currentUser?.id {
                        showProfile = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.user?.username ?? "unknown")
                            .font(.system(size: 12))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if let location = post.locationName {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Like Button
                Button(action: { onLikeTapped(post) }) {
                    Image(systemName: post.isLikedByMe ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(post.isLikedByMe ? .red : .white)
                }
                
                // Comment Button
                Button(action: { showingComments = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 16, weight: .light))
                            .foregroundColor(.white)
                        
                        if post.commentCount > 0 {
                            Text("\(post.commentCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                
            }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            } else {
                // Placeholder while loading
                HStack(spacing: 12) {
                    // Avatar placeholder
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "1A1A1A"))
                        .frame(width: 24, height: 24)
                        .shimmerEffect()
                    
                    // Username placeholder
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 100, height: 14)
                            .shimmerEffect()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "1A1A1A"))
                            .frame(width: 60, height: 12)
                            .shimmerEffect()
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            
            // Caption - Only show when image is loaded
            if isImageLoaded, let caption = post.caption, !caption.isEmpty {
                HStack {
                    Text(caption)
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            
        }
        .background(Color(hex: "121212"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
        .fullScreenCover(isPresented: $showProfile) {
            if let userId = post.user?.id, userId != authManager.currentUser?.id {
                OtherUserProfileView(userId: userId)
            }
        }
        .sheet(isPresented: $showingComments) {
            CommentListView(post: post)
                .presentationDragIndicator(.visible)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(20)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview Provider

struct PostCardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample post for preview
        let samplePost = Post(
            id: "sample-1",
            userId: "user-1",
            mediaUrl: "https://example.com/image.jpg",
            mediaType: .photo,
            caption: "Sample post caption",
            locationName: "Sample Location",
            createdAt: Date(),
            updatedAt: Date(),
            likeCount: 10,
            commentCount: 5,
            isLikedByMe: false
        )
        
        PostCardView(
            post: samplePost,
            onLikeTapped: { _ in }
        )
        .background(MinimalDesign.Colors.background)
    }
}