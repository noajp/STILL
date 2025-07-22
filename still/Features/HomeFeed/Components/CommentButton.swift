//======================================================================
// MARK: - CommentButton.swift
// Purpose: Comment button component
// Path: still/Features/HomeFeed/Components/CommentButton.swift
//======================================================================
import SwiftUI

struct CommentButton: View {
    let commentCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "message")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.primary)
                
                if commentCount > 0 {
                    Text("\(commentCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CommentButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            CommentButton(commentCount: 0, action: {})
            CommentButton(commentCount: 15, action: {})
        }
        .padding()
    }
}