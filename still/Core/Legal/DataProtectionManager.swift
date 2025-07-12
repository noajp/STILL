//======================================================================
// MARK: - DataProtectionManager.swift
// Purpose: Manager class for system operations (DataProtectionManagerのシステム操作管理クラス)
// Path: still/Core/Legal/DataProtectionManager.swift
//======================================================================
//
//  DataProtectionManager.swift
//  tete
//
//  GDPR、CCPA、その他データ保護規制への対応
//

import Foundation
import SwiftUI

// MARK: - Data Protection Manager
@MainActor
final class DataProtectionManager: ObservableObject {
    
    static let shared = DataProtectionManager()
    
    // MARK: - Published Properties
    @Published var hasShownPrivacyNotice = false
    @Published var hasAcceptedTerms = false
    @Published var consentChoices: ConsentChoices = ConsentChoices()
    @Published var dataRetentionPeriod: DataRetentionPeriod = .standard
    
    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let dateFormatter = ISO8601DateFormatter()
    
    // MARK: - Initialization
    private init() {
        loadConsentChoices()
    }
    
    // MARK: - Consent Management
    
    /// ユーザーの同意選択を記録
    func recordConsent(_ choices: ConsentChoices) {
        self.consentChoices = choices
        saveConsentChoices()
        
        // 同意ログを記録
        let consentLog = ConsentLog(
            timestamp: Date(),
            choices: choices,
            version: getCurrentPolicyVersion()
        )
        saveConsentLog(consentLog)
        
        print("✅ User consent recorded: \(choices)")
    }
    
    /// 同意の撤回
    func withdrawConsent(for purposes: [ConsentPurpose]) {
        for purpose in purposes {
            switch purpose {
            case .analytics:
                consentChoices.analytics = false
            case .marketing:
                consentChoices.marketing = false
            case .personalization:
                consentChoices.personalization = false
            case .thirdPartySharing:
                consentChoices.thirdPartySharing = false
            }
        }
        
        saveConsentChoices()
        print("📝 Consent withdrawn for: \(purposes)")
    }
    
    /// 最新の同意状況を確認
    func isConsentRequired() -> Bool {
        let lastConsentVersion = userDefaults.string(forKey: "LastConsentVersion")
        let currentVersion = getCurrentPolicyVersion()
        
        return lastConsentVersion != currentVersion || !hasAcceptedTerms
    }
    
    // MARK: - Data Rights (GDPR Article 15-22)
    
    /// データアクセス権 (Right to Access)
    func requestDataExport() async -> DataExportPackage? {
        do {
            // ユーザーデータの収集
            let userData = try await collectUserData()
            let posts = try await collectUserPosts()
            let messages = try await collectUserMessages()
            let analytics = try await collectAnalyticsData()
            
            let exportPackage = DataExportPackage(
                userData: userData,
                posts: posts,
                messages: messages,
                analytics: analytics,
                generatedAt: Date()
            )
            
            print("📦 Data export package created")
            return exportPackage
            
        } catch {
            print("❌ Failed to create data export: \(error)")
            return nil
        }
    }
    
    /// データ削除権 (Right to Erasure)
    func requestDataDeletion() async -> Bool {
        do {
            // アカウント削除処理
            try await deleteUserAccount()
            try await deleteUserContent()
            try await deleteAnalyticsData()
            try await anonymizeBackupData()
            
            // ローカルデータの削除
            clearLocalData()
            
            print("🗑️ User data deletion completed")
            return true
            
        } catch {
            print("❌ Failed to delete user data: \(error)")
            return false
        }
    }
    
    /// データ訂正権 (Right to Rectification)
    func requestDataCorrection(_ corrections: [DataCorrection]) async -> Bool {
        do {
            for correction in corrections {
                try await applyDataCorrection(correction)
            }
            
            print("✏️ Data corrections applied: \(corrections.count)")
            return true
            
        } catch {
            print("❌ Failed to apply data corrections: \(error)")
            return false
        }
    }
    
    /// データポータビリティ権 (Right to Data Portability)
    func requestDataPortability(format: DataExportFormat) async -> URL? {
        guard let exportPackage = await requestDataExport() else { return nil }
        
        do {
            let exportURL = try await generatePortableData(exportPackage, format: format)
            print("📱 Portable data generated: \(format)")
            return exportURL
            
        } catch {
            print("❌ Failed to generate portable data: \(error)")
            return nil
        }
    }
    
    // MARK: - Age Verification
    
    /// 年齢確認
    func verifyAge(_ birthDate: Date) -> AgeVerificationResult {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        
        guard let age = ageComponents.year else {
            return .invalid
        }
        
        if age < 13 {
            return .tooYoung
        } else if age < 18 {
            return .minorRequiresConsent
        } else {
            return .verified
        }
    }
    
    /// 保護者同意の記録
    func recordParentalConsent(_ consent: ParentalConsent) {
        let consentData = try? JSONEncoder().encode(consent)
        userDefaults.set(consentData, forKey: "ParentalConsent")
        userDefaults.set(true, forKey: "HasParentalConsent")
        
        print("👨‍👩‍👧‍👦 Parental consent recorded")
    }
    
    // MARK: - Data Retention
    
    /// データ保持ポリシーの適用
    func applyDataRetentionPolicy() async {
        let retentionRules = getDataRetentionRules()
        
        for rule in retentionRules {
            do {
                try await enforceRetentionRule(rule)
            } catch {
                print("❌ Failed to enforce retention rule \(rule.category): \(error)")
            }
        }
        
        print("🗓️ Data retention policy applied")
    }
    
    /// 自動データ削除の設定
    func scheduleAutomaticDeletion() {
        // バックグラウンドタスクでデータ保持ポリシーを適用
        Task {
            await applyDataRetentionPolicy()
        }
    }
    
    // MARK: - Privacy Settings
    
    /// プライバシー設定の管理
    func updatePrivacySettings(_ settings: PrivacySettings) {
        let settingsData = try? JSONEncoder().encode(settings)
        userDefaults.set(settingsData, forKey: "PrivacySettings")
        
        // 設定に基づいてデータ処理を調整
        adjustDataProcessing(based: settings)
        
        print("🔒 Privacy settings updated")
    }
    
    /// データ処理の最小化
    func enableDataMinimization() {
        consentChoices.analytics = false
        consentChoices.marketing = false
        consentChoices.personalization = false
        dataRetentionPeriod = .minimal
        
        saveConsentChoices()
        print("📉 Data minimization enabled")
    }
    
    // MARK: - Privacy Notice
    
    /// プライバシー通知の表示判定
    func shouldShowPrivacyNotice() -> Bool {
        let lastShown = userDefaults.object(forKey: "LastPrivacyNoticeShown") as? Date
        let policyVersion = userDefaults.string(forKey: "LastPolicyVersion")
        let currentVersion = getCurrentPolicyVersion()
        
        // 初回または新しいポリシーバージョン
        return lastShown == nil || policyVersion != currentVersion
    }
    
    /// プライバシー通知の記録
    func recordPrivacyNoticeShown() {
        userDefaults.set(Date(), forKey: "LastPrivacyNoticeShown")
        userDefaults.set(getCurrentPolicyVersion(), forKey: "LastPolicyVersion")
        hasShownPrivacyNotice = true
    }
    
    // MARK: - Private Methods
    
    private func loadConsentChoices() {
        if let data = userDefaults.data(forKey: "ConsentChoices"),
           let choices = try? JSONDecoder().decode(ConsentChoices.self, from: data) {
            self.consentChoices = choices
        }
        
        hasAcceptedTerms = userDefaults.bool(forKey: "HasAcceptedTerms")
        hasShownPrivacyNotice = userDefaults.bool(forKey: "HasShownPrivacyNotice")
    }
    
    private func saveConsentChoices() {
        if let data = try? JSONEncoder().encode(consentChoices) {
            userDefaults.set(data, forKey: "ConsentChoices")
        }
        userDefaults.set(hasAcceptedTerms, forKey: "HasAcceptedTerms")
        userDefaults.set(hasShownPrivacyNotice, forKey: "HasShownPrivacyNotice")
    }
    
    private func saveConsentLog(_ log: ConsentLog) {
        var logs = getConsentLogs()
        logs.append(log)
        
        if let data = try? JSONEncoder().encode(logs) {
            userDefaults.set(data, forKey: "ConsentLogs")
        }
    }
    
    private func getConsentLogs() -> [ConsentLog] {
        guard let data = userDefaults.data(forKey: "ConsentLogs"),
              let logs = try? JSONDecoder().decode([ConsentLog].self, from: data) else {
            return []
        }
        return logs
    }
    
    private func getCurrentPolicyVersion() -> String {
        return "1.0.0" // アプリバージョンまたは専用のポリシーバージョン
    }
    
    // データ収集メソッド（実装は省略）
    private func collectUserData() async throws -> UserDataExport { fatalError("Implementation needed") }
    private func collectUserPosts() async throws -> [PostExport] { fatalError("Implementation needed") }
    private func collectUserMessages() async throws -> [MessageExport] { fatalError("Implementation needed") }
    private func collectAnalyticsData() async throws -> AnalyticsExport { fatalError("Implementation needed") }
    
    // データ削除メソッド（実装は省略）
    private func deleteUserAccount() async throws { fatalError("Implementation needed") }
    private func deleteUserContent() async throws { fatalError("Implementation needed") }
    private func deleteAnalyticsData() async throws { fatalError("Implementation needed") }
    private func anonymizeBackupData() async throws { fatalError("Implementation needed") }
    
    private func clearLocalData() {
        userDefaults.removeObject(forKey: "ConsentChoices")
        userDefaults.removeObject(forKey: "PrivacySettings")
        userDefaults.removeObject(forKey: "ConsentLogs")
    }
    
    private func applyDataCorrection(_ correction: DataCorrection) async throws {
        // データ訂正の実装
    }
    
    private func generatePortableData(_ package: DataExportPackage, format: DataExportFormat) async throws -> URL {
        // ポータブルデータ生成の実装
        fatalError("Implementation needed")
    }
    
    private func getDataRetentionRules() -> [DataRetentionRule] {
        return [
            DataRetentionRule(category: .userPosts, period: .days(365)),
            DataRetentionRule(category: .analytics, period: .days(90)),
            DataRetentionRule(category: .messages, period: .days(180)),
            DataRetentionRule(category: .logs, period: .days(30))
        ]
    }
    
    private func enforceRetentionRule(_ rule: DataRetentionRule) async throws {
        // データ保持ルールの実装
    }
    
    private func adjustDataProcessing(based settings: PrivacySettings) {
        // プライバシー設定に基づくデータ処理調整
    }
}

// MARK: - Supporting Types

struct ConsentChoices: Codable {
    var analytics: Bool = false
    var marketing: Bool = false
    var personalization: Bool = false
    var thirdPartySharing: Bool = false
    var essential: Bool = true // 必須機能は常にtrue
}

struct ConsentLog: Codable {
    let timestamp: Date
    let choices: ConsentChoices
    let version: String
}

enum ConsentPurpose: String, CaseIterable {
    case analytics = "analytics"
    case marketing = "marketing"
    case personalization = "personalization"
    case thirdPartySharing = "third_party_sharing"
}

enum AgeVerificationResult {
    case verified
    case minorRequiresConsent
    case tooYoung
    case invalid
}

struct ParentalConsent: Codable {
    let parentName: String
    let parentEmail: String
    let childName: String
    let childBirthDate: Date
    let consentDate: Date
    let verificationMethod: String
}

enum DataRetentionPeriod: String, CaseIterable, Codable {
    case minimal = "minimal" // 30日
    case standard = "standard" // 1年
    case extended = "extended" // 3年
    
    var days: Int {
        switch self {
        case .minimal: return 30
        case .standard: return 365
        case .extended: return 1095
        }
    }
}

struct DataRetentionRule {
    let category: DataCategory
    let period: RetentionPeriod
    
    enum DataCategory {
        case userPosts, analytics, messages, logs
    }
    
    enum RetentionPeriod {
        case days(Int)
        case indefinite
    }
}

struct PrivacySettings: Codable {
    var profileVisibility: ProfileVisibility = .public
    var messagePrivacy: MessagePrivacy = .everyone
    var locationSharing: Bool = false
    var searchVisibility: Bool = true
    var analyticsOptOut: Bool = false
    
    enum ProfileVisibility: String, Codable, CaseIterable {
        case `public` = "public"
        case followers = "followers"
        case `private` = "private"
    }
    
    enum MessagePrivacy: String, Codable, CaseIterable {
        case everyone = "everyone"
        case followers = "followers"
        case nobody = "nobody"
    }
}

// MARK: - Data Export Types

struct DataExportPackage: Codable {
    let userData: UserDataExport
    let posts: [PostExport]
    let messages: [MessageExport]
    let analytics: AnalyticsExport
    let generatedAt: Date
}

struct UserDataExport: Codable {
    let username: String
    let email: String
    let displayName: String?
    let bio: String?
    let createdAt: Date
    let lastActive: Date
}

struct PostExport: Codable {
    let id: String
    let caption: String
    let imageURL: String?
    let location: String?
    let createdAt: Date
    let likes: Int
    let comments: [CommentExport]
}

struct CommentExport: Codable {
    let id: String
    let content: String
    let authorUsername: String
    let createdAt: Date
}

struct MessageExport: Codable {
    let id: String
    let content: String
    let conversationId: String
    let otherParticipants: [String]
    let sentAt: Date
}

struct AnalyticsExport: Codable {
    let sessionData: [SessionData]
    let featureUsage: [String: Int]
    let preferences: [String: String]
}

struct SessionData: Codable {
    let startTime: Date
    let duration: TimeInterval
    let actionsPerformed: [String]
}

enum DataExportFormat: String, CaseIterable {
    case json = "JSON"
    case csv = "CSV"
    case xml = "XML"
}

struct DataCorrection {
    let field: String
    let oldValue: String
    let newValue: String
    let reason: String
}