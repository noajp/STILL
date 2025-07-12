//======================================================================
// MARK: - ArticleEditorView.swift
// Purpose: SwiftUI view component (ArticleEditorViewビューコンポーネント)
// Path: still/Features/Article/Views/ArticleEditorView.swift
//======================================================================
//
//  ArticleEditorView.swift
//  tete
//
//  Note-style article editor with clean UI/UX
//

import SwiftUI
import Combine

struct ArticleEditorView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ArticleEditorViewModel()
    @State private var showingPublishSettings = false
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main editor canvas
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Title editor
                        titleEditor
                        
                        // Content editor
                        contentEditor
                        
                        // Bottom padding for comfortable writing
                        Color.clear.frame(height: 200)
                    }
                    .padding(.horizontal, 24)
                }
            }
            
            // Floating toolbar (appears when text is selected)
            if viewModel.showFloatingToolbar {
                floatingToolbar
            }
            
            // Auto-save indicator
            autoSaveIndicator
        }
        .onAppear {
            isTextEditorFocused = true
        }
        .fullScreenCover(isPresented: $showingPublishSettings) {
            ArticlePublishSettingsView(article: viewModel.article)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button("Back") {
                dismiss()
            }
            .font(.system(size: 16))
            .foregroundColor(.gray)
            
            Spacer()
            
            Button("Publish") {
                showingPublishSettings = true
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.black)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    // MARK: - Title Editor
    
    private var titleEditor: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $viewModel.article.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.vertical, 24)
            
            // Subtle divider
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .frame(height: 1)
                .padding(.bottom, 32)
        }
    }
    
    // MARK: - Content Editor
    
    private var contentEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(viewModel.article.blocks.enumerated()), id: \.offset) { index, block in
                ArticleBlockView(
                    block: $viewModel.article.blocks[index],
                    isActive: viewModel.activeBlockIndex == index,
                    onActivate: { 
                        viewModel.activeBlockIndex = index 
                        viewModel.handleTextSelection(hasSelection: false)
                    },
                    onDelete: { viewModel.deleteBlock(at: index) },
                    onAddBlock: { type in viewModel.addBlock(type: type, after: index) },
                    onTextSelection: { hasSelection in
                        viewModel.handleTextSelection(hasSelection: hasSelection)
                    }
                )
                .padding(.bottom, 8)
            }
            
            // Add new block button at the end
            addBlockButton
        }
    }
    
    private var addBlockButton: some View {
        HStack {
            Button(action: {
                viewModel.addBlock(type: .text, after: viewModel.article.blocks.count - 1)
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text("Add block")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Floating Toolbar
    
    private var floatingToolbar: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 0) {
                toolbarButton("bold", action: { viewModel.toggleBold() })
                toolbarDivider
                toolbarButton("italic", action: { viewModel.toggleItalic() })
                toolbarDivider
                toolbarButton("quote.opening", action: { viewModel.toggleQuote() })
                toolbarDivider
                toolbarButton("link", action: { viewModel.insertLink() })
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black)
                    .shadow(radius: 8, y: 4)
            )
            .padding(.horizontal, 50)
            .padding(.bottom, 100)
        }
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.2), value: viewModel.showFloatingToolbar)
    }
    
    private func toolbarButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
    }
    
    private var toolbarDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 1, height: 24)
    }
    
    // MARK: - Auto-save Indicator
    
    private var autoSaveIndicator: some View {
        VStack {
            HStack {
                Spacer()
                
                if viewModel.isSaving {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Saving...")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                } else if viewModel.lastSavedAt != nil {
                    Text("Saved")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}

// MARK: - Article Block View

struct ArticleBlockView: View {
    @Binding var block: ArticleBlock
    let isActive: Bool
    let onActivate: () -> Void
    let onDelete: () -> Void
    let onAddBlock: (ArticleBlockType) -> Void
    let onTextSelection: (Bool) -> Void
    
    @State private var showingAddMenu = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Add button (appears on new lines)
            if block.content.isEmpty || block.content.hasSuffix("\n") {
                Button(action: {
                    showingAddMenu = true
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.gray.opacity(0.6))
                }
                .opacity(isActive ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: isActive)
            } else {
                Color.clear.frame(width: 20, height: 20)
            }
            
            // Block content
            blockContent
        }
        .onTapGesture {
            onActivate()
            isFocused = true
        }
        .actionSheet(isPresented: $showingAddMenu) {
            ActionSheet(
                title: Text("Add Block"),
                buttons: [
                    .default(Text("Text")) { onAddBlock(.text) },
                    .default(Text("Heading")) { onAddBlock(.heading) },
                    .default(Text("Image")) { onAddBlock(.image) },
                    .default(Text("Quote")) { onAddBlock(.quote) },
                    .cancel()
                ]
            )
        }
    }
    
    @ViewBuilder
    private var blockContent: some View {
        switch block.type {
        case .text:
            TextField("Type here...", text: $block.content, axis: .vertical)
                .font(.system(size: 18, weight: .regular))
                .lineSpacing(6)
                .foregroundColor(.black)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onChange(of: isFocused) { _, newValue in
                    if newValue {
                        onActivate()
                    }
                }
            
        case .heading:
            TextField("Heading", text: $block.content, axis: .vertical)
                .font(.system(size: 28, weight: .bold))
                .lineSpacing(4)
                .foregroundColor(.black)
                .textFieldStyle(PlainTextFieldStyle())
                .focused($isFocused)
                .onChange(of: isFocused) { _, newValue in
                    if newValue {
                        onActivate()
                    }
                }
            
        case .quote:
            HStack(alignment: .top, spacing: 12) {
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 4)
                
                TextField("Quote text", text: $block.content, axis: .vertical)
                    .font(.system(size: 18, weight: .regular))
                    .italic()
                    .lineSpacing(6)
                    .foregroundColor(.gray)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)
                    .onChange(of: isFocused) { _, newValue in
                        if newValue {
                            onActivate()
                        }
                    }
            }
            .padding(.leading, 16)
            
        case .image:
            VStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(.gray)
                            Text("Add image")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                    )
                    .onTapGesture {
                        // Image picker functionality
                    }
            }
        }
    }
}

#if DEBUG
struct ArticleEditorView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleEditorView()
    }
}
#endif