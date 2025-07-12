//======================================================================
// MARK: - ArticleEditorViewModel.swift
// Purpose: View model for data and business logic (ArticleEditorViewModelのデータとビジネスロジック)
// Path: still/Features/Article/ViewModels/ArticleEditorViewModel.swift
//======================================================================
//
//  ArticleEditorViewModel.swift
//  tete
//
//  ViewModel for note-style article editor
//

import SwiftUI
import Combine

@MainActor
class ArticleEditorViewModel: ObservableObject {
    @Published var article = Article()
    @Published var activeBlockIndex: Int = 0
    @Published var showFloatingToolbar = false
    @Published var isSaving = false
    @Published var lastSavedAt: Date?
    
    private var autoSaveTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Initialize with a default text block
        article.blocks = [ArticleBlock(type: .text, content: "")]
        
        // Setup auto-save
        setupAutoSave()
    }
    
    // MARK: - Auto Save
    
    private func setupAutoSave() {
        // Auto-save every 10 seconds when content changes
        $article
            .debounce(for: .seconds(10), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.autoSave()
                }
            }
            .store(in: &cancellables)
    }
    
    private func autoSave() async {
        guard !article.title.isEmpty || !article.blocks.allSatisfy({ $0.content.isEmpty }) else {
            return
        }
        
        isSaving = true
        
        // Simulate save operation
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        isSaving = false
        lastSavedAt = Date()
    }
    
    // MARK: - Block Management
    
    func addBlock(type: ArticleBlockType, after index: Int) {
        let newBlock = ArticleBlock(type: type, content: "")
        article.blocks.insert(newBlock, at: index + 1)
        activeBlockIndex = index + 1
    }
    
    func deleteBlock(at index: Int) {
        guard article.blocks.count > 1 else { return }
        article.blocks.remove(at: index)
        activeBlockIndex = max(0, index - 1)
    }
    
    // MARK: - Text Formatting
    
    func toggleBold() {
        // Implement bold formatting
        showFloatingToolbar = false
    }
    
    func toggleItalic() {
        // Implement italic formatting
        showFloatingToolbar = false
    }
    
    func toggleQuote() {
        // Convert current block to quote
        if activeBlockIndex < article.blocks.count {
            article.blocks[activeBlockIndex].type = .quote
        }
        showFloatingToolbar = false
    }
    
    func insertLink() {
        // Implement link insertion
        showFloatingToolbar = false
    }
    
    // MARK: - Selection Handling
    
    func handleTextSelection(hasSelection: Bool) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showFloatingToolbar = hasSelection
        }
    }
}

// MARK: - Data Models

struct Article: Codable {
    var id = UUID()
    var title: String = ""
    var blocks: [ArticleBlock] = []
    var createdAt = Date()
    var updatedAt = Date()
    var isPublished = false
    var tags: [String] = []
    var category: String = ""
}

struct ArticleBlock: Codable, Identifiable {
    var id = UUID()
    var type: ArticleBlockType
    var content: String
    var metadata: [String: String] = [:] // For images, links, etc.
}

enum ArticleBlockType: String, Codable, CaseIterable {
    case text = "text"
    case heading = "heading"
    case quote = "quote"
    case image = "image"
    
    var displayName: String {
        switch self {
        case .text: return "Text"
        case .heading: return "Heading"
        case .quote: return "Quote"
        case .image: return "Image"
        }
    }
}