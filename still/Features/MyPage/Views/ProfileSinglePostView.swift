//======================================================================
// MARK: - ProfileSinglePostView.swift
// Purpose: Profile-specific single post view with scroll navigation (スクロールナビゲーション付きプロフィール専用シングル投稿ビュー)
// Path: still/Features/MyPage/Views/ProfileSinglePostView.swift
//======================================================================
import SwiftUI

@MainActor
struct ProfileSinglePostView: View {
    let initialPost: Post
    let allPosts: [Post]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    
    private var reorderedPosts: [Post] {
        // 選択された投稿を最初に表示し、残りを順序で表示
        guard let selectedIndex = allPosts.firstIndex(where: { $0.id == initialPost.id }) else {
            return allPosts
        }
        
        var posts = [Post]()
        
        // 選択された投稿を最初に追加
        posts.append(allPosts[selectedIndex])
        
        // 選択された投稿より後の投稿を追加
        for i in (selectedIndex + 1)..<allPosts.count {
            posts.append(allPosts[i])
        }
        
        // 選択された投稿より前の投稿を追加
        for i in 0..<selectedIndex {
            posts.append(allPosts[i])
        }
        
        return posts
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // 並び替えられた投稿を表示（選択された投稿が最初）
                ForEach(Array(reorderedPosts.enumerated()), id: \.element.id) { index, post in
                    SingleCardView(post: post) { post in
                        // プロフィールページなのでlike機能は無効
                    }
                    .onAppear {
                        currentIndex = index
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            currentIndex = 0 // 選択された投稿が最初なので0
        }
    }
}