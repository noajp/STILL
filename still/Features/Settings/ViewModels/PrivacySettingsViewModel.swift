//======================================================================
// MARK: - PrivacySettingsViewModel.swift
// Purpose: ViewModel for privacy settings including private account management and follow request handling (プライベートアカウント管理とフォローリクエスト処理を含むプライバシー設定のためのViewModel)
// Path: still/Features/Settings/ViewModels/PrivacySettingsViewModel.swift
//======================================================================

import Foundation
import Supabase

struct FollowRequest: Identifiable, Codable {
    let id: String
    let follower_id: String
    let following_id: String
    let status: String
    let created_at: Date
    
    // フォロワーのプロフィール情報
    var followerProfile: UserProfile?
}

@MainActor
class PrivacySettingsViewModel: ObservableObject {
    @Published var isPrivateAccount: Bool = false
    @Published var pendingRequestsCount: Int = 0
    @Published var pendingRequests: [FollowRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var currentUserId: String?
    
    func loadPrivacySettings(for userId: String) async {
        currentUserId = userId
        isLoading = true
        
        do {
            // Load current privacy setting using direct JSON query
            struct PrivacyResult: Codable {
                let isPrivate: Bool?
                
                enum CodingKeys: String, CodingKey {
                    case isPrivate = "is_private"
                }
            }
            
            let result: PrivacyResult = try await SupabaseManager.shared.client
                .from("profiles")
                .select("is_private")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            isPrivateAccount = result.isPrivate ?? false
            print("✅ Privacy setting loaded: \(isPrivateAccount)")
            
            // Load pending requests count if private
            if isPrivateAccount {
                await loadPendingRequestsCount()
                await loadPendingRequests()
            }
            
        } catch {
            print("❌ Error loading privacy settings: \(error)")
            errorMessage = "Failed to load privacy settings"
        }
        
        isLoading = false
    }
    
    func updatePrivacySetting() {
        guard let userId = currentUserId else { return }
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("profiles")
                    .update(["is_private": isPrivateAccount])
                    .eq("id", value: userId)
                    .execute()
                
                print("✅ Privacy setting updated: \(isPrivateAccount ? "Private" : "Public")")
                
                // Load pending requests if now private
                if isPrivateAccount {
                    await loadPendingRequestsCount()
                    await loadPendingRequests()
                } else {
                    // If going public, automatically accept all pending requests
                    await acceptAllPendingRequests()
                    pendingRequestsCount = 0
                    pendingRequests = []
                }
                
            } catch {
                print("❌ Error updating privacy setting: \(error)")
                errorMessage = "Failed to update privacy setting"
                // Revert the toggle
                isPrivateAccount.toggle()
            }
        }
    }
    
    private func loadPendingRequestsCount() async {
        guard let userId = currentUserId else { return }
        
        do {
            let count: Int = try await SupabaseManager.shared.client
                .from("follows")
                .select("id", count: .exact)
                .eq("following_id", value: userId)
                .eq("status", value: "pending")
                .execute()
                .count ?? 0
            
            pendingRequestsCount = count
            
        } catch {
            print("❌ Error loading pending requests count: \(error)")
        }
    }
    
    private func loadPendingRequests() async {
        guard let userId = currentUserId else { return }
        
        do {
            // まずpendingフォローリクエストを取得
            let requests: [FollowRequest] = try await SupabaseManager.shared.client
                .from("follows")
                .select("*")
                .eq("following_id", value: userId)
                .eq("status", value: "pending")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // 各リクエストに対してフォロワーのプロフィール情報を取得
            var requestsWithProfiles: [FollowRequest] = []
            for var request in requests {
                do {
                    let profile: UserProfile = try await SupabaseManager.shared.client
                        .from("profiles")
                        .select("*")
                        .eq("id", value: request.follower_id)
                        .single()
                        .execute()
                        .value
                    
                    request.followerProfile = profile
                    requestsWithProfiles.append(request)
                } catch {
                    print("❌ Error loading profile for follower \(request.follower_id): \(error)")
                    // プロフィール情報がなくてもリクエストは表示
                    requestsWithProfiles.append(request)
                }
            }
            
            pendingRequests = requestsWithProfiles
            
        } catch {
            print("❌ Error loading pending requests: \(error)")
        }
    }
    
    func acceptFollowRequest(_ request: FollowRequest) async {
        do {
            try await SupabaseManager.shared.client
                .from("follows")
                .update(["status": "accepted"])
                .eq("id", value: request.id)
                .execute()
            
            // リストから削除
            pendingRequests.removeAll { $0.id == request.id }
            pendingRequestsCount = pendingRequests.count
            
            // フォロー承認通知を作成
            if let followerProfile = request.followerProfile {
                await NotificationService.shared.createFollowNotification(
                    fromUserId: request.follower_id,
                    toUserId: request.following_id,
                    senderProfile: followerProfile
                )
            }
            
            print("✅ Follow request accepted")
            
        } catch {
            print("❌ Error accepting follow request: \(error)")
            errorMessage = "Failed to accept follow request"
        }
    }
    
    func rejectFollowRequest(_ request: FollowRequest) async {
        do {
            try await SupabaseManager.shared.client
                .from("follows")
                .delete()
                .eq("id", value: request.id)
                .execute()
            
            // リストから削除
            pendingRequests.removeAll { $0.id == request.id }
            pendingRequestsCount = pendingRequests.count
            
            print("✅ Follow request rejected")
            
        } catch {
            print("❌ Error rejecting follow request: \(error)")
            errorMessage = "Failed to reject follow request"
        }
    }
    
    private func acceptAllPendingRequests() async {
        guard let userId = currentUserId else { return }
        
        do {
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