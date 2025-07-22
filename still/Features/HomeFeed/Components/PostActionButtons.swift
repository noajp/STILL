//======================================================================
// MARK: - PostActionButtons.swift
// Purpose: Unified component for post action buttons (like, comment, save)
// Path: still/Features/HomeFeed/Components/PostActionButtons.swift
//======================================================================
import SwiftUI

struct PostActionButtons: View {
    let post: Post
    let isSaved: Bool
    let onLikeTapped: () -> Void
    let onCommentTapped: () -> Void
    let onSaveTapped: () -> Void
    let onShareTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Like Button
            LikeButton(
                isLiked: post.isLikedByMe,
                likeCount: post.likeCount,
                action: onLikeTapped
            )
            
            // Comment Button
            CommentButton(
                commentCount: post.commentCount ?? 0,
                action: onCommentTapped
            )
            
            // Share Button
            Button(action: onShareTapped) {
                Image(systemName: "paperplane")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.primary)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Save Button
            SaveButton(
                isSaved: isSaved,
                action: onSaveTapped
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview Helper
struct PostActionButtons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example with no interactions
            PostActionButtons(
                post: Post(
                    id: "1",
                    userId: "user1",
                    mediaUrl: "https://example.com/image.jpg",
                    caption: "Sample post",
                    createdAt: Date(),
                    likeCount: 0,
                    commentCount: 0,
                    isLikedByMe: false,
                    user: nil,
                    locationName: nil,
                    locationLatitude: nil,
                    locationLongitude: nil,
                    aspectRatio: nil
                ),
                isSaved: false,
                onLikeTapped: {},
                onCommentTapped: {},
                onSaveTapped: {},
                onShareTapped: {}
            )
            
            // Example with likes and comments
            PostActionButtons(
                post: Post(
                    id: "2",
                    userId: "user2",
                    mediaUrl: "https://example.com/image2.jpg",
                    caption: "Another post",
                    createdAt: Date(),
                    likeCount: 42,
                    commentCount: 15,
                    isLikedByMe: true,
                    user: nil,
                    locationName: nil,
                    locationLatitude: nil,
                    locationLongitude: nil,
                    aspectRatio: nil
                ),
                isSaved: true,
                onLikeTapped: {},
                onCommentTapped: {},
                onSaveTapped: {},
                onShareTapped: {}
            )
        }
        .background(Color(.systemBackground))
    }
}