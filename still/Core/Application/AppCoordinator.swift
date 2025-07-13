//======================================================================
// MARK: - AppCoordinator.swift
// Purpose: AppCoordinator implementation (AppCoordinatorの実装)
// Path: still/Core/Application/AppCoordinator.swift
//======================================================================
//
//  AppCoordinator.swift
//  tete
//
//  アプリケーション全体のコーディネーション
//

import SwiftUI
import Combine

// MARK: - App Coordinator
@MainActor
final class AppCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentTab: MainTab = .home
    @Published var showGridMode = false
    @Published var showingCreatePost = false
    @Published var isInSingleView = false
    
    // MARK: - Services
    private let imageCache = ImageCacheManager.shared
    private var realtimeMessageService: RealtimeMessageService?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupServices()
        preloadCriticalResources()
    }
    
    // MARK: - Public Methods
    
    /// アプリケーション起動時の初期化
    func initialize(with userId: String) async {
        // Initialize realtime messaging
        realtimeMessageService = RealtimeMessageService(userId: userId)
        await realtimeMessageService?.connect()
        
        // Preload user-specific data
        await preloadUserData(userId: userId)
        
        print("🚀 AppCoordinator initialized for user: \(userId)")
    }
    
    /// アプリケーション終了時のクリーンアップ
    func cleanup() {
        Task {
            await realtimeMessageService?.disconnect()
            cancellables.removeAll()
            print("🧹 AppCoordinator cleaned up")
        }
    }
    
    /// タブを切り替え
    func switchTab(to tab: MainTab) {
        currentTab = tab
        
        // Tab-specific optimizations
        switch tab {
        case .home:
            optimizeForFeed()
        case .messages:
            optimizeForMessages()
        case .createPost:
            optimizeForCamera()
        case .myPage:
            optimizeForProfile()
        }
    }
    
    /// ビューモードを切り替え
    func toggleViewMode() {
        showGridMode.toggle()
        UserDefaults.standard.set(showGridMode, forKey: "ShowGridMode")
    }
    
    // MARK: - Private Methods
    
    private func setupServices() {
        // Load saved preferences
        showGridMode = UserDefaults.standard.bool(forKey: "ShowGridMode")
        
        // Setup automatic cleanup
        NotificationCenter.default.publisher(for: UIApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.cleanup()
            }
            .store(in: &cancellables)
    }
    
    private func preloadCriticalResources() {
        Task {
            // Preload common UI elements
            await preloadCommonImages()
            
            // Warm up image cache
            await warmUpImageCache()
        }
    }
    
    private func preloadUserData(userId: String) async {
        // This would preload user-specific data in background
        print("🔄 Preloading user data...")
    }
    
    private func preloadCommonImages() async {
        let commonImageUrls: [String] = [
            // Avatar placeholders, app icons, etc.
        ]
        
        imageCache.preloadImages(commonImageUrls)
    }
    
    private func warmUpImageCache() async {
        // Warm up cache with recent images
        print("🔥 Warming up image cache...")
    }
    
    // MARK: - Tab Optimizations
    
    private func optimizeForFeed() {
        // Optimize for scrolling performance
        Task {
            imageCache.clearCache() // Clear old cache
        }
    }
    
    private func optimizeForMessages() {
        // Ensure realtime connection is active
        Task {
            if realtimeMessageService?.isConnected == false {
                await realtimeMessageService?.connect()
            }
        }
    }
    
    private func optimizeForCamera() {
        // Prepare camera resources
        print("📸 Optimizing for camera...")
    }
    
    private func optimizeForProfile() {
        // Preload profile data
        print("👤 Optimizing for profile...")
    }
}

// MARK: - Main Tab Enum
enum MainTab: Int, CaseIterable {
    case home = 0
    case messages = 1
    case createPost = 2
    case myPage = 3
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .messages: return "Messages"
        case .createPost: return "Create"
        case .myPage: return "Profile"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "house"
        case .messages: return "message"
        case .createPost: return "plus.square"
        case .myPage: return "person"
        }
    }
}

// MARK: - Enhanced MainTabView
struct EnhancedMainTabView: View {
    @StateObject private var coordinator = AppCoordinator()
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        TabView(selection: $coordinator.currentTab) {
            // Home Feed
            HomeFeedView(
                showGridMode: $coordinator.showGridMode, 
                showingCreatePost: $coordinator.showingCreatePost, 
                isInSingleView: $coordinator.isInSingleView, 
                headerOffset: Binding.constant(0),
                onBackToGrid: { () -> Void in },
                onScrollChanged: { (_: CGFloat) -> Void in }
            )
                .tabItem {
                    Image(systemName: MainTab.home.iconName)
                    Text(MainTab.home.title)
                }
                .tag(MainTab.home)
            
            // Messages
            MessagesView()
                .tabItem {
                    Image(systemName: MainTab.messages.iconName)
                    Text(MainTab.messages.title)
                }
                .tag(MainTab.messages)
            
            // Create Post
            CreatePostView()
                .tabItem {
                    Image(systemName: MainTab.createPost.iconName)
                    Text(MainTab.createPost.title)
                }
                .tag(MainTab.createPost)
            
            // Profile
            MyPageView(
                isInProfileSingleView: .constant(false),
                isUserSearchMode: .constant(false)
            )
                .tabItem {
                    Image(systemName: MainTab.myPage.iconName)
                    Text(MainTab.myPage.title)
                }
                .tag(MainTab.myPage)
        }
        .accentColor(MinimalDesign.Colors.accent)
        .task {
            if let userId = authManager.currentUser?.id {
                await coordinator.initialize(with: userId)
            }
        }
        .onChange(of: coordinator.currentTab) { _, newTab in
            coordinator.switchTab(to: newTab)
        }
        .fullScreenCover(isPresented: $coordinator.showingCreatePost) {
            CreatePostNavigationView()
        }
        .environmentObject(coordinator)
    }
}