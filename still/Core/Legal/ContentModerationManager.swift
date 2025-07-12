//======================================================================
// MARK: - ContentModerationManager.swift
// Purpose: Manager class for system operations (ContentModerationManagerのシステム操作管理クラス)
// Path: still/Core/Legal/ContentModerationManager.swift
//======================================================================
//
//  ContentModerationManager.swift
//  tete
//
//  コンテンツモデレーションと年齢制限システム
//

import Foundation
import SwiftUI
@preconcurrency import Vision
import CoreML

// MARK: - Enums
enum RestrictionReason: String, Codable {
    case inappropriate = "inappropriate"
    case ageRestricted = "age_restricted"
    case violatesGuidelines = "violates_guidelines"
    case reported = "reported"
    case temporaryBan = "temporary_ban"
    case permanentBan = "permanent_ban"
}

// MARK: - Content Moderation Manager
@MainActor
final class ContentModerationManager: ObservableObject {
    
    static let shared = ContentModerationManager()
    
    // MARK: - Published Properties
    @Published var moderationQueue: [ModerationItem] = []
    @Published var bannedUsers: Set<String> = []
    @Published var restrictedContent: [String: RestrictionReason] = [:]
    
    // MARK: - Private Properties
    private let imageAnalyzer = VNImageRequestHandler(cgImage: UIImage().cgImage!)
    private var contentClassifier: VNCoreMLModel?
    
    // MARK: - Initialization
    private init() {
        setupContentClassifier()
        loadModerationData()
    }
    
    // MARK: - Content Analysis
    
    /// 画像コンテンツの分析
    @MainActor
    func analyzeImage(_ image: UIImage) async -> ContentAnalysisResult {
        return await withCheckedContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(returning: ContentAnalysisResult(
                    isAppropriate: false,
                    confidence: 0.0,
                    flags: [.technicalError],
                    ageRating: .mature
                ))
                return
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            var analysisResult = ContentAnalysisResult(
                isAppropriate: true,
                confidence: 1.0,
                flags: [],
                ageRating: .general
            )
            
            // 1. 成人向けコンテンツの検出
            let adultContentRequest = VNClassifyImageRequest { request, error in
                if let results = request.results as? [VNClassificationObservation] {
                    for result in results {
                        if result.identifier.contains("explicit") && result.confidence > 0.7 {
                            analysisResult.flags.append(.explicitContent)
                            analysisResult.ageRating = .mature
                            analysisResult.isAppropriate = false
                        }
                    }
                }
            }
            
            // 2. テキスト検出（画像内のテキスト）
            let textRequest = VNRecognizeTextRequest { request, error in
                if let results = request.results as? [VNRecognizedTextObservation] {
                    for result in results {
                        if let text = result.topCandidates(1).first?.string {
                            let textAnalysis = self.analyzeTextContent(text)
                            if !textAnalysis.isAppropriate {
                                analysisResult.flags.append(contentsOf: textAnalysis.flags)
                                analysisResult.isAppropriate = false
                            }
                        }
                    }
                }
            }
            
            // 3. 顔検出（プライバシー保護）
            let faceRequest = VNDetectFaceRectanglesRequest { request, error in
                if let results = request.results as? [VNFaceObservation], results.count > 5 {
                    analysisResult.flags.append(.multiplePersons)
                    analysisResult.requiresReview = true
                }
            }
            
            // リクエストを実行
            Task { @MainActor in
                do {
                    try handler.perform([adultContentRequest, textRequest, faceRequest])
                    
                    // 機械学習モデルによる追加分析
                    if let classifier = self.contentClassifier {
                        let classificationRequest = VNCoreMLRequest(model: classifier) { request, error in
                            if let results = request.results as? [VNClassificationObservation] {
                                for result in results {
                                    if result.identifier == "inappropriate" && result.confidence > 0.8 {
                                        analysisResult.flags.append(.inappropriateContent)
                                        analysisResult.isAppropriate = false
                                    }
                                }
                            }
                        }
                        try handler.perform([classificationRequest])
                    }
                    
                    // 最終的な信頼度を計算
                    analysisResult.confidence = self.calculateConfidence(for: analysisResult)
                    
                    continuation.resume(returning: analysisResult)
                    
                } catch {
                    analysisResult.flags.append(.technicalError)
                    analysisResult.isAppropriate = false
                    continuation.resume(returning: analysisResult)
                }
            }
        }
    }
    
    /// テキストコンテンツの分析
    func analyzeTextContent(_ text: String) -> ContentAnalysisResult {
        var flags: [ContentFlag] = []
        var isAppropriate = true
        var ageRating: AgeRating = .general
        
        let lowercaseText = text.lowercased()
        
        // 1. 不適切な言葉の検出
        let inappropriateWords = getInappropriateWords()
        for word in inappropriateWords {
            if lowercaseText.contains(word.lowercased()) {
                flags.append(.inappropriateLanguage)
                isAppropriate = false
                ageRating = .mature
                break
            }
        }
        
        // 2. ヘイトスピーチの検出
        let hateWords = getHateWords()
        for word in hateWords {
            if lowercaseText.contains(word.lowercased()) {
                flags.append(.hateSpeech)
                isAppropriate = false
                ageRating = .mature
                break
            }
        }
        
        // 3. スパムの検出
        if isSpamContent(text) {
            flags.append(.spam)
            isAppropriate = false
        }
        
        // 4. 個人情報の検出
        if containsPersonalInfo(text) {
            flags.append(.personalInformation)
            ageRating = .teen
        }
        
        return ContentAnalysisResult(
            isAppropriate: isAppropriate,
            confidence: 0.9,
            flags: flags,
            ageRating: ageRating
        )
    }
    
    // MARK: - Age Verification
    
    /// 年齢制限の確認
    func checkAgeRestriction(content: ContentAnalysisResult, userAge: Int?) -> Bool {
        guard let userAge = userAge else {
            // 年齢不明の場合は最も厳しい制限を適用
            return content.ageRating == .general
        }
        
        switch content.ageRating {
        case .general:
            return true
        case .teen:
            return userAge >= 13
        case .mature:
            return userAge >= 18
        }
    }
    
    /// 保護者による制限設定
    func applyParentalControls(_ controls: ParentalControls, userId: String) {
        let controlsData = try? JSONEncoder().encode(controls)
        UserDefaults.standard.set(controlsData, forKey: "ParentalControls_\(userId)")
        
        print("👨‍👩‍👧‍👦 Parental controls applied for user: \(userId)")
    }
    
    /// コンテンツフィルタの適用
    func shouldFilterContent(_ content: ContentAnalysisResult, for userId: String) -> Bool {
        // 保護者による制限を確認
        if let controlsData = UserDefaults.standard.data(forKey: "ParentalControls_\(userId)"),
           let controls = try? JSONDecoder().decode(ParentalControls.self, from: controlsData) {
            
            // 制限レベルに基づく判定
            switch controls.restrictionLevel {
            case .none:
                return false
            case .light:
                return content.flags.contains(.explicitContent) || content.flags.contains(.hateSpeech)
            case .moderate:
                return !content.isAppropriate || content.ageRating == .mature
            case .strict:
                return content.ageRating != .general
            }
        }
        
        // デフォルトは成人向けコンテンツのみフィルタ
        return content.flags.contains(.explicitContent)
    }
    
    // MARK: - Moderation Actions
    
    /// コンテンツの報告処理
    func reportContent(_ contentId: String, reason: ReportReason, reporterId: String) {
        let report = ContentReport(
            id: UUID().uuidString,
            contentId: contentId,
            reporterId: reporterId,
            reason: reason,
            timestamp: Date(),
            status: .pending
        )
        
        addToModerationQueue(report)
        
        // 緊急度の高い報告は即座に処理
        if reason == .illegalContent || reason == .harmToMinors {
            Task {
                await processUrgentReport(report)
            }
        }
        
        print("🚨 Content reported: \(contentId) for \(reason)")
    }
    
    /// 自動モデレーション
    func automaticModeration(_ content: PostContent) async -> ModerationDecision {
        // 画像分析
        var imageAnalysis: ContentAnalysisResult?
        if let image = content.image {
            imageAnalysis = await analyzeImage(image)
        }
        
        // テキスト分析
        let textAnalysis = analyzeTextContent(content.caption)
        
        // 総合判定
        let overallAppropriate = (imageAnalysis?.isAppropriate ?? true) && textAnalysis.isAppropriate
        
        if !overallAppropriate {
            // 自動削除の基準
            let shouldAutoRemove = hasAutoRemoveFlags(imageAnalysis, textAnalysis)
            
            if shouldAutoRemove {
                return .remove(reason: "Automatic moderation: inappropriate content")
            } else {
                return .requiresReview(priority: .high)
            }
        }
        
        return .approve
    }
    
    /// ユーザーの警告・制裁
    func issueWarning(to userId: String, reason: String) {
        let warning = UserWarning(
            userId: userId,
            reason: reason,
            timestamp: Date(),
            severity: .warning
        )
        
        saveUserWarning(warning)
        
        // 警告履歴の確認
        let warningCount = getUserWarningCount(userId)
        
        if warningCount >= 3 {
            // 3回警告で一時停止
            suspendUser(userId, duration: .days(7), reason: "Multiple violations")
        }
        
        print("⚠️ Warning issued to user: \(userId)")
    }
    
    /// ユーザーの一時停止
    func suspendUser(_ userId: String, duration: SuspensionDuration, reason: String) {
        let suspension = UserSuspension(
            userId: userId,
            reason: reason,
            startDate: Date(),
            endDate: Date().addingTimeInterval(duration.timeInterval),
            isActive: true
        )
        
        saveUserSuspension(suspension)
        print("🚫 User suspended: \(userId) for \(duration)")
    }
    
    /// ユーザーの永久停止
    func banUser(_ userId: String, reason: String) {
        bannedUsers.insert(userId)
        
        let ban = UserBan(
            userId: userId,
            reason: reason,
            timestamp: Date(),
            isActive: true
        )
        
        saveUserBan(ban)
        print("🔨 User banned: \(userId)")
    }
    
    // MARK: - AI-Powered Moderation
    
    /// 文脈を理解した高度なモデレーション
    func advancedContentAnalysis(_ content: PostContent) async -> AdvancedAnalysisResult {
        // 複数の機械学習モデルを組み合わせた分析
        var analysisResults: [String: Any] = [:]
        
        // 1. 感情分析
        let sentimentScore = analyzeSentiment(content.caption)
        analysisResults["sentiment"] = sentimentScore
        
        // 2. トピック分類
        let topics = classifyTopics(content.caption)
        analysisResults["topics"] = topics
        
        // 3. 画像の文脈理解
        if let image = content.image {
            let imageContext = await analyzeImageContext(image)
            analysisResults["imageContext"] = imageContext
        }
        
        // 4. ユーザー行動パターン分析
        let userPattern = analyzeUserBehavior(content.authorId)
        analysisResults["userPattern"] = userPattern
        
        return AdvancedAnalysisResult(
            confidence: 0.85,
            riskScore: calculateRiskScore(analysisResults),
            recommendations: generateRecommendations(analysisResults),
            details: analysisResults
        )
    }
    
    // MARK: - Community Guidelines
    
    /// コミュニティガイドライン違反の検出
    func checkCommunityGuidelines(_ content: PostContent) -> [GuidelineViolation] {
        var violations: [GuidelineViolation] = []
        
        // 1. スパム・宣伝
        if isCommercialSpam(content.caption) {
            violations.append(.commercialSpam)
        }
        
        // 2. 著作権侵害の可能性
        if containsCopyrightedContent(content) {
            violations.append(.copyrightInfringement)
        }
        
        // 3. 暴力的コンテンツ
        if containsViolentContent(content) {
            violations.append(.violence)
        }
        
        // 4. 自傷行為の促進
        if promotesSelfHarm(content.caption) {
            violations.append(.selfHarmPromotion)
        }
        
        return violations
    }
    
    // MARK: - Private Methods
    
    private func setupContentClassifier() {
        // Core MLモデルの初期化（実際のモデルファイルが必要）
        // contentClassifier = try? VNCoreMLModel(for: ContentClassifierModel().model)
    }
    
    private func loadModerationData() {
        // 過去のモデレーションデータの読み込み
        if let bannedData = UserDefaults.standard.data(forKey: "BannedUsers"),
           let banned = try? JSONDecoder().decode(Set<String>.self, from: bannedData) {
            bannedUsers = banned
        }
    }
    
    private func getInappropriateWords() -> [String] {
        // 実際の実装では外部ファイルまたはサーバーから取得
        return ["badword1", "badword2", "inappropriate"]
    }
    
    private func getHateWords() -> [String] {
        // ヘイトスピーチ関連の単語リスト
        return ["hate1", "hate2", "discriminatory"]
    }
    
    private func isSpamContent(_ text: String) -> Bool {
        // スパム検出ロジック
        let spamIndicators = ["click here", "free money", "limited time"]
        return spamIndicators.contains { text.lowercased().contains($0) }
    }
    
    private func containsPersonalInfo(_ text: String) -> Bool {
        // 個人情報検出（メールアドレス、電話番号など）
        let emailRegex = try? NSRegularExpression(pattern: "[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", options: .caseInsensitive)
        return emailRegex?.firstMatch(in: text, range: NSRange(location: 0, length: text.count)) != nil
    }
    
    private func calculateConfidence(for result: ContentAnalysisResult) -> Double {
        var confidence = 1.0
        
        // フラグの数に基づいて信頼度を調整
        confidence -= Double(result.flags.count) * 0.1
        
        return max(0.1, confidence)
    }
    
    private func addToModerationQueue(_ report: ContentReport) {
        let item = ModerationItem(
            id: report.id,
            type: .userReport,
            contentId: report.contentId,
            priority: getPriority(for: report.reason),
            timestamp: report.timestamp
        )
        
        moderationQueue.append(item)
        moderationQueue.sort { $0.priority.rawValue < $1.priority.rawValue }
    }
    
    private func getPriority(for reason: ReportReason) -> ModerationPriority {
        switch reason {
        case .illegalContent, .harmToMinors:
            return .urgent
        case .hateSpeech, .harassment:
            return .high
        case .spam, .inappropriateContent:
            return .medium
        default:
            return .low
        }
    }
    
    private func processUrgentReport(_ report: ContentReport) async {
        // 緊急報告の即座処理
        print("🚨 Processing urgent report: \(report.id)")
    }
    
    private func hasAutoRemoveFlags(_ imageAnalysis: ContentAnalysisResult?, _ textAnalysis: ContentAnalysisResult) -> Bool {
        let dangerousFlags: [ContentFlag] = [.explicitContent, .hateSpeech, .harmToMinors]
        
        let imageFlags = imageAnalysis?.flags ?? []
        let textFlags = textAnalysis.flags
        
        return dangerousFlags.contains { imageFlags.contains($0) || textFlags.contains($0) }
    }
    
    // その他のプライベートメソッド（実装省略）
    private func saveUserWarning(_ warning: UserWarning) { /* 実装 */ }
    private func getUserWarningCount(_ userId: String) -> Int { return 0 }
    private func saveUserSuspension(_ suspension: UserSuspension) { /* 実装 */ }
    private func saveUserBan(_ ban: UserBan) { /* 実装 */ }
    private func analyzeSentiment(_ text: String) -> Double { return 0.0 }
    private func classifyTopics(_ text: String) -> [String] { return [] }
    private func analyzeImageContext(_ image: UIImage) async -> [String: Any] { return [:] }
    private func analyzeUserBehavior(_ userId: String) -> [String: Any] { return [:] }
    private func calculateRiskScore(_ results: [String: Any]) -> Double { return 0.0 }
    private func generateRecommendations(_ results: [String: Any]) -> [String] { return [] }
    private func isCommercialSpam(_ text: String) -> Bool { return false }
    private func containsCopyrightedContent(_ content: PostContent) -> Bool { return false }
    private func containsViolentContent(_ content: PostContent) -> Bool { return false }
    private func promotesSelfHarm(_ text: String) -> Bool { return false }
}

// MARK: - Supporting Types

struct ContentAnalysisResult {
    var isAppropriate: Bool
    var confidence: Double
    var flags: [ContentFlag]
    var ageRating: AgeRating
    var requiresReview: Bool = false
}

enum ContentFlag {
    case explicitContent
    case inappropriateLanguage
    case hateSpeech
    case spam
    case personalInformation
    case violence
    case inappropriateContent
    case multiplePersons
    case harmToMinors
    case technicalError
}

enum AgeRating {
    case general    // 全年齢
    case teen      // 13歳以上
    case mature    // 18歳以上
}

struct ParentalControls: Codable {
    let restrictionLevel: RestrictionLevel
    let allowedCategories: [ContentCategory]
    let timeRestrictions: TimeRestrictions?
    let blockedUsers: [String]
    
    enum RestrictionLevel: String, Codable, CaseIterable {
        case none = "none"
        case light = "light"
        case moderate = "moderate"
        case strict = "strict"
    }
}

enum ContentCategory: String, Codable, CaseIterable {
    case food = "food"
    case travel = "travel"
    case nature = "nature"
    case art = "art"
    case lifestyle = "lifestyle"
}

struct TimeRestrictions: Codable {
    let dailyLimit: TimeInterval // 1日の利用時間制限
    let allowedHours: [Int] // 利用可能時間帯
    let blockNighttime: Bool // 夜間利用制限
}

enum ReportReason: String, Codable, CaseIterable {
    case inappropriateContent = "inappropriate"
    case spam = "spam"
    case harassment = "harassment"
    case hateSpeech = "hate_speech"
    case violence = "violence"
    case illegalContent = "illegal"
    case copyrightInfringement = "copyright"
    case harmToMinors = "harm_minors"
    case personalInformation = "personal_info"
    case other = "other"
}

struct ContentReport: Codable {
    let id: String
    let contentId: String
    let reporterId: String
    let reason: ReportReason
    let timestamp: Date
    var status: ReportStatus
    
    enum ReportStatus: String, Codable {
        case pending = "pending"
        case reviewed = "reviewed"
        case resolved = "resolved"
        case dismissed = "dismissed"
    }
}

struct ModerationItem {
    let id: String
    let type: ModerationType
    let contentId: String
    let priority: ModerationPriority
    let timestamp: Date
    
    enum ModerationType {
        case automaticFlag
        case userReport
        case algorithmicDetection
    }
}

enum ModerationPriority: Int, CaseIterable {
    case urgent = 1
    case high = 2
    case medium = 3
    case low = 4
}

enum ModerationDecision {
    case approve
    case remove(reason: String)
    case requiresReview(priority: ModerationPriority)
    case shadowBan
}

struct UserWarning: Codable {
    let userId: String
    let reason: String
    let timestamp: Date
    let severity: Severity
    
    enum Severity: String, Codable {
        case warning = "warning"
        case serious = "serious"
        case final = "final"
    }
}

struct UserSuspension: Codable {
    let userId: String
    let reason: String
    let startDate: Date
    let endDate: Date
    var isActive: Bool
}

struct UserBan: Codable {
    let userId: String
    let reason: String
    let timestamp: Date
    var isActive: Bool
}

enum SuspensionDuration {
    case hours(Int)
    case days(Int)
    case weeks(Int)
    case permanent
    
    var timeInterval: TimeInterval {
        switch self {
        case .hours(let h): return TimeInterval(h * 3600)
        case .days(let d): return TimeInterval(d * 24 * 3600)
        case .weeks(let w): return TimeInterval(w * 7 * 24 * 3600)
        case .permanent: return TimeInterval.greatestFiniteMagnitude
        }
    }
}

struct PostContent {
    let authorId: String
    let caption: String
    let image: UIImage?
    let location: String?
    let hashtags: [String]
}

struct AdvancedAnalysisResult {
    let confidence: Double
    let riskScore: Double
    let recommendations: [String]
    let details: [String: Any]
}

enum GuidelineViolation {
    case commercialSpam
    case copyrightInfringement
    case violence
    case selfHarmPromotion
    case harassment
    case impersonation
}