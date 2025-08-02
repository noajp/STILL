//======================================================================
// MARK: - RealtimeSubscriptionManager.swift
// Purpose: Manages real-time subscriptions, notifications, and message updates
// Path: still/Core/Services/RealtimeSubscriptionManager.swift
//======================================================================

import Foundation
import Supabase

/// Manages real-time subscriptions and polling for message updates
/// Handles authentication state changes and provides live data synchronization
@MainActor
class RealtimeSubscriptionManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var unreadConversationsCount: Int = 0
    @Published var isConnected: Bool = false
    
    // MARK: - Private Properties
    
    private let supabase = SupabaseManager.shared.client
    private let conversationManager = ConversationManager()
    
    private var updateTimer: Timer?
    private var authenticationObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    
    init() {
        setupAuthenticationListener()
    }
    
    deinit {
        // Note: In Swift concurrency, deinit cannot access MainActor-isolated properties
        // Cleanup should be called explicitly before deallocation
        // Timer will be automatically cleaned up when the object is deallocated
    }
    
    // MARK: - Public Methods
    
    /// Start real-time subscriptions and polling
    func startSubscriptions() {
        guard AuthManager.shared.currentUser != nil else {
            print("⚠️ Cannot start subscriptions: User not authenticated")
            return
        }
        
        startPollingForUpdates()
        setupSupabaseRealtime()
        isConnected = true
        
        print("✅ Real-time subscriptions started")
    }
    
    /// Stop all subscriptions and cleanup
    func stopSubscriptions() {
        cleanup()
        isConnected = false
        unreadConversationsCount = 0
        
        print("🔌 Real-time subscriptions stopped")
    }
    
    /// Force update unread count immediately
    func updateUnreadCountImmediately() {
        Task {
            await updateUnreadCount()
        }
    }
    
    /// Trigger manual refresh of data
    func refreshData() {
        Task {
            await updateUnreadCount()
        }
    }
    
    // MARK: - Private Methods
    
    /// Setup authentication state change listener
    private func setupAuthenticationListener() {
        authenticationObserver = NotificationCenter.default.addObserver(
            forName: .authStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleAuthStateChange()
            }
        }
        
        // Setup immediately if user is already authenticated
        if AuthManager.shared.currentUser != nil {
            startSubscriptions()
        }
    }
    
    /// Handle authentication state changes
    private func handleAuthStateChange() {
        if AuthManager.shared.currentUser != nil {
            startSubscriptions()
        } else {
            stopSubscriptions()
        }
    }
    
    /// Start polling timer for periodic updates
    private func startPollingForUpdates() {
        stopPolling() // Clean up existing timer
        
        // Poll for unread count updates every 10 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.updateUnreadCount()
            }
        }
        
        // Update immediately
        Task {
            await updateUnreadCount()
        }
        
        print("📊 Polling started for unread count updates")
    }
    
    /// Stop polling timer
    private func stopPolling() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Setup Supabase real-time subscription
    private func setupSupabaseRealtime() {
        // TODO: Implement Supabase realtime subscription for messages table
        // This would provide instant notifications when new messages arrive
        // For now, we rely on polling mechanism
        
        print("🔄 Supabase realtime setup (placeholder - using polling)")
    }
    
    /// Update unread conversations count
    private func updateUnreadCount() async {
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            unreadConversationsCount = 0
            return
        }
        
        let count = await conversationManager.calculateUnreadConversationsCount(for: currentUserId)
        
        // Update on main thread
        await MainActor.run {
            unreadConversationsCount = count
        }
    }
    
    /// Cleanup all subscriptions and timers
    private func cleanup() {
        stopPolling()
        
        if let observer = authenticationObserver {
            NotificationCenter.default.removeObserver(observer)
            authenticationObserver = nil
        }
        
        // TODO: Cleanup Supabase real-time subscriptions when implemented
    }
}

