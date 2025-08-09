//======================================================================
// MARK: - CommentListView.swift
// Purpose: View for displaying and managing comments on a post
// Path: still/Features/Comments/Views/CommentListView.swift
//======================================================================

import SwiftUI

/**
 * CommentListView displays comments for a specific post with creation and management functionality.
 * 
 * This view provides a full-screen interface for viewing, creating, and managing comments
 * on a post, with real-time updates and proper user interactions.
 */
struct CommentListView: View {
    
    // MARK: - Properties
    
    let post: Post
    @StateObject private var viewModel: CommentViewModel
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var newCommentText = ""
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Initialization
    
    init(post: Post) {
        self.post = post
        self._viewModel = StateObject(wrappedValue: CommentViewModel(postId: post.id))
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            headerView
            
            // Comments List
            commentsListView
            
            // Comment Input with keyboard handling
            commentInputView
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 0)
                }
        }
        .background(Color(hex: "121212"))
        .alert("Error", isPresented: $viewModel.hasError) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onAppear {
            Task {
                await viewModel.loadComments()
            }
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        isTextFieldFocused = false
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(MinimalDesign.Colors.accentRed)
                }
            }
        }
    }
    
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Comments")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.1)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(hex: "121212"))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    // MARK: - Comments List View
    
    private var commentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.comments.isEmpty {
                    emptyStateView
                } else {
                    ForEach(viewModel.comments) { comment in
                        CommentRowView(
                            comment: comment,
                            onDelete: {
                                Task {
                                    await viewModel.deleteComment(comment.id)
                                }
                            },
                            onEdit: { newContent in
                                Task {
                                    await viewModel.updateComment(comment.id, content: newContent)
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.white)
            
            Text("Loading comments...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No comments yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
            
            Text("Be the first to leave a comment")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 50)
    }
    
    // MARK: - Comment Input View
    
    private var commentInputView: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            HStack(spacing: 12) {
                // User Avatar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(hex: "1e1e1e"))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(authManager.currentUser?.email?.prefix(1).uppercased() ?? "?")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    )
                
                // Text Input
                HStack {
                    TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...5)
                    
                    if !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Button(action: postComment) {
                            if viewModel.isSubmitting {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(MinimalDesign.Colors.accentRed)
                            }
                        }
                        .disabled(viewModel.isSubmitting)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(hex: "1e1e1e"))
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "121212"))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    // MARK: - Actions
    
    private func postComment() {
        let content = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        print("📝 CommentListView: Attempting to post comment")
        
        Task {
            await viewModel.createComment(content: content)
            if !viewModel.hasError {
                print("✅ CommentListView: Comment posted successfully")
                newCommentText = ""
                isTextFieldFocused = false
            } else {
                print("❌ CommentListView: Failed to post comment: \(viewModel.errorMessage)")
            }
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    let onDelete: () -> Void
    let onEdit: (String) -> Void
    
    @EnvironmentObject var authManager: AuthManager
    @State private var showingActionSheet = false
    @State private var showingEditDialog = false
    @State private var editText = ""
    @State private var showingProfile = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            Button(action: { showingProfile = true }) {
                if let avatarUrl = comment.authorAvatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "1e1e1e"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Text(comment.authorUsername.prefix(1).uppercased())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Comment Content
            VStack(alignment: .leading, spacing: 4) {
                // Username and Time
                HStack(alignment: .center, spacing: 8) {
                    Button(action: { showingProfile = true }) {
                        Text(comment.authorDisplayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(comment.timeAgoString)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if comment.isEdited {
                        Text("edited")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    // Actions button (only for own comments)
                    if comment.userId == authManager.currentUser?.id {
                        Button(action: { showingActionSheet = true }) {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                // Comment Text
                Text(comment.content)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Comment Actions"),
                buttons: [
                    .default(Text("Edit")) {
                        editText = comment.content
                        showingEditDialog = true
                    },
                    .destructive(Text("Delete")) {
                        onDelete()
                    },
                    .cancel()
                ]
            )
        }
        .alert("Edit Comment", isPresented: $showingEditDialog) {
            TextField("Comment", text: $editText)
            Button("Save") {
                onEdit(editText)
            }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: $showingProfile) {
            if let userId = comment.user?.id, userId != authManager.currentUser?.id {
                OtherUserProfileView(userId: userId)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    CommentListView(post: Post(
        id: "preview",
        userId: "user1",
        mediaUrl: "https://example.com/image.jpg",
        mediaType: .photo,
        caption: "Preview post",
        locationName: nil,
        createdAt: Date(),
        likeCount: 0,
        commentCount: 0,
        user: nil
    ))
    .environmentObject(AuthManager.shared)
}