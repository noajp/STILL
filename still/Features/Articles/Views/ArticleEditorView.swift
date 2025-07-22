//======================================================================
// MARK: - ArticleEditorView.swift
// Purpose: Simple article editor with text and image insertion
// Path: still/Features/Articles/Views/ArticleEditorView.swift
//======================================================================

import SwiftUI
import PhotosUI

// 記事の要素（テキストまたは画像）
struct ArticleElement: Identifiable {
    let id = UUID()
    var type: ElementType
    var content: String
    var imageData: Data?
    
    enum ElementType {
        case text
        case image
    }
}

struct ArticleEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title: String = ""
    @State private var elements: [ArticleElement] = [
        ArticleElement(type: .text, content: "")
    ]
    @State private var showImagePicker = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var isPublishing = false
    @State private var currentEditingIndex: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button("キャンセル") {
                        dismiss()
                    }
                    
                    Spacer()
                    
                    Button("投稿") {
                        publishArticle()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .gray : .blue)
                }
                .padding()
                
                Divider()
                
                // エディター本体
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // タイトル入力
                        TextField("タイトル", text: $title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        // 記事要素（テキストと画像）
                        ForEach(elements.indices, id: \.self) { index in
                            if elements[index].type == .text {
                                // テキスト要素
                                TextEditor(text: $elements[index].content)
                                    .font(.body)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 100)
                                    .onTapGesture {
                                        currentEditingIndex = index
                                    }
                            } else if elements[index].type == .image,
                                      let imageData = elements[index].imageData,
                                      let uiImage = UIImage(data: imageData) {
                                // 画像要素
                                VStack {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .cornerRadius(8)
                                    
                                    // 画像の下に削除ボタン
                                    Button(action: {
                                        elements.remove(at: index)
                                    }) {
                                        Label("削除", systemImage: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.horizontal)
                                .onTapGesture {
                                    currentEditingIndex = index
                                }
                            }
                        }
                        
                        // 最低限の高さを確保
                        Spacer(minLength: 200)
                    }
                    .padding(.vertical)
                }
                
                // 下部ツールバー
                HStack(spacing: 20) {
                    // 画像挿入ボタン
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
            }
            .navigationBarHidden(true)
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImageItem)
        .onChange(of: selectedImageItem) { _, newItem in
            if let newItem = newItem {
                insertImage(from: newItem)
            }
        }
        .overlay(
            Group {
                if isPublishing {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    ProgressView("投稿中...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }
            }
        )
    }
    
    private func insertImage(from item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await MainActor.run {
                    // 現在編集中の位置の次に画像を挿入
                    let insertIndex = min(currentEditingIndex + 1, elements.count)
                    
                    // 画像要素を挿入
                    elements.insert(
                        ArticleElement(type: .image, content: "", imageData: data),
                        at: insertIndex
                    )
                    
                    // 画像の後に新しいテキスト要素を追加
                    elements.insert(
                        ArticleElement(type: .text, content: ""),
                        at: insertIndex + 1
                    )
                    
                    // カーソルを新しいテキスト要素に移動
                    currentEditingIndex = insertIndex + 1
                }
            }
        }
    }
    
    private func publishArticle() {
        isPublishing = true
        
        // 記事の内容を結合（Markdown形式）
        var fullContent = ""
        for element in elements {
            if element.type == .text && !element.content.isEmpty {
                fullContent += element.content + "\n\n"
            } else if element.type == .image, let imageData = element.imageData {
                // 画像は後でURLに変換する必要がある
                // TODO: 画像をSupabase Storageにアップロード
                fullContent += "[IMAGE]\n\n"
            }
        }
        
        // コンテンツを暗号化
        var encryptedTitle: String = ""
        var encryptedContent: String = ""
        do {
            let keyData = try KeychainManager.shared.getUserKey()
            let key = CryptoManager.shared.dataToKey(keyData)
            encryptedTitle = try CryptoManager.shared.encryptToBase64(text: title, using: key)
            encryptedContent = try CryptoManager.shared.encryptToBase64(text: fullContent, using: key)
        } catch KeychainError.keyNotFound {
            // 初回の場合はキーを生成
            let newKey = CryptoManager.shared.generateUserKey()
            let keyData = CryptoManager.shared.keyToData(newKey)
            do {
                try KeychainManager.shared.saveUserKey(keyData)
                encryptedTitle = try CryptoManager.shared.encryptToBase64(text: title, using: newKey)
                encryptedContent = try CryptoManager.shared.encryptToBase64(text: fullContent, using: newKey)
            } catch {
                print("暗号化エラー: \(error)")
                isPublishing = false
                return
            }
        } catch {
            print("暗号化エラー: \(error)")
            isPublishing = false
            return
        }
        
        // TODO: 実際の投稿処理を実装
        // ここでSupabaseに暗号化された記事を保存
        // encryptedTitle と encryptedContent を保存
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isPublishing = false
            
            // 投稿完了通知を送信
            NotificationCenter.default.post(name: NSNotification.Name("ArticleCreated"), object: nil)
            
            dismiss()
        }
    }
}

#Preview {
    ArticleEditorView()
}