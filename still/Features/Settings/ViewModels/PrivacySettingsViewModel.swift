//======================================================================
// MARK: - PrivacySettingsViewModel.swift
// Purpose: ViewModel for privacy settings including private account management and follow request handling (プライベートアカウント管理とフォローリクエスト処理を含むプライバシー設定のためのViewModel)
// Path: still/Features/Settings/ViewModels/PrivacySettingsViewModel.swift
//======================================================================

import Foundation
import Supabase

/// Represents a follow request between users
/// Contains the relationship data and optional profile information for the follower
struct FollowRequest: Identifiable, Codable {
    /// Unique identifier for the follow request
    let id: String
    /// ID of the user who sent the follow request
    let follower_id: String
    /// ID of the user who received the follow request
    let following_id: String
    /// Status of the request (pending, accepted, rejected)
    let status: String
    /// When the follow request was created
    let created_at: Date
    
    /// Profile information of the user who sent the follow request
    var followerProfile: UserProfile?
}

/// ViewModel for managing privacy settings and follow request handling
/// Handles private account toggle and automatic follow request management
@MainActor
class PrivacySettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the current user's account is private
    @Published var isPrivateAccount: Bool = false
    
    /// Loading state indicator
    @Published var isLoading: Bool = false
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// ID of the current user whose privacy settings are being managed
    private var currentUserId: String?
    
    // MARK: - Public Methods
    
    /// Loads the current privacy settings for the specified user
    /// - Parameter userId: ID of the user whose privacy settings to load
    func loadPrivacySettings(for userId: String) async {
        currentUserId = userId
        isLoading = true
        
        do {
            // Structure for decoding privacy setting from database
            struct PrivacyResult: Codable {
                let isPrivate: Bool?
                
                enum CodingKeys: String, CodingKey {
                    case isPrivate = "is_private"
                }
            }
            
            // Fetch current privacy setting from database
            let result: PrivacyResult = try await SupabaseManager.shared.client
                .from("profiles")
                .select("is_private")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            isPrivateAccount = result.isPrivate ?? false
            print("✅ Privacy setting loaded: \(isPrivateAccount)")
            
        } catch {
            print("❌ Error loading privacy settings: \(error)")
            errorMessage = "Failed to load privacy settings"
        }
        
        isLoading = false
    }
    
    /// Updates the privacy setting for the current user
    /// If changing from private to public, automatically accepts all pending follow requests
    func updatePrivacySetting() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                // Update privacy setting in database
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["is_private": isPrivateAccount])
                    .eq("id", value: userId)
                    .execute()
                
                print("✅ Privacy setting updated: \(isPrivateAccount ? "Private" : "Public")")
                
                // If switching to public account, automatically accept all pending requests
                if !isPrivateAccount {
                    await acceptAllPendingRequests()
                }
                
            } catch {
                print("❌ Error updating privacy setting: \(error)")
                errorMessage = "Failed to update privacy setting"
                // Revert the UI state if database update failed
                isPrivateAccount.toggle()
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    /// Accepts all pending follow requests for the current user
    /// Called automatically when user switches from private to public account
    private func acceptAllPendingRequests() async {
        guard let userId = currentUserId else { return }
        
        do {
            // Update all pending follow requests to accepted status
            try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("following_id", value: userId)
                .eq("status", value: "pending")
                .execute()
            
            print("✅ All pending follow requests accepted")
            
        } catch {
            print("❌ Error accepting pending requests: \(error)")
        }
    }

}