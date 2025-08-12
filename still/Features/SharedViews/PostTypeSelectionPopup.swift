//======================================================================
// MARK: - PostTypeSelectionPopup.swift
// Purpose: Post type selection popup for choosing between photo and article posts (写真投稿と記事投稿を選択するための投稿タイプ選択ポップアップ)
// Path: still/Features/SharedViews/PostTypeSelectionPopup.swift
//======================================================================
import SwiftUI

struct PostTypeSelectionPopup: View {
    @Binding var isPresented: Bool
    let onPictureSelected: () -> Void

    // Color scheme now handled by MinimalDesign
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景タップで閉じる
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    }
                
                // ポップアップをタブバーの真上に配置
                VStack {
                    Spacer()
                    
                    // ポップアップコンテンツ
                    VStack(spacing: 0) {
                // ヘッダー
                Text("Post")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.primary)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
                
                // ボタンコンテナ
                HStack(spacing: 40) {
                    // 写真投稿ボタン

                }
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
                    }
                    .background(MinimalDesign.Colors.background)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 8)
                    .frame(maxWidth: 280)
                    
                    // タブバーの高さ分の余白（タブバー: 8pt上パディング + 36pt ボタン + 8pt下パディング + 30pt底部パディング = 82pt）
                    Color.clear.frame(height: 82)
                }
                .scaleEffect(isPresented ? 1.0 : 0.8)
                .opacity(isPresented ? 1.0 : 0)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                animationProgress = 1
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
struct PostTypeSelectionPopup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.opacity(0.2)
                .ignoresSafeArea()
            
            PostTypeSelectionPopup(
                isPresented: .constant(true),
                onPictureSelected: {},

            )
        }
    }
}
#endif