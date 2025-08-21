//======================================================================
// MARK: - PostCompositionView.swift
// Purpose: Post composition screen for adding captions and hashtags to photos (写真にキャプションとハッシュタグを追加する投稿作成画面)
// Path: still/Features/Posts/Views/PostCompositionView.swift
//======================================================================

import SwiftUI

struct PostCompositionView: View {
    let editedImage: UIImage
    let onPostCreated: () -> Void
    let onCancel: () -> Void
    
    @State private var caption = ""
    @State private var hashtags = ""
    @State private var isPosting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: FocusedField?
    @Environment(\.dismiss) private var dismiss
    
    enum FocusedField {
        case caption
        case hashtags
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                MinimalDesign.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Image preview
                        Image(uiImage: editedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .clipped()
                        
                        // Caption input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Caption")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("Share your thoughts...", text: $caption, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .caption)
                                .lineLimit(3...6)
                        }
                        
                        // Hashtags input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hashtags")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("#nature #photography #still", text: $hashtags)
                                .textFieldStyle(CustomTextFieldStyle())
                                .focused($focusedField, equals: .hashtags)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        
                        // Post button
                        Button(action: {
                            Task {
                                await createPost()
                            }
                        }) {
                            HStack {
                                if isPosting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isPosting ? "Posting..." : "Post")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(MinimalDesign.Colors.accentRed)
                            .cornerRadius(12)
                        }
                        .disabled(isPosting || caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity((isPosting || caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            await createPost()
                        }
                    }
                    .foregroundColor(MinimalDesign.Colors.accentRed)
                    .fontWeight(.semibold)
                    .disabled(isPosting)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createPost() async {
        guard !isPosting else { return }
        
        isPosting = true
        focusedField = nil // Dismiss keyboard
        
        // Simulate post creation
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        print("✅ Post created with caption: \(caption)")
        print("✅ Hashtags: \(hashtags)")
        
        isPosting = false
        onPostCreated()
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}