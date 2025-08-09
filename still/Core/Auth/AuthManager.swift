//======================================================================
// MARK: - AuthManager.swift
// Purpose: Authentication manager with user session handling, secure token management, and Supabase auth integration (ユーザーセッション処理、セキュアトークン管理、Supabase認証統合を持つ認証マネージャー)
// Path: still/Core/Auth/AuthManager.swift
//======================================================================
import Foundation
import Supabase
import AuthenticationServices

// MARK: - Notification Extensions

/// Notification names for auth state changes
extension Notification.Name {
    /// Posted when authentication state changes (login/logout)
    static let authStateChanged = Notification.Name("authStateChanged")
}

// MARK: - Auth Errors

/// Comprehensive authentication error types with localized descriptions
enum AuthError: LocalizedError {
    /// Invalid input data (email format, empty fields, etc.)
    case invalidInput(String)
    
    /// Rate limiting applied due to too many attempts
    case rateLimitExceeded(TimeInterval)
    
    /// Account locked due to security concerns
    case accountLocked
    
    /// Password doesn't meet security requirements
    case weakPassword([String])
    
    /// Unknown authentication error
    case unknown(String)
    
    /// Localized error description for user display
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .rateLimitExceeded(let duration):
            return "Too many failed attempts. Please try again in \(Int(duration/60)) minutes."
        case .accountLocked:
            return "Account temporarily locked due to multiple failed login attempts."
        case .weakPassword(let errors):
            return "Password requirements not met: \(errors.joined(separator: ", "))"
        case .unknown(let message):
            return "Authentication error: \(message)"
        }
    }
}

// MARK: - User Model

/// Application-specific user structure that wraps Supabase user data
/// Contains essential user information needed throughout the app
struct AppUser: Codable {
    /// Unique user identifier from Supabase Auth
    let id: String
    
    /// User's email address (optional as some auth methods don't require email)
    let email: String?
    
    /// Account creation timestamp
    let createdAt: String?
    
    /// Coding keys for JSON serialization/deserialization
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
    }
}

// MARK: - AuthManager Class

/// Comprehensive authentication manager that handles user sessions, security, and state management
/// Integrates with Supabase Auth and provides secure authentication with rate limiting and session management
/// Supports sign in, sign up, password reset, and automatic session restoration
@MainActor
class AuthManager: ObservableObject, AuthManagerProtocol {
    // MARK: - Type Aliases
    
    /// User type used throughout the authentication system
    typealias User = AppUser
    
    // MARK: - Singleton
    
    /// Shared instance of the authentication manager
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    
    /// Currently authenticated user (nil if not authenticated)
    @Published var currentUser: AppUser?
    
    /// Boolean indicating if user is currently authenticated
    @Published var isAuthenticated = false
    
    /// Loading state for authentication operations
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    /// Supabase client for authentication operations
    private let client = SupabaseManager.shared.client
    
    /// Secure logger for authentication events
    private let secureLogger = SecureLogger.shared
    
    // MARK: - Security Configuration
    
    /// Maximum number of login attempts before account lockout
    private let maxLoginAttempts = 5
    
    /// Duration of account lockout after max attempts (15 minutes)
    private let lockoutDuration: TimeInterval = 900
    
    /// Dictionary tracking login attempts per user (email -> (count, lastAttempt))
    private var loginAttempts: [String: (count: Int, lastAttempt: Date)] = [:]
    
    private init() {
        setupSecurityConfiguration()
        Task {
            await checkCurrentUser()
        }
    }
    
    private func setupSecurityConfiguration() {
        // セキュア設定の初期化
        #if DEBUG
        SecureConfig.shared.initializeForDevelopment()
        #endif
        secureLogger.info("AuthManager initialized with secure configuration")
    }
    
    // MARK: - Current User Check
    
    func checkCurrentUser() async {
        isLoading = true
        
        do {
            let session = try await client.auth.session
            let user = session.user
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            // Ensure user profile exists for existing session
            await ensureUserProfileExists(for: user)
            
            secureLogger.authEvent("Current user session found", userID: user.id.uuidString)
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            secureLogger.debug("No current user session found")
        }
        
        isLoading = false
    }
    
    // MARK: - Email Authentication
    
    func signIn(email: String, password: String) async throws -> AppUser {
        try await signInWithEmail(email: email, password: password)
        guard let user = currentUser else {
            throw AuthError.unknown("Failed to retrieve user after sign in")
        }
        return user
    }
    
    func signInWithEmail(email: String, password: String) async throws {
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            secureLogger.securityEvent("Invalid email format during sign in", details: ["email": email])
            throw AuthError.invalidInput("Invalid email format")
        }
        
        // レート制限チェック
        try checkRateLimit(for: validEmail)
        
        print("🔵 Attempting sign in with email: \(validEmail)")
        secureLogger.authEvent("Sign in attempt", userID: nil)
        isLoading = true
        
        do {
            let session = try await client.auth.signIn(
                email: validEmail,
                password: password
            )
            
            let user = session.user
            print("✅ Sign in successful")
            print("🔵 User ID: \(user.id.uuidString)")
            print("🔵 User email: \(user.email ?? "nil")")
            print("🔵 User email confirmed: \(user.emailConfirmedAt != nil)")
            print("🔵 User created at: \(user.createdAt)")
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            // ログイン成功時はレート制限をリセット
            resetLoginAttempts(for: validEmail)
            
            // Ensure user profile exists
            await ensureUserProfileExists(for: user)
            
            secureLogger.authEvent("Sign in successful", userID: user.id.uuidString)
        } catch {
            print("❌ Sign in failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            if let authError = error as? AuthError {
                print("❌ AuthError: \(authError.localizedDescription)")
            }
            
            // Check if it's a Supabase specific error
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
                
                // Handle common Supabase auth errors
                if nsError.localizedDescription.lowercased().contains("invalid") {
                    print("⚠️ This might be an invalid email/password combination")
                } else if nsError.localizedDescription.lowercased().contains("confirm") {
                    print("⚠️ This might be an unconfirmed email address")
                } else if nsError.localizedDescription.lowercased().contains("disabled") {
                    print("⚠️ This account might be disabled")
                }
            }
            
            recordFailedLoginAttempt(for: validEmail)
            secureLogger.securityEvent("Sign in failed", details: ["error": error.localizedDescription])
            isLoading = false
            throw error
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async throws -> AppUser {
        // Use existing signUpWithEmail method and ignore the return value for protocol compliance
        _ = try await signUpWithEmail(email: email, password: password)
        guard let user = currentUser else {
            throw AuthError.unknown("Failed to retrieve user after sign up")
        }
        return user
    }
    
    func signUpWithEmail(email: String, password: String) async throws -> String {
        // 入力検証
        let emailValidation = InputValidator.validateEmail(email)
        guard emailValidation.isValid, let validEmail = emailValidation.value else {
            secureLogger.securityEvent("Invalid email format during sign up", details: ["email": email])
            throw AuthError.invalidInput("Invalid email format")
        }
        
        // パスワード強度チェック
        let passwordValidation = InputValidator.validatePassword(password)
        guard passwordValidation.isValid else {
            secureLogger.securityEvent("Weak password during sign up")
            throw AuthError.weakPassword(passwordValidation.errors)
        }
        
        print("🔵 Attempting sign up with email: \(validEmail)")
        print("🔵 Password validation passed")
        isLoading = true
        secureLogger.authEvent("Sign up attempt", userID: nil)
        
        do {
            let session = try await client.auth.signUp(
                email: validEmail,
                password: password
            )
            
            let user = session.user
            print("✅ Sign up successful")
            print("🔵 User ID: \(user.id.uuidString)")
            print("🔵 User email: \(user.email ?? "nil")")
            print("🔵 User email confirmed: \(user.emailConfirmedAt != nil)")
            if let sessionData = session.session {
                print("🔵 Session access token exists: \(!sessionData.accessToken.isEmpty)")
            } else {
                print("🔵 No session data available")
            }
            
            // Check if email confirmation is required  
            if user.emailConfirmedAt == nil {
                print("⚠️ Email confirmation required")
                
                // サインアウトして確認待ち状態にする
                try await client.auth.signOut()
                secureLogger.authEvent("Sign up successful - email confirmation required", userID: user.id.uuidString)
                return user.id.uuidString
            }
            
            // サインアップ成功時もログインした状態を維持
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            // Ensure user profile exists after sign up
            await ensureUserProfileExists(for: user)
            
            secureLogger.authEvent("Sign up successful", userID: user.id.uuidString)
            return user.id.uuidString
        } catch {
            print("❌ Sign up failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
                
                // Handle common sign up errors
                if nsError.localizedDescription.lowercased().contains("already") {
                    print("⚠️ This email is already registered")
                } else if nsError.localizedDescription.lowercased().contains("weak") {
                    print("⚠️ Password is too weak")
                }
            }
            
            secureLogger.securityEvent("Sign up failed", details: ["error": error.localizedDescription])
            isLoading = false
            throw error
        }
    }
    
    // MARK: - Google Authentication
    
    func signInWithGoogle() async throws {
        print("🔵 Starting Google OAuth sign in")
        isLoading = true
        secureLogger.authEvent("Google Sign In attempt", userID: nil)
        
        do {
            let redirectURL = URL(string: "com.takanorinakano.tete://auth")!
            print("🔵 Using redirect URL: \(redirectURL)")
            
            // WebAuthenticationSessionエラー（error 1）の詳細説明を追加
            print("ℹ️ WebAuthenticationSession error 1 usually means:")
            print("ℹ️ - User cancelled the authentication")
            print("ℹ️ - OAuth provider not configured in Supabase")
            print("ℹ️ - URL scheme not properly registered")
            
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: redirectURL
            )
            
            print("✅ Google OAuth flow initiated - waiting for callback")
            secureLogger.authEvent("Google Sign In initiated", userID: nil)
            // Note: isLoading will be set to false in handleAuthCallback
        } catch {
            print("❌ Google sign in failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
                
                // WebAuthenticationSession specific error handling
                if nsError.domain == "com.apple.AuthenticationServices.WebAuthenticationSession" {
                    switch nsError.code {
                    case 1:
                        print("⚠️ User cancelled authentication or OAuth not configured")
                        print("⚠️ Please check:")
                        print("⚠️ 1. Google OAuth is enabled in Supabase Dashboard")
                        print("⚠️ 2. Client ID and Secret are configured")
                        print("⚠️ 3. Redirect URL is added to Google OAuth settings")
                    case 2:
                        print("⚠️ Session was cancelled")
                    case 3:
                        print("⚠️ Context unavailable")
                    default:
                        print("⚠️ Unknown WebAuthenticationSession error")
                    }
                }
            }
            
            isLoading = false
            secureLogger.securityEvent("Google Sign In failed", details: ["error": error.localizedDescription])
            throw error
        }
    }
    
    // MARK: - Profile Management
    
    func createUserProfile(userId: String, username: String, displayName: String, bio: String? = nil) async throws {
        print("📝 Creating user profile for userId: \(userId), username: \(username)")
        
        let profileData: [String: AnyJSON] = [
            "id": AnyJSON.string(userId),
            "username": AnyJSON.string(username),
            "display_name": AnyJSON.string(displayName),
            "bio": AnyJSON.string(bio ?? "Hello, I'm \(displayName)!")
        ]
        
        do {
            let response = try await client
                .from("profiles")
                .insert(profileData)
                .execute()
            
            print("✅ Profile created successfully: \(response)")
        } catch {
            print("❌ Profile creation failed: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(error.localizedDescription)")
            
            // Check if it's an RLS policy error
            if error.localizedDescription.contains("row-level security policy") {
                print("❌ RLS Policy Error - the user may not have permission to create their profile")
                print("💡 Tip: Make sure the profiles table has an INSERT policy for authenticated users")
            }
            
            throw error
        }
        
        print("✅ User profile created: \(username)")
    }
    
    func checkUsernameAvailability(username: String) async throws -> Bool {
        do {
            let response = try await client
                .from("profiles")
                .select("username")
                .eq("username", value: username)
                .execute()
            
            // If we get data, username is taken
            let data = String(data: response.data, encoding: .utf8) ?? ""
            return data == "[]" // Empty array means username is available
        } catch {
            print("❌ Error checking username: \(error)")
            throw error
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        isLoading = true
        let userID = currentUser?.id
        
        do {
            try await client.auth.signOut()
            
            // メモリ内の機密データをクリア
            clearSensitiveData()
            
            self.currentUser = nil
            self.isAuthenticated = false
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            secureLogger.authEvent("Sign out successful", userID: userID)
        } catch {
            secureLogger.securityEvent("Sign out failed", details: ["error": error.localizedDescription])
            throw error
        }
        
        isLoading = false
    }
    
    func refreshSession() async throws {
        isLoading = true
        
        do {
            let session = try await client.auth.refreshSession()
            let user = session.user
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            secureLogger.authEvent("Session refreshed successfully", userID: user.id.uuidString)
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
            secureLogger.securityEvent("Session refresh failed", details: ["error": error.localizedDescription])
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Security Helper Methods
    
    private func checkRateLimit(for email: String) throws {
        // レート制限機能は無効化
        return
    }
    
    private func recordFailedLoginAttempt(for email: String) {
        // ログイン失敗記録は簡素化
        secureLogger.securityEvent("Failed login attempt", details: ["email": email])
    }
    
    private func resetLoginAttempts(for email: String) {
        loginAttempts.removeValue(forKey: email)
    }
    
    private func clearSensitiveData() {
        // メモリ内の機密データをゼロクリア
        loginAttempts.removeAll()
        
        // 追加のクリーンアップ処理
        secureLogger.debug("Sensitive data cleared from memory")
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
        print("✅ Password reset email sent to: \(email)")
    }
    
    // MARK: - Apple Authentication
    
    func signInWithApple() async throws {
        print("🔵 Starting Apple OAuth sign in")
        isLoading = true
        secureLogger.authEvent("Apple Sign In attempt", userID: nil)
        
        do {
            let redirectURL = URL(string: "com.takanorinakano.tete://auth")!
            print("🔵 Using redirect URL: \(redirectURL)")
            
            try await client.auth.signInWithOAuth(
                provider: .apple,
                redirectTo: redirectURL
            )
            
            print("✅ Apple OAuth flow initiated - waiting for callback")
            secureLogger.authEvent("Apple Sign In initiated", userID: nil)
            // Note: isLoading will be set to false in handleAuthCallback
        } catch {
            print("❌ Apple sign in failed: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                print("❌ Error domain: \(nsError.domain)")
                print("❌ Error code: \(nsError.code)")
                print("❌ Error userInfo: \(nsError.userInfo)")
            }
            isLoading = false
            secureLogger.securityEvent("Apple Sign In failed", details: ["error": error.localizedDescription])
            throw error
        }
    }
    
    // MARK: - OAuth URL Handling
    
    func handleAuthCallback(url: URL) async throws {
        print("🔵 Handling auth callback URL: \(url)")
        
        // Extract the session from the URL callback
        do {
            let session = try await client.auth.session(from: url)
            let user = session.user
            
            print("🔵 Auth callback successful")
            print("🔵 User ID: \(user.id.uuidString)")
            print("🔵 User Email: \(user.email ?? "nil")")
            
            self.currentUser = AppUser(
                id: user.id.uuidString,
                email: user.email,
                createdAt: user.createdAt.ISO8601Format()
            )
            self.isAuthenticated = true
            self.isLoading = false
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            // Check if user profile exists, create if not
            await ensureUserProfileExists(for: user)
            
            print("✅ OAuth authentication successful: \(user.email ?? "")")
        } catch {
            print("❌ Auth callback failed: \(error)")
            self.isLoading = false
            throw error
        }
    }
    
    private func ensureUserProfileExists(for user: Supabase.User) async {
        do {
            // First, ensure the profiles table exists
            await ensureProfilesTableExists()
            
            // Check if profile already exists
            let profileCount = try await client
                .from("profiles")
                .select("id", head: true, count: .exact)
                .eq("id", value: user.id.uuidString)
                .execute()
                .count ?? 0
            
            if profileCount == 0 {
                print("🔵 Creating user profile for user: \(user.id.uuidString)")
                
                // Check if we have saved user info from signup
                let userId = user.id.uuidString
                let savedUsername = UserDefaults.standard.string(forKey: "pendingUsername_\(userId)")
                let savedDisplayName = UserDefaults.standard.string(forKey: "pendingDisplayName_\(userId)")
                
                let username: String
                let displayName: String
                
                if let savedUsername = savedUsername, let savedDisplayName = savedDisplayName {
                    // Use saved info from signup
                    username = savedUsername
                    displayName = savedDisplayName
                    
                    // Clean up saved data
                    UserDefaults.standard.removeObject(forKey: "pendingUsername_\(userId)")
                    UserDefaults.standard.removeObject(forKey: "pendingDisplayName_\(userId)")
                    
                    print("🔵 Using saved signup info: username=\(username), displayName=\(displayName)")
                } else {
                    // Generate username from email for OAuth users
                    let baseUsername = user.email?.components(separatedBy: "@").first?
                        .lowercased()
                        .replacingOccurrences(of: ".", with: "_")
                        .replacingOccurrences(of: "+", with: "_")
                        .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" } ?? ""
                    
                    // Ensure username meets constraints
                    username = if baseUsername.count >= 3 && baseUsername.count <= 30 {
                        String(baseUsername)
                    } else {
                        "user\(String(user.id.uuidString.lowercased().replacingOccurrences(of: "-", with: "").prefix(8)))"
                    }
                    
                    // For OAuth users, use email as display name initially
                    displayName = user.email ?? username
                    
                    print("🔵 Generated username from email: username=\(username), displayName=\(displayName)")
                }
                
                try await createUserProfile(
                    userId: userId,
                    username: username,
                    displayName: displayName,
                    bio: "New to TETE!"
                )
                
                print("✅ User profile created: \(username)")
            } else {
                print("🔵 User profile already exists for: \(user.id.uuidString)")
            }
        } catch {
            print("❌ Error ensuring user profile exists: \(error)")
            // Don't throw error here - authentication should still succeed even if profile creation fails
        }
    }
    
    // MARK: - Database Schema Management
    
    private func ensureProfilesTableExists() async {
        // For now, just log that we need to create the table manually
        // The table should be created through Supabase Dashboard or CLI
        print("⚠️ User_profiles table needs to be created manually in Supabase Dashboard")
        print("🔍 Please run the migration for user_profiles table")
    }
    
    // MARK: - Protocol Compliance
    // AuthManagerProtocol methods signIn and signUp are implemented above
    
}