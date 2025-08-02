//======================================================================
// MARK: - UserSearchView.swift
// Purpose: User search functionality extracted from MyPageView
// Path: still/Features/MyPage/Views/UserSearchView.swift
//======================================================================
import SwiftUI

/**
 * User search view displaying search interface and results
 * Handles user search by ID with result list display
 */
@MainActor
struct UserSearchView: View {
    // MARK: - Properties
    @EnvironmentObject var authManager: AuthManager
    @State private var searchText: String = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isSearching: Bool = false
    @State private var searchError: String?
    @Binding var isUserSearchMode: Bool
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: MinimalDesign.Spacing.md) {
            // Search field
            searchField
            
            Divider()
                .padding(.horizontal, MinimalDesign.Spacing.md)
            
            // Search results area
            searchResultsArea
        }
    }
    
    // MARK: - Search Field
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16))
            
            TextField("Search by user ID", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onSubmit {
                    searchUsers()
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(25)
        .padding(.horizontal, MinimalDesign.Spacing.md)
    }
    
    // MARK: - Search Results Area
    private var searchResultsArea: some View {
        VStack {
            if searchText.isEmpty && searchResults.isEmpty {
                emptyStateView
            } else if isSearching {
                loadingView
            } else if let error = searchError {
                errorView(error: error)
            } else if searchResults.isEmpty && !searchText.isEmpty {
                noResultsView
            } else {
                searchResultsList
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Search for users")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Enter a user ID to find\nother users")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Searching...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Error")
                .font(.headline)
                .foregroundColor(.secondary)
            Text(error)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 50)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No users found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try a different user ID")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Search Results List
    private var searchResultsList: some View {
        LazyVStack(spacing: 12) {
            ForEach(searchResults, id: \.id) { user in
                if user.id.lowercased() == authManager.currentUser?.id.lowercased() {
                    // Current user - exit search mode
                    Button(action: {
                        isUserSearchMode = false
                        searchText = ""
                        searchResults = []
                    }) {
                        UserSearchResultRow(user: user)
                            .environmentObject(authManager)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    .onAppear {
                        print("🔵 UserSearch - Showing current user: \(user.username) (ID: \(user.id))")
                    }
                } else {
                    // Other users - navigate to profile
                    NavigationLink(destination: OtherUserProfileView(userId: user.id)) {
                        UserSearchResultRow(user: user)
                            .environmentObject(authManager)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, MinimalDesign.Spacing.md)
                    .onAppear {
                        print("🔵 UserSearch - Showing user: \(user.username) (ID: \(user.id))")
                    }
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - Search Function
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        searchError = nil
        
        Task {
            do {
                print("🔍 UserSearch - Searching for: \(searchText)")
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let users = try await UserRepository.shared.searchUsersByUsername(query)
                
                await MainActor.run {
                    self.searchResults = users
                    self.isSearching = false
                    print("✅ UserSearch - Found \(users.count) users")
                }
            } catch {
                print("❌ UserSearch - Search error: \(error)")
                await MainActor.run {
                    self.searchError = "Failed to search users"
                    self.isSearching = false
                }
            }
        }
    }
}

// MARK: - User Search Result Row Component
/**
 * Individual row component for user search results
 * Displays user info with follow/unfollow functionality
 */
struct UserSearchResultRow: View {
    // MARK: - Properties
    let user: UserProfile
    @State private var isFollowing = false
    @State private var requestStatus: FollowRequestStatus?
    @State private var isLoading = false
    @State private var hasCheckedFollowStatus = false
    @EnvironmentObject var authManager: AuthManager
    
    private var isCurrentUser: Bool {
        user.id.lowercased() == authManager.currentUser?.id.lowercased()
    }
    
    private var buttonText: String {
        switch requestStatus {
        case .pending:
            return "Requested"
        case .accepted:
            return "Following"
        case .declined:
            return "Follow"
        case .none:
            return "Follow"
        }
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // Profile image
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.profileDisplayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(user.userIdWithAt)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Follow button (only for other users)
            if !isCurrentUser {
                Button(action: {
                    toggleFollow()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: isFollowing ? .primary : .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(buttonText)
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .foregroundColor(isFollowing ? .primary : .white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFollowing ? Color.clear : MinimalDesign.Colors.accentRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isFollowing ? Color.primary : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .disabled(isLoading)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .onAppear {
            // Reset state for current user to prevent any UI inconsistencies
            if isCurrentUser {
                isFollowing = false
                requestStatus = nil
                hasCheckedFollowStatus = true
            } else if !hasCheckedFollowStatus {
                checkFollowStatus()
            }
        }
    }
    
    // MARK: - Helper Functions
    private func checkFollowStatus() {
        Task { @MainActor in
            do {
                let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                isFollowing = followStatus.isFollowing
                requestStatus = followStatus.requestStatus
                hasCheckedFollowStatus = true
                print("🔵 MyPageUserSearch - Follow status for \(user.username): isFollowing=\(isFollowing), status=\(requestStatus?.rawValue ?? "nil")")
            } catch {
                print("❌ MyPageUserSearch - Error checking follow status: \(error)")
                hasCheckedFollowStatus = true
            }
        }
    }
    
    private func toggleFollow() {
        // Extra safety check - never allow self-follow attempts
        guard !isCurrentUser else {
            print("⚠️ MyPageUserSearch - Attempted self-follow prevented")
            return
        }
        
        isLoading = true
        
        Task { @MainActor in
            do {
                if requestStatus == .accepted {
                    // Unfollow
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                    print("✅ MyPageUserSearch - Unfollowed \(user.username)")
                } else if requestStatus == .pending {
                    // Cancel request
                    try await FollowService.shared.unfollowUser(userId: user.id)
                    requestStatus = nil
                    isFollowing = false
                    print("✅ MyPageUserSearch - Cancelled follow request for \(user.username)")
                } else {
                    // Send new follow request
                    try await FollowService.shared.followUser(userId: user.id)
                    // Refresh status to get correct state
                    let followStatus = try await FollowService.shared.checkFollowStatus(userId: user.id)
                    requestStatus = followStatus.requestStatus
                    isFollowing = followStatus.isFollowing
                    print("✅ MyPageUserSearch - Sent follow request to \(user.username), status: \(requestStatus?.rawValue ?? "nil")")
                }
            } catch {
                print("❌ MyPageUserSearch - Error toggling follow: \(error)")
            }
            isLoading = false
        }
    }
}