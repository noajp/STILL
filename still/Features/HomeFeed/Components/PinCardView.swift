//======================================================================
// MARK: - PinCardView（写真共有アプリ版）
// Path: foodai/Features/HomeFeed/Components/PinCardView.swift
//======================================================================
import SwiftUI

struct PinCardView: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        AsyncImage(url: URL(string: post.mediaUrl)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 250)
                .overlay(
                    ProgressView()
                        .scaleEffect(1.5)
                )
        }
    }
}

