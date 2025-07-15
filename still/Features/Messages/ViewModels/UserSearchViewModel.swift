//======================================================================
// MARK: - UserSearchViewModel.swift
// Path: foodai/Features/Messages/ViewModels/UserSearchViewModel.swift
//======================================================================
import Foundation
import SwiftUI

@MainActor
class UserSearchViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    func searchUsers(query: String) async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            users = []
            return
        }
        
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            
            let users: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .neq("id", value: currentUserId) // Exclude current user
                .or("username.ilike.*\(searchQuery)*,display_name.ilike.*\(searchQuery)*")
                .limit(20)
                .execute()
                .value
            
            self.users = users
        } catch {
            errorMessage = "Failed to search users: \(error.localizedDescription)"
            print("❌ Error searching users: \(error)")
        }
        
        isLoading = false
    }
    
    func getAllUsers() async {
        // Get all users except current user for testing
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let users: [UserProfile] = try await supabase
                .from("profiles")
                .select("*")
                .neq("id", value: currentUserId)
                .limit(10)
                .execute()
                .value
            
            self.users = users
            print("✅ Found \(users.count) users: \(users.map { $0.username })")
        } catch {
            errorMessage = "Failed to get users: \(error.localizedDescription)"
            print("❌ Error getting users: \(error)")
        }
        
        isLoading = false
    }
    
    func getTestUsers() async {
        // For backward compatibility, just call getAllUsers
        await getAllUsers()
    }
}