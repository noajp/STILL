//======================================================================
// MARK: - SaveButton.swift
// Purpose: Save/bookmark button component with animation
// Path: still/Features/HomeFeed/Components/SaveButton.swift
//======================================================================
import SwiftUI

struct SaveButton: View {
    let isSaved: Bool
    let action: () -> Void
    @State private var animateBookmark = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animateBookmark = true
            }
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateBookmark = false
            }
        }) {
            Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(isSaved ? .primary : .primary)
                .scaleEffect(animateBookmark ? 1.2 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SaveButton_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 40) {
            SaveButton(isSaved: false, action: {})
            SaveButton(isSaved: true, action: {})
        }
        .padding()
    }
}