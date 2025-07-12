//======================================================================
// MARK: - ModernCreatePostFlow.swift
// Purpose: ModernCreatePostFlow implementation (ModernCreatePostFlowの実装)
// Path: still/Features/CreatePost/Views/ModernCreatePostFlow.swift
//======================================================================
//
//  ModernCreatePostFlow.swift
//  tete
//
//  モダンな投稿フロー（写真選択→編集→投稿）
//

import SwiftUI
import PhotosUI

struct ModernCreatePostFlow: View {
    @StateObject private var viewModel = CreatePostViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoPicker = true
    @State private var showingEditor = false
    @State private var showingPostDetails = false
    @State private var selectedImage: UIImage?
    @State private var editedImage: UIImage?
    
    var body: some View {
        NavigationStack {
            VStack {
                if showingPhotoPicker {
                    // 写真選択画面
                    PhotoSelectView(
                        selectedItem: $selectedPhotoItem,
                        onImageSelected: { image in
                            selectedImage = image
                            showingPhotoPicker = false
                            showingEditor = true
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showingEditor) {
                if let image = selectedImage {
                    ModernPhotoEditorView(
                        image: image,
                        onComplete: { edited in
                            editedImage = edited
                            viewModel.selectedImage = edited
                            showingEditor = false
                            showingPostDetails = true
                        },
                        onCancel: {
                            showingEditor = false
                            showingPhotoPicker = true
                        },
                        onPost: { edited in
                            // 直接投稿処理
                            editedImage = edited
                            viewModel.selectedImage = edited
                            viewModel.createPostInBackground()
                            showingEditor = false
                        },
                        postViewModel: viewModel
                    )
                }
            }
            .sheet(isPresented: $showingPostDetails) {
                PostDetailsView(
                    image: editedImage ?? selectedImage!,
                    viewModel: viewModel,
                    onPost: {
                        viewModel.createPostInBackground()
                        showingPostDetails = false
                    },
                    onBack: {
                        showingPostDetails = false
                        showingEditor = true
                    }
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: .postUploadCompleted)) { _ in
                // 投稿完了後、即座に画面を閉じる
                dismiss()
            }
        }
    }
}


// MARK: - Photo Selection View
struct PhotoSelectView: View {
    @Binding var selectedItem: PhotosPickerItem?
    let onImageSelected: (UIImage) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Select Photo")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // プレースホルダー
                Color.clear.frame(width: 60)
            }
            .padding()
            .background(Color.black)
            
            // 写真選択
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Tap to select a photo")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Choose from your photo library")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let newItem = newItem,
                       let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        onImageSelected(image)
                    }
                }
            }
        }
        .background(Color.black)
    }
}

// MARK: - Post Details View
struct PostDetailsView: View {
    let image: UIImage
    @ObservedObject var viewModel: CreatePostViewModel
    let onPost: () -> Void
    let onBack: () -> Void
    
    @State private var caption = ""
    @State private var location = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case caption, location
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("New Post")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Share", action: onPost)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.canPost ? .blue : .gray)
                        .disabled(!viewModel.canPost || viewModel.isLoading)
                }
                .padding()
                .background(Color(white: 0.1))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 編集済み画像プレビュー
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                            .padding(.horizontal)
                        
                        // キャプション入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            TextEditor(text: $caption)
                                .focused($focusedField, equals: .caption)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(white: 0.15))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                        }
                        
                        // 位置情報入力
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location (Optional)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                            
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.gray)
                                
                                TextField("Add location", text: $location)
                                    .focused($focusedField, equals: .location)
                                    .foregroundColor(.white)
                            }
                            .padding(12)
                            .background(Color(white: 0.15))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
                        
                    }
                    .padding(.vertical)
                }
                .background(Color.black)
                .onTapGesture {
                    focusedField = nil
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .onChange(of: caption) { _, newValue in
            viewModel.caption = newValue
        }
        .onChange(of: location) { _, newValue in
            viewModel.locationName = newValue
        }
    }
}

// MARK: - Preview
#if DEBUG
struct ModernCreatePostFlow_Previews: PreviewProvider {
    static var previews: some View {
        ModernCreatePostFlow()
    }
}
#endif