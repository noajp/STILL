//======================================================================
// MARK: - SupabaseManage.swift
// Purpose: SupabaseManage implementation (SupabaseManageの実装)
// Path: still/Core/Networking/SupabaseManage.swift
//======================================================================
import Foundation
import Supabase

/// Singleton manager for Supabase client configuration and secure database access
/// Provides centralized configuration management with security logging and validation
final class SupabaseManager: @unchecked Sendable {
    
    // MARK: - Singleton Instance
    
    /// Shared singleton instance of SupabaseManager
    static let shared = SupabaseManager()
    
    // MARK: - Properties
    
    /// Primary Supabase client instance used throughout the application
    let client: SupabaseClient
    
    /// Secure logger for tracking authentication and database operations
    private let secureLogger = SecureLogger.shared
    
    // MARK: - Initialization
    
    /// Private initializer ensuring singleton pattern and secure configuration
    /// Validates configuration parameters and initializes Supabase client with security logging
    private init() {
        // Validate and retrieve secure Supabase URL configuration
        guard let supabaseURL = URL(string: SecureConfig.shared.supabaseURL) else {
            secureLogger.error("Invalid Supabase URL configuration")
            fatalError("Invalid Supabase URL")
        }
        
        // Validate and retrieve secure anonymous key configuration
        let supabaseKey = SecureConfig.shared.supabaseAnonKey
        guard !supabaseKey.isEmpty else {
            secureLogger.error("Missing Supabase anonymous key")
            fatalError("Missing Supabase configuration")
        }
        
        // Initialize Supabase client with validated configuration
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
        
        secureLogger.info("SupabaseManager initialized with secure configuration")
        setupSecurityConfiguration()
    }
    
    // MARK: - Private Methods
    
    /// Sets up additional security configurations for the Supabase client
    /// Called during initialization to apply security policies and settings
    private func setupSecurityConfiguration() {
        // Additional security configuration can be added here
        // Such as SSL settings, timeout configurations, retry policies, etc.
        secureLogger.debug("Supabase security configuration completed")
    }
    
    // MARK: - Public Methods
    
    /// Creates a fresh Supabase client instance to avoid cached RPC function definitions
    /// Useful when you need to ensure clean state or avoid caching issues
    /// - Returns: A new SupabaseClient instance with same configuration as the shared client
    func createFreshClient() -> SupabaseClient {
        // Validate URL configuration for fresh client
        guard let supabaseURL = URL(string: SecureConfig.shared.supabaseURL) else {
            secureLogger.error("Invalid Supabase URL configuration")
            fatalError("Invalid Supabase URL")
        }
        
        // Validate key configuration for fresh client
        let supabaseKey = SecureConfig.shared.supabaseAnonKey
        guard !supabaseKey.isEmpty else {
            secureLogger.error("Missing Supabase anonymous key")
            fatalError("Missing Supabase configuration")
        }
        
        // Return new client instance with same configuration
        return SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

