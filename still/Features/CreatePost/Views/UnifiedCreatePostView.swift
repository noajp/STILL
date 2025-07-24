//======================================================================
// MARK: - UnifiedCreatePostView.swift
// Purpose: Unified create post view with swipeable header (Pictures ⇄ Article)
// Path: still/Features/CreatePost/Views/UnifiedCreatePostView.swift
//======================================================================
import SwiftUI

enum CreatePostType: String, CaseIterable {
    case pictures = "Pictures"
    case article = "Article"
}

struct UnifiedCreatePostView: View {
    @State private var currentType: CreatePostType = .pictures
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Header with swipeable titles
                SwipeableHeader(
                    currentType: $currentType,
                    dragOffset: $dragOffset,
                    isDragging: $isDragging,
                    onDismiss: {
                        dismiss()
                    }
                )
                
                // Content based on current type
                TabView(selection: $currentType) {
                    // Pictures View
                    CreatePostView()
                        .tag(CreatePostType.pictures)
                    
                    // Article View
                    ArticleEditorView()
                        .tag(CreatePostType.article)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentType) { _, newValue in
                    // Handle type change if needed
                    print("📝 Post type changed to: \(newValue.rawValue)")
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Swipeable Header
struct SwipeableHeader: View {
    @Binding var currentType: CreatePostType
    @Binding var dragOffset: CGFloat
    @Binding var isDragging: Bool
    let onDismiss: () -> Void
    
    private let headerHeight: CGFloat = 100
    private let titleSpacing: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
            
            HStack {
                // Close Button
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                .padding(.leading, 16)
                
                Spacer()
                
                // Swipeable Titles Container
                GeometryReader { geometry in
                    ZStack {
                        // Pictures Title
                        Text("Pictures")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(currentType == .pictures ? .primary : .secondary)
                            .position(
                                x: geometry.size.width / 2 - titleSpacing + dragOffset,
                                y: geometry.size.height / 2
                            )
                            .opacity(titleOpacity(for: .pictures))
                        
                        // Article Title
                        Text("Article")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(currentType == .article ? .primary : .secondary)
                            .position(
                                x: geometry.size.width / 2 + titleSpacing + dragOffset,
                                y: geometry.size.height / 2
                            )
                            .opacity(titleOpacity(for: .article))
                    }
                }
                .clipped()
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            dragOffset = gesture.translation.width
                        }
                        .onEnded { gesture in
                            isDragging = false
                            
                            // Determine swipe direction and threshold
                            let swipeThreshold: CGFloat = 50
                            let translationX = gesture.translation.width
                            
                            if translationX < -swipeThreshold {
                                // Swipe left: Pictures → Article
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentType = .article
                                    dragOffset = 0
                                }
                            } else if translationX > swipeThreshold {
                                // Swipe right: Article → Pictures
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentType = .pictures
                                    dragOffset = 0
                                }
                            } else {
                                // Snap back to original position
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                
                Spacer()
            }
        }
        .frame(height: headerHeight)
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    private func titleOpacity(for type: CreatePostType) -> Double {
        let baseOpacity: Double = currentType == type ? 1.0 : 0.6
        
        if isDragging {
            // Calculate opacity based on drag offset
            let progress = abs(dragOffset) / titleSpacing
            if type == currentType {
                return max(0.3, baseOpacity - progress)
            } else {
                return min(1.0, baseOpacity + progress)
            }
        }
        
        return baseOpacity
    }
}

// MARK: - Navigation Wrapper
struct UnifiedCreatePostNavigationView: View {
    var body: some View {
        UnifiedCreatePostView()
    }
}

// MARK: - Preview
struct UnifiedCreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        UnifiedCreatePostView()
    }
}