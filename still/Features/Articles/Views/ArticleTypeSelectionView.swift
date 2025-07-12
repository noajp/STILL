//======================================================================
// MARK: - ArticleTypeSelectionView.swift
// Purpose: SwiftUI view component (ArticleTypeSelectionViewビューコンポーネント)
// Path: still/Features/Articles/Views/ArticleTypeSelectionView.swift
//======================================================================
//
//  ArticleTypeSelectionView.swift
//  tete
//
//  記事タイプ選択画面（新聞記事 vs 雑誌記事）
//

import SwiftUI

struct ArticleTypeSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedType: ArticleType? = nil
    @State private var showingEditor = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景グラデーション
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.1),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // ヘッダー
                        VStack(spacing: 16) {
                            Text("記事スタイルを選択")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                            
                            Text("どのようなスタイルの記事を書きますか？")
                                .font(.system(size: 18))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // 記事タイプ選択
                        VStack(spacing: 24) {
                            // 新聞記事オプション
                            ArticleTypeCard(
                                type: .newspaper,
                                isSelected: selectedType == .newspaper,
                                title: "新聞記事",
                                subtitle: "ニュース・報道・情報記事",
                                description: "事実に基づいた情報を分かりやすく伝える記事形式。ニュース、レポート、解説記事などに適しています。",
                                icon: "newspaper",
                                color: .blue,
                                features: [
                                    "シンプルで読みやすいレイアウト",
                                    "事実重視の構成",
                                    "情報の整理に最適"
                                ]
                            ) {
                                selectedType = .newspaper
                            }
                            
                            // 雑誌記事オプション
                            ArticleTypeCard(
                                type: .magazine,
                                isSelected: selectedType == .magazine,
                                title: "雑誌記事",
                                subtitle: "ライフスタイル・特集・エンターテイメント",
                                description: "スタイリッシュで魅力的なビジュアルと共に、読者の興味を引くストーリーを伝える記事形式。",
                                icon: "magazine",
                                color: .purple,
                                features: [
                                    "美しいビジュアルデザイン",
                                    "ストーリー性重視",
                                    "読者との感情的なつながり"
                                ]
                            ) {
                                selectedType = .magazine
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 作成ボタン
                        if selectedType != nil {
                            Button(action: {
                                showingEditor = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    
                                    Text("記事を作成する")
                                        .font(.system(size: 18, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: selectedType == .newspaper ? 
                                            [.blue, .blue.opacity(0.8)] :
                                            [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            .padding(.horizontal, 20)
                            .transition(.slide.combined(with: .opacity))
                        }
                        
                        Color.clear.frame(height: 50)
                    }
                }
            }
            .navigationTitle("新しい記事")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            })
        }
        .fullScreenCover(isPresented: $showingEditor) {
            if selectedType == .newspaper {
                NewspaperEditorView()
            } else {
                MagazineEditorView()
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedType)
    }
}

struct ArticleTypeCard: View {
    let type: ArticleType
    let isSelected: Bool
    let title: String
    let subtitle: String
    let description: String
    let icon: String
    let color: Color
    let features: [String]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー部分
                HStack(spacing: 16) {
                    // アイコン
                    Image(systemName: icon)
                        .font(.system(size: 40))
                        .foregroundColor(isSelected ? .white : color)
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill(isSelected ? color : color.opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(isSelected ? .white : .primary)
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                    
                    Spacer()
                    
                    // 選択インジケーター
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelected ? .white : color.opacity(0.5))
                }
                
                // 説明文
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                
                // 特徴リスト
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 12) {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(isSelected ? .white : color)
                            
                            Text(feature)
                                .font(.system(size: 14))
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        isSelected ? 
                            LinearGradient(colors: [color, color.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [.white, .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.3) : .black.opacity(0.1),
                        radius: isSelected ? 20 : 8,
                        x: 0,
                        y: isSelected ? 8 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? Color.clear : color.opacity(0.2),
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ArticleTypeSelectionView()
}