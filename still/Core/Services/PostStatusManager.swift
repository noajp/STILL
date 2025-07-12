//======================================================================
// MARK: - PostStatusManager.swift
// Purpose: Manager class for system operations (PostStatusManagerのシステム操作管理クラス)
// Path: still/Core/Services/PostStatusManager.swift
//======================================================================
//
//  PostStatusManager.swift
//  tete
//
//  Global post status management for showing status bars across the app
//

import SwiftUI
import Combine

@MainActor
class PostStatusManager: ObservableObject {
    static let shared = PostStatusManager()
    
    @Published var showStatus = false
    @Published var statusMessage = ""
    @Published var statusColor: Color = .red
    @Published var isSuccess = false
    @Published var progress: CGFloat = 0.0
    
    enum PostStatus {
        case uploading
        case processing
        case completed
        case failed
    }
    
    @Published var currentStatus: PostStatus = .uploading
    
    private init() {
        // Listen for post notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostStarted),
            name: .postUploadStarted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostProgress),
            name: .postUploadProgress,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostCompleted),
            name: .postUploadCompleted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostFailed),
            name: .postUploadFailed,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePostCreated),
            name: NSNotification.Name("PostCreated"),
            object: nil
        )
    }
    
    @objc private func handlePostStarted() {
        print("🔔 PostStatusManager: Post started")
        currentStatus = .uploading
        statusMessage = "画像をアップロード中..."
        statusColor = .blue
        isSuccess = false
        progress = 0.0
        showStatus = true
    }
    
    @objc private func handlePostProgress(_ notification: Notification) {
        if let progressValue = notification.userInfo?["progress"] as? Double {
            let cgProgress = CGFloat(progressValue)
            print("🔔 PostStatusManager: Progress \(Int(progressValue * 100))%")
            
            withAnimation(.easeOut(duration: 0.3)) {
                progress = cgProgress
            }
            
            if progressValue < 0.5 {
                statusMessage = "画像をアップロード中..."
                statusColor = .blue
                currentStatus = .uploading
            } else if progressValue < 1.0 {
                statusMessage = "投稿を処理中..."
                statusColor = .orange
                currentStatus = .processing
            }
        }
    }
    
    @objc private func handlePostCompleted() {
        print("🔔 PostStatusManager: Post upload completed, waiting for feed reflection...")
        currentStatus = .processing
        statusMessage = "投稿を処理中..."
        statusColor = .orange
        
        // プログレスバーを100%に
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 1.0
        }
        
        // PostCreated通知を待つ（タイムアウト10秒）
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            // タイムアウトした場合も完了とみなす
            if self.currentStatus == .processing {
                self.showCompletionStatus()
            }
        }
    }
    
    @objc private func handlePostCreated() {
        print("🔔 PostStatusManager: Post reflected in feed")
        if currentStatus == .processing {
            showCompletionStatus()
        }
    }
    
    private func showCompletionStatus() {
        currentStatus = .completed
        statusMessage = "投稿が完了しました"
        statusColor = .green
        isSuccess = true
        
        // 2秒後に非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hideStatus()
        }
    }
    
    @objc private func handlePostFailed(_ notification: Notification) {
        print("🔔 PostStatusManager: Post failed")
        let errorMessage = notification.userInfo?["error"] as? String ?? "Unknown error"
        currentStatus = .failed
        statusMessage = "投稿に失敗しました: \(errorMessage)"
        statusColor = .red
        isSuccess = false
        
        // 5秒後に非表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.hideStatus()
        }
    }
    
    func hideStatus() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showStatus = false
            progress = 0.0
            currentStatus = .uploading
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}