//======================================================================
// MARK: - StoriesBarView.swift
// Purpose: Horizontal scrollable bar showing user stories at the top of home feed
// Path: still/Features/Stories/Views/StoriesBarView.swift
//======================================================================

import SwiftUI

/**
 * StoriesBarView displays a horizontal scrollable list of user stories.
 * Shows user avatars with colored rings indicating unviewed stories.
 * Tapping an avatar either opens the camera (for current user) or views stories.
 */
struct StoriesBarView: View {
    // MARK: - Properties
    
    /// Story groups to display
    let storyGroups: [StoryGroup]
    
    /// Current user ID for identifying "Add Story" button
    let currentUserId: String?
    
    /// Callback when user taps to add story (opens camera)
    let onAddStory: () -> Void
    
    /// Callback when user taps to view someone's stories
    let onViewStory: (StoryGroup) -> Void
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Add Story button (current user)
                if let userId = currentUserId {
                    AddStoryButton(
                        userProfile: getCurrentUserProfile(),
                        onTap: onAddStory
                    )
                }
                
                // Other users' stories
                ForEach(storyGroups.filter { $0.user.id != currentUserId }) { group in
                    StoryAvatarView(
                        storyGroup: group,
                        onTap: { onViewStory(group) }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(MinimalDesign.Colors.background)
        .frame(height: 100)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentUserProfile() -> UserProfile? {
        // TODO: Get current user profile from AuthManager
        return nil
    }
}

/**
 * AddStoryButton shows the current user's avatar with a plus icon
 */
struct AddStoryButton: View {
    let userProfile: UserProfile?
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottomTrailing) {
                // User avatar or placeholder
                if let avatarUrl = userProfile?.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 64, height: 64)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 64, height: 64)
                }
                
                // Plus icon
                Circle()
                    .fill(MinimalDesign.Colors.accentRed)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 2, y: 2)
            }
            
            Text("Your Story")
                .font(.caption2)
                .foregroundColor(MinimalDesign.Colors.secondary)
                .lineLimit(1)
        }
        .onTapGesture {
            onTap()
        }
    }
}

/**
 * StoryAvatarView shows a user's avatar with a colored ring for unviewed stories
 */
struct StoryAvatarView: View {
    let storyGroup: StoryGroup
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            // Avatar with ring
            ZStack {
                // Colored border for unviewed stories
                if storyGroup.hasUnviewedStories {
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 68, height: 68)
                }
                
                // User avatar
                if let avatarUrl = storyGroup.user.avatarUrl, let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 60, height: 60)
                    }
                } else {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 60)
                }
            }
            
            // Username
            Text(storyGroup.user.username)
                .font(.caption2)
                .foregroundColor(MinimalDesign.Colors.secondary)
                .lineLimit(1)
                .frame(width: 64)
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

struct StoriesBarView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesBarView(
            storyGroups: [],
            currentUserId: "123",
            onAddStory: {},
            onViewStory: { _ in }
        )
        .preferredColorScheme(.dark)
    }
}