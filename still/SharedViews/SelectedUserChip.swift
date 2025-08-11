//======================================================================
// MARK: - SelectedUserChip.swift
// Purpose: Reusable user selection chip component
// Path: still/SharedViews/SelectedUserChip.swift
//======================================================================

import SwiftUI

/**
 * SelectedUserChip displays a selected user as a removable chip.
 * 
 * Features:
 * - User avatar and name display
 * - Remove button with X icon
 * - Compact horizontal layout
 * - Consistent styling across the app
 */
struct SelectedUserChip: View {
    let user: UserProfile
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // User avatar
            Group {
                if let avatarUrl = user.avatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(user.profileDisplayName.prefix(1)).uppercased())
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            
            Text(user.profileDisplayName)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(16)
    }
}

#Preview {
    SelectedUserChip(
        user: UserProfile(
            id: "1",
            username: "testuser",
            displayName: "Test User",
            avatarUrl: nil,
            bio: "This is a test user",
            followersCount: 0,
            followingCount: 0,
            isPrivate: false,
            createdAt: Date(),
            publicKey: nil
        )
    ) {
        print("Remove user")
    }
    .padding()
    .background(MinimalDesign.Colors.background)
}