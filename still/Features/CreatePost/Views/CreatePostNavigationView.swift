//======================================================================
// MARK: - CreatePostNavigationView.swift
// Purpose: SwiftUI view component (CreatePostNavigationViewビューコンポーネント)
// Path: still/Features/CreatePost/Views/CreatePostNavigationView.swift
//======================================================================
//
//  CreatePostNavigationView.swift
//  tete
//
//  投稿作成のナビゲーション管理
//

import SwiftUI

struct CreatePostNavigationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var navigationPath = NavigationPath()
    @State private var selectedEditorData: PhotoEditorData?
    @StateObject private var viewModel = CreatePostViewModel()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            PhotoPickerView { editorData in
                print("🟢 CreatePostNavigationViewで画像受信")
                selectedEditorData = editorData
                navigationPath.append(editorData)
            }
            .navigationDestination(for: PhotoEditorData.self) { editorData in
                ModernPhotoEditorView(
                    editorData: editorData,
                    onComplete: { editedImage in
                        // 編集完了後の処理
                        viewModel.selectedImage = editedImage
                        navigationPath.removeLast()
                    },
                    onCancel: {
                        navigationPath.removeLast()
                    },
                    onPost: { editedImage in
                        print("🟢 onPost called in CreatePostNavigationView")
                        viewModel.selectedImage = editedImage
                        Task {
                            // Start background upload
                            viewModel.createPostInBackground()
                            // Close navigation and return to main feed
                            dismiss()
                        }
                    },
                    postViewModel: viewModel
                )
                .navigationBarHidden(true)
            }
        }
    }
}