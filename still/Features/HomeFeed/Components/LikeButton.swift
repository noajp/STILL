//======================================================================
// MARK: - LikeButton.swift
// Purpose: Like button component with animation
// Path: still/Features/HomeFeed/Components/LikeButton.swift
//======================================================================
import SwiftUI

struct LikeButton: View {
    let isLiked: Bool
    let likeCount: Int
    let action: () -> Void
    @State private var animateHeart = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateHeart = true
            }
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateHeart = false
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isLiked ? .red : .primary)
                    .scaleEffect(animateHeart ? 1.2 : 1.0)
                
                if likeCount > 0 {
                    Text("\(likeCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LikeButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            LikeButton(isLiked: false, likeCount: 0, action: {})
            LikeButton(isLiked: true, likeCount: 42, action: {})
        }
        .padding()
    }
}