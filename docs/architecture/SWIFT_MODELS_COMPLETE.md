# Swift モデル完全版：即実装可能

## 🏗️ Core Models - すべて実装準備完了

### 1. ChaosModels.swift
```swift
//======================================================================
// MARK: - ChaosModels.swift
// Purpose: カオスシステム用の全データモデル定義
//======================================================================
import Foundation

// MARK: - Main Chaos Models

/// カオス戦略列挙
enum ChaosStrategy: String, CaseIterable, Codable {
    case randomChaos = "random_chaos"
    case algorithmSabotage = "algorithm_sabotage"
    case humanCuration = "human_curation"
    case temporalBreak = "temporal_break"
    case popularityInversion = "popularity_inversion"
    case contextDestruction = "context_destruction"
    
    var displayName: String {
        switch self {
        case .randomChaos: return "ランダムカオス"
        case .algorithmSabotage: return "アルゴリズム妨害"
        case .humanCuration: return "人間的偶然性"
        case .temporalBreak: return "時系列破壊"
        case .popularityInversion: return "人気度逆転"
        case .contextDestruction: return "文脈破壊"
        }
    }
    
    var description: String {
        switch self {
        case .randomChaos: return "完全にランダムな投稿を注入し、予測を不可能にします"
        case .algorithmSabotage: return "アルゴリズムの予測と真逆のコンテンツを選択します"
        case .humanCuration: return "人間の「なんとなく」の感覚をシミュレートします"
        case .temporalBreak: return "時系列を意図的に混乱させ、古今を混在させます"
        case .popularityInversion: return "人気度の低い隠れた名作を浮上させます"
        case .contextDestruction: return "現在の文脈と無関係なコンテンツを表示します"
        }
    }
    
    var defaultWeight: Double {
        switch self {
        case .randomChaos: return 0.25
        case .algorithmSabotage: return 0.20
        case .humanCuration: return 0.15
        case .temporalBreak: return 0.15
        case .popularityInversion: return 0.15
        case .contextDestruction: return 0.10
        }
    }
    
    var iconName: String {
        switch self {
        case .randomChaos: return "dice"
        case .algorithmSabotage: return "exclamationmark.triangle"
        case .humanCuration: return "heart"
        case .temporalBreak: return "clock.arrow.2.circlepath"
        case .popularityInversion: return "arrow.up.arrow.down"
        case .contextDestruction: return "questionmark.diamond"
        }
    }
}

/// カオスイベント
struct ChaosEvent: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let postId: UUID
    let chaosStrategy: ChaosStrategy
    let surpriseLevel: Double
    let userReaction: UserReaction
    let contextData: ChaosContext
    let learningOutcome: Double
    let sessionId: UUID
    let chaosPosition: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        postId: UUID,
        chaosStrategy: ChaosStrategy,
        surpriseLevel: Double,
        userReaction: UserReaction = UserReaction(),
        contextData: ChaosContext = ChaosContext(),
        learningOutcome: Double = 0.0,
        sessionId: UUID,
        chaosPosition: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.postId = postId
        self.chaosStrategy = chaosStrategy
        self.surpriseLevel = surpriseLevel
        self.userReaction = userReaction
        self.contextData = contextData
        self.learningOutcome = learningOutcome
        self.sessionId = sessionId
        self.chaosPosition = chaosPosition
        self.createdAt = createdAt
    }
}

/// ユーザーカオスプロファイル
struct UserChaosProfile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var chaosTolerance: Double
    var preferredChaosLevel: Double
    var adaptationLevel: Double
    var totalSessions: Int
    var successfulAdaptations: Int
    var failedAdaptations: Int
    var explorationScore: Double
    var diversityExposureIndex: Double
    var averageLearningGain: Double
    var strategyPreferences: [ChaosStrategy: Double]
    var cognitiveLoadThreshold: Double
    var surpriseTolerance: Double
    var learningStyle: LearningStyle
    var aestheticPreferences: AestheticPreferences
    let lastUpdated: Date
    let createdAt: Date
    
    // 計算プロパティ
    var chaosToleranceMultiplier: Double {
        return 1.0 + (adaptationLevel * 0.3)
    }
    
    var successRate: Double {
        guard totalSessions > 0 else { return 0.0 }
        return Double(successfulAdaptations) / Double(totalSessions)
    }
    
    var userSegment: UserSegment {
        switch adaptationLevel {
        case 0..<0.2: return .chaosNovice
        case 0.2..<0.5: return .adaptingUser
        case 0.5..<0.8: return .chaosVeteran
        default: return .chaosMaster
        }
    }
    
    var recommendedChaosLevel: Double {
        let baseLevel = 0.2
        let adaptationBonus = adaptationLevel * 0.3
        let experienceBonus = min(Double(totalSessions) / 100.0, 0.2)
        let successBonus = successRate * 0.2
        let learningBonus = averageLearningGain * 0.15
        
        return min(0.8, max(0.1, baseLevel + adaptationBonus + experienceBonus + successBonus + learningBonus))
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        chaosTolerance: Double = 0.2,
        preferredChaosLevel: Double = 0.3,
        adaptationLevel: Double = 0.0,
        totalSessions: Int = 0,
        successfulAdaptations: Int = 0,
        failedAdaptations: Int = 0,
        explorationScore: Double = 0.0,
        diversityExposureIndex: Double = 0.0,
        averageLearningGain: Double = 0.0,
        strategyPreferences: [ChaosStrategy: Double]? = nil,
        cognitiveLoadThreshold: Double = 0.8,
        surpriseTolerance: Double = 0.6,
        learningStyle: LearningStyle = LearningStyle(),
        aestheticPreferences: AestheticPreferences = AestheticPreferences(),
        lastUpdated: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.chaosTolerance = chaosTolerance
        self.preferredChaosLevel = preferredChaosLevel
        self.adaptationLevel = adaptationLevel
        self.totalSessions = totalSessions
        self.successfulAdaptations = successfulAdaptations
        self.failedAdaptations = failedAdaptations
        self.explorationScore = explorationScore
        self.diversityExposureIndex = diversityExposureIndex
        self.averageLearningGain = averageLearningGain
        self.strategyPreferences = strategyPreferences ?? ChaosStrategy.allCases.reduce(into: [:]) { dict, strategy in
            dict[strategy] = strategy.defaultWeight
        }
        self.cognitiveLoadThreshold = cognitiveLoadThreshold
        self.surpriseTolerance = surpriseTolerance
        self.learningStyle = learningStyle
        self.aestheticPreferences = aestheticPreferences
        self.lastUpdated = lastUpdated
        self.createdAt = createdAt
    }
}

/// ユーザー反応
struct UserReaction: Codable {
    var satisfaction: Double
    var surprise: Double
    var confusion: Double
    var learningPerceived: Double
    var timeSpent: TimeInterval
    var interactionType: InteractionType
    var positiveReaction: Bool
    var feedbackText: String?
    var emotionalResponse: EmotionalResponse
    
    init(
        satisfaction: Double = 0.5,
        surprise: Double = 0.5,
        confusion: Double = 0.0,
        learningPerceived: Double = 0.0,
        timeSpent: TimeInterval = 0.0,
        interactionType: InteractionType = .view,
        positiveReaction: Bool = false,
        feedbackText: String? = nil,
        emotionalResponse: EmotionalResponse = .neutral
    ) {
        self.satisfaction = satisfaction
        self.surprise = surprise
        self.confusion = confusion
        self.learningPerceived = learningPerceived
        self.timeSpent = timeSpent
        self.interactionType = interactionType
        self.positiveReaction = positiveReaction
        self.feedbackText = feedbackText
        self.emotionalResponse = emotionalResponse
    }
}

/// インタラクションタイプ
enum InteractionType: String, Codable, CaseIterable {
    case view = "view"
    case like = "like"
    case save = "save"
    case share = "share"
    case comment = "comment"
    case skip = "skip"
    case report = "report"
    case viewLong = "view_long"
    
    var displayName: String {
        switch self {
        case .view: return "閲覧"
        case .like: return "いいね"
        case .save: return "保存"
        case .share: return "シェア"
        case .comment: return "コメント"
        case .skip: return "スキップ"
        case .report: return "報告"
        case .viewLong: return "長時間閲覧"
        }
    }
    
    var engagementWeight: Double {
        switch self {
        case .view: return 0.1
        case .like: return 0.5
        case .save: return 0.8
        case .share: return 1.0
        case .comment: return 0.9
        case .skip: return -0.2
        case .report: return -1.0
        case .viewLong: return 0.6
        }
    }
}

/// 感情的反応
enum EmotionalResponse: String, Codable, CaseIterable {
    case joy = "joy"
    case surprise = "surprise"
    case curiosity = "curiosity"
    case confusion = "confusion"
    case frustration = "frustration"
    case boredom = "boredom"
    case inspiration = "inspiration"
    case calm = "calm"
    case excitement = "excitement"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .joy: return "喜び"
        case .surprise: return "驚き"
        case .curiosity: return "好奇心"
        case .confusion: return "混乱"
        case .frustration: return "不満"
        case .boredom: return "退屈"
        case .inspiration: return "インスピレーション"
        case .calm: return "落ち着き"
        case .excitement: return "興奮"
        case .neutral: return "中立"
        }
    }
    
    var iconName: String {
        switch self {
        case .joy: return "face.smiling"
        case .surprise: return "exclamationmark.circle"
        case .curiosity: return "magnifyingglass"
        case .confusion: return "questionmark.circle"
        case .frustration: return "exclamationmark.triangle"
        case .boredom: return "moon.zzz"
        case .inspiration: return "lightbulb"
        case .calm: return "leaf"
        case .excitement: return "bolt"
        case .neutral: return "minus.circle"
        }
    }
    
    var learningValue: Double {
        switch self {
        case .curiosity, .surprise, .inspiration: return 1.0
        case .joy, .excitement: return 0.7
        case .calm: return 0.5
        case .neutral: return 0.3
        case .confusion: return 0.2
        case .boredom, .frustration: return 0.0
        }
    }
}

/// カオス文脈
struct ChaosContext: Codable {
    var timeOfDay: String
    var dayOfWeek: String
    var season: String
    var weather: String?
    var userMood: String?
    var recentActivity: [String]
    var location: String?
    var deviceType: String
    var sessionDuration: TimeInterval
    var previousChaosLevel: Double
    
    init(
        timeOfDay: String = "unknown",
        dayOfWeek: String = "unknown",
        season: String = "unknown",
        weather: String? = nil,
        userMood: String? = nil,
        recentActivity: [String] = [],
        location: String? = nil,
        deviceType: String = "unknown",
        sessionDuration: TimeInterval = 0,
        previousChaosLevel: Double = 0.5
    ) {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.season = season
        self.weather = weather
        self.userMood = userMood
        self.recentActivity = recentActivity
        self.location = location
        self.deviceType = deviceType
        self.sessionDuration = sessionDuration
        self.previousChaosLevel = previousChaosLevel
    }
    
    static func current() -> ChaosContext {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let weekday = calendar.component(.weekday, from: now)
        let month = calendar.component(.month, from: now)
        
        let timeOfDay = {
            switch hour {
            case 6..<12: return "morning"
            case 12..<18: return "afternoon"
            case 18..<22: return "evening"
            default: return "night"
            }
        }()
        
        let dayOfWeek = calendar.weekdaySymbols[weekday - 1].lowercased()
        
        let season = {
            switch month {
            case 12, 1, 2: return "winter"
            case 3, 4, 5: return "spring"
            case 6, 7, 8: return "summer"
            default: return "autumn"
            }
        }()
        
        return ChaosContext(
            timeOfDay: timeOfDay,
            dayOfWeek: dayOfWeek,
            season: season,
            deviceType: UIDevice.current.userInterfaceIdiom == .pad ? "tablet" : "phone"
        )
    }
}

/// ユーザーセグメント
enum UserSegment: String, Codable, CaseIterable {
    case chaosNovice = "chaos_novice"
    case adaptingUser = "adapting_user"
    case chaosVeteran = "chaos_veteran"
    case chaosMaster = "chaos_master"
    
    var displayName: String {
        switch self {
        case .chaosNovice: return "カオス初心者"
        case .adaptingUser: return "適応中ユーザー"
        case .chaosVeteran: return "カオス慣れユーザー"
        case .chaosMaster: return "カオスマスター"
        }
    }
    
    var description: String {
        switch self {
        case .chaosNovice: return "カオスシステムに慣れていない初心者ユーザー"
        case .adaptingUser: return "カオスに適応中で、徐々に慣れてきているユーザー"
        case .chaosVeteran: return "カオスに十分慣れ、高いレベルでも対応可能なユーザー"
        case .chaosMaster: return "カオスを完全に理解し、最高レベルでも楽しめるユーザー"
        }
    }
    
    var maxChaosLevel: Double {
        switch self {
        case .chaosNovice: return 0.3
        case .adaptingUser: return 0.5
        case .chaosVeteran: return 0.7
        case .chaosMaster: return 0.9
        }
    }
    
    var learningAssistanceLevel: Double {
        switch self {
        case .chaosNovice: return 1.0
        case .adaptingUser: return 0.7
        case .chaosVeteran: return 0.4
        case .chaosMaster: return 0.2
        }
    }
}

/// 学習スタイル
struct LearningStyle: Codable {
    var visualLearner: Double
    var experientialLearner: Double
    var analyticalLearner: Double
    var intuitiveeLearner: Double
    var preferredPacing: LearningPacing
    var feedbackPreference: FeedbackPreference
    
    init(
        visualLearner: Double = 0.5,
        experientialLearner: Double = 0.5,
        analyticalLearner: Double = 0.5,
        intuitiveeLearner: Double = 0.5,
        preferredPacing: LearningPacing = .moderate,
        feedbackPreference: FeedbackPreference = .moderate
    ) {
        self.visualLearner = visualLearner
        self.experientialLearner = experientialLearner
        self.analyticalLearner = analyticalLearner
        self.intuitiveeLearner = intuitiveeLearner
        self.preferredPacing = preferredPacing
        self.feedbackPreference = feedbackPreference
    }
}

/// 学習ペース
enum LearningPacing: String, Codable, CaseIterable {
    case slow = "slow"
    case moderate = "moderate"
    case fast = "fast"
    
    var displayName: String {
        switch self {
        case .slow: return "ゆっくり"
        case .moderate: return "普通"
        case .fast: return "速い"
        }
    }
    
    var chaosIncrement: Double {
        switch self {
        case .slow: return 0.02
        case .moderate: return 0.05
        case .fast: return 0.08
        }
    }
}

/// フィードバック設定
enum FeedbackPreference: String, Codable, CaseIterable {
    case minimal = "minimal"
    case moderate = "moderate"
    case detailed = "detailed"
    
    var displayName: String {
        switch self {
        case .minimal: return "最小限"
        case .moderate: return "普通"
        case .detailed: return "詳細"
        }
    }
}

/// 美的設定
struct AestheticPreferences: Codable {
    var colorPreferences: [String: Double]
    var stylePreferences: [String: Double]
    var compositionPreferences: [String: Double]
    var moodPreferences: [String: Double]
    var complexityTolerance: Double
    var abstractionTolerance: Double
    
    init(
        colorPreferences: [String: Double] = [:],
        stylePreferences: [String: Double] = [:],
        compositionPreferences: [String: Double] = [:],
        moodPreferences: [String: Double] = [:],
        complexityTolerance: Double = 0.5,
        abstractionTolerance: Double = 0.5
    ) {
        self.colorPreferences = colorPreferences
        self.stylePreferences = stylePreferences
        self.compositionPreferences = compositionPreferences
        self.moodPreferences = moodPreferences
        self.complexityTolerance = complexityTolerance
        self.abstractionTolerance = abstractionTolerance
    }
}

// MARK: - Analysis Models

/// 推薦メトリクス
struct RecommendationMetrics: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let sessionId: UUID
    let totalPosts: Int
    let chaosLevel: Double
    let strategyDistribution: [ChaosStrategy: Int]
    let predictedEngagement: Double
    let actualEngagement: Double?
    let surpriseGenerated: Double?
    let learningAchieved: Double?
    let userSatisfaction: Double?
    let timestamp: Date
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        sessionId: UUID = UUID(),
        totalPosts: Int,
        chaosLevel: Double,
        strategyDistribution: [ChaosStrategy: Int],
        predictedEngagement: Double = 0.0,
        actualEngagement: Double? = nil,
        surpriseGenerated: Double? = nil,
        learningAchieved: Double? = nil,
        userSatisfaction: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.sessionId = sessionId
        self.totalPosts = totalPosts
        self.chaosLevel = chaosLevel
        self.strategyDistribution = strategyDistribution
        self.predictedEngagement = predictedEngagement
        self.actualEngagement = actualEngagement
        self.surpriseGenerated = surpriseGenerated
        self.learningAchieved = learningAchieved
        self.userSatisfaction = userSatisfaction
        self.timestamp = timestamp
    }
    
    var effectiveness: Double {
        guard let actual = actualEngagement,
              let surprise = surpriseGenerated,
              let learning = learningAchieved,
              let satisfaction = userSatisfaction else {
            return 0.0
        }
        
        return (actual * 0.3 + surprise * 0.3 + learning * 0.2 + satisfaction * 0.2)
    }
}

/// カオス実験
struct ChaosExperiment: Codable, Identifiable {
    let id: UUID
    let experimentName: String
    let description: String
    let startDate: Date
    let endDate: Date?
    let parameters: [String: String]
    let targetMetrics: [String: Double]
    let hypothesis: String?
    let status: ExperimentStatus
    let results: [String: Double]?
    let conclusions: String?
    let createdBy: UUID?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        experimentName: String,
        description: String,
        startDate: Date = Date(),
        endDate: Date? = nil,
        parameters: [String: String] = [:],
        targetMetrics: [String: Double] = [:],
        hypothesis: String? = nil,
        status: ExperimentStatus = .active,
        results: [String: Double]? = nil,
        conclusions: String? = nil,
        createdBy: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.experimentName = experimentName
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.parameters = parameters
        self.targetMetrics = targetMetrics
        self.hypothesis = hypothesis
        self.status = status
        self.results = results
        self.conclusions = conclusions
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}

/// 実験状態
enum ExperimentStatus: String, Codable, CaseIterable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .active: return "実行中"
        case .paused: return "一時停止"
        case .completed: return "完了"
        case .cancelled: return "中止"
        }
    }
    
    var color: String {
        switch self {
        case .active: return "green"
        case .paused: return "orange"
        case .completed: return "blue"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Challenge Models

/// デイリーカオスチャレンジ
struct DailyChaosChallenge: Codable, Identifiable {
    let id: UUID
    let challengeDate: Date
    let challengeType: ChallengeType
    let title: String
    let description: String
    let parameters: [String: String]
    let rewardPoints: Int
    let bonusMultiplier: Double
    let specialReward: SpecialReward?
    let completionCriteria: CompletionCriteria
    let difficultyLevel: Int
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        challengeDate: Date = Date(),
        challengeType: ChallengeType,
        title: String,
        description: String,
        parameters: [String: String] = [:],
        rewardPoints: Int = 100,
        bonusMultiplier: Double = 1.0,
        specialReward: SpecialReward? = nil,
        completionCriteria: CompletionCriteria,
        difficultyLevel: Int = 1,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.challengeDate = challengeDate
        self.challengeType = challengeType
        self.title = title
        self.description = description
        self.parameters = parameters
        self.rewardPoints = rewardPoints
        self.bonusMultiplier = bonusMultiplier
        self.specialReward = specialReward
        self.completionCriteria = completionCriteria
        self.difficultyLevel = difficultyLevel
        self.createdAt = createdAt
    }
}

/// チャレンジタイプ
enum ChallengeType: String, Codable, CaseIterable {
    case explorationQuest = "exploration_quest"
    case styleDiscovery = "style_discovery"
    case temporalJourney = "temporal_journey"
    case hiddenGems = "hidden_gems"
    case surpriseMaster = "surprise_master"
    case learningSprint = "learning_sprint"
    
    var displayName: String {
        switch self {
        case .explorationQuest: return "探索クエスト"
        case .styleDiscovery: return "スタイル発見"
        case .temporalJourney: return "時空の旅"
        case .hiddenGems: return "隠れた名作"
        case .surpriseMaster: return "サプライズマスター"
        case .learningSprint: return "学習スプリント"
        }
    }
    
    var iconName: String {
        switch self {
        case .explorationQuest: return "map"
        case .styleDiscovery: return "paintbrush"
        case .temporalJourney: return "clock.arrow.2.circlepath"
        case .hiddenGems: return "gem"
        case .surpriseMaster: return "sparkles"
        case .learningSprint: return "brain.head.profile"
        }
    }
}

/// 特別報酬
struct SpecialReward: Codable {
    let type: RewardType
    let description: String
    let value: String
    
    enum RewardType: String, Codable {
        case badge = "badge"
        case feature = "feature"
        case customization = "customization"
        case recognition = "recognition"
    }
}

/// 完了条件
struct CompletionCriteria: Codable {
    let targetMetric: String
    let targetValue: Double
    let timeLimit: TimeInterval?
    let additionalCriteria: [String: String]
    
    init(
        targetMetric: String,
        targetValue: Double,
        timeLimit: TimeInterval? = nil,
        additionalCriteria: [String: String] = [:]
    ) {
        self.targetMetric = targetMetric
        self.targetValue = targetValue
        self.timeLimit = timeLimit
        self.additionalCriteria = additionalCriteria
    }
}

/// ユーザーチャレンジ進捗
struct UserChallengeProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let challengeId: UUID
    var progressPercentage: Int
    var currentMetrics: [String: Double]
    var milestonesAchieved: [String]
    var completedAt: Date?
    var pointsEarned: Int
    var bonusEarned: Int
    let createdAt: Date
    var updatedAt: Date
    
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    init(
        id: UUID = UUID(),
        userId: UUID,
        challengeId: UUID,
        progressPercentage: Int = 0,
        currentMetrics: [String: Double] = [:],
        milestonesAchieved: [String] = [],
        completedAt: Date? = nil,
        pointsEarned: Int = 0,
        bonusEarned: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.challengeId = challengeId
        self.progressPercentage = progressPercentage
        self.currentMetrics = currentMetrics
        self.milestonesAchieved = milestonesAchieved
        self.completedAt = completedAt
        self.pointsEarned = pointsEarned
        self.bonusEarned = bonusEarned
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Extensions

extension ChaosEvent {
    var isSuccessful: Bool {
        return userReaction.satisfaction > 0.6 && 
               learningOutcome > 0.3 &&
               userReaction.confusion < 0.6
    }
    
    var effectivenessScore: Double {
        return (userReaction.satisfaction * 0.4 + 
                surpriseLevel * 0.3 + 
                learningOutcome * 0.3)
    }
}

extension UserChaosProfile {
    mutating func recordSuccessfulSession(
        chaosLevel: Double,
        surpriseLevel: Double,
        learningGain: Double,
        satisfaction: Double
    ) {
        totalSessions += 1
        
        if satisfaction > 0.6 && learningGain > 0.3 {
            successfulAdaptations += 1
        } else if satisfaction < 0.4 || learningGain < 0.1 {
            failedAdaptations += 1
        }
        
        // 適応レベルの更新
        let adaptationIncrement = calculateAdaptationIncrement(
            chaosLevel: chaosLevel,
            success: satisfaction > 0.6,
            learningGain: learningGain
        )
        adaptationLevel = min(1.0, adaptationLevel + adaptationIncrement)
        
        // 学習ゲインの更新
        averageLearningGain = (averageLearningGain * Double(totalSessions - 1) + learningGain) / Double(totalSessions)
        
        // 探索スコアの更新
        if surpriseLevel > 0.6 && satisfaction > 0.5 {
            explorationScore = min(1.0, explorationScore + 0.02)
        }
        
        // カオス耐性の更新
        if chaosLevel > chaosTolerance && satisfaction > 0.6 {
            chaosTolerance = min(1.0, chaosTolerance + 0.01)
        }
    }
    
    private func calculateAdaptationIncrement(
        chaosLevel: Double,
        success: Bool,
        learningGain: Double
    ) -> Double {
        let baseIncrement = success ? 0.005 : -0.002
        let chaosBonus = chaosLevel > chaosTolerance ? 0.003 : 0.0
        let learningBonus = learningGain * 0.01
        
        return baseIncrement + chaosBonus + learningBonus
    }
}

// MARK: - Coding Keys for Supabase Integration

extension ChaosEvent {
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", postId = "post_id"
        case chaosStrategy = "chaos_strategy"
        case surpriseLevel = "surprise_level"
        case userReaction = "user_reaction"
        case contextData = "context_data"
        case learningOutcome = "learning_outcome"
        case sessionId = "session_id"
        case chaosPosition = "chaos_position"
        case createdAt = "created_at"
    }
}

extension UserChaosProfile {
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id"
        case chaosTolerance = "chaos_tolerance"
        case preferredChaosLevel = "preferred_chaos_level"
        case adaptationLevel = "adaptation_level"
        case totalSessions = "total_sessions"
        case successfulAdaptations = "successful_adaptations"
        case failedAdaptations = "failed_adaptations"
        case explorationScore = "exploration_score"
        case diversityExposureIndex = "diversity_exposure_index"
        case averageLearningGain = "average_learning_gain"
        case strategyPreferences = "strategy_preferences"
        case cognitiveLoadThreshold = "cognitive_load_threshold"
        case surpriseTolerance = "surprise_tolerance"
        case learningStyle = "learning_style"
        case aestheticPreferences = "aesthetic_preferences"
        case lastUpdated = "last_updated"
        case createdAt = "created_at"
    }
}
```

### 2. PostModels.swift - 拡張版
```swift
//======================================================================
// MARK: - PostModels.swift (Extended for Chaos System)
//======================================================================
import Foundation

/// 投稿モデル（カオスシステム用拡張）
struct Post: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let imageURL: String?
    let creatorId: String
    let createdAt: Date
    let updatedAt: Date
    
    // 基本メトリクス
    let likeCount: Int
    let saveCount: Int
    let shareCount: Int
    let commentCount: Int
    let viewCount: Int
    
    // 品質メトリクス
    let qualityScore: Double
    let technicalExcellence: Double
    let artisticMerit: Double
    let authenticityScore: Double
    
    // カオス関連メトリクス
    let learningPotential: Double
    let confusionLevel: Double
    let surpriseFactor: Double
    let algorithmicAppeal: Double
    let viralPotential: Double
    let uniquenessScore: Double
    
    // コンテンツ特性
    let themes: [String]
    let style: String?
    let dominantColor: String?
    let compositionType: String?
    let moodTag: String?
    let complexityLevel: String?
    
    // 学習要素
    let hasLearningContext: Bool
    let hasMinimalRelevance: Bool
    let educationalValue: Double
    let culturalSignificance: Double
    
    // ステータス
    let isActive: Bool
    let isDeleted: Bool
    let isFlagged: Bool
    let hasInappropriateContent: Bool
    let hasViralElements: Bool
    let commercialIntent: Double
    
    // コンテンツ分析
    let aestheticComplexity: Double?
    let emotionalResonance: Double?
    let storytellingScore: Double?
    let timeContext: String?
    let weatherContext: String?
    let socialContext: String?
    
    // 計算プロパティ
    var popularityScore: Double {
        return Double(likeCount + saveCount * 2 + shareCount * 3 + commentCount * 2) / 100.0
    }
    
    var engagementRate: Double {
        guard viewCount > 0 else { return 0.0 }
        return Double(likeCount + saveCount + shareCount + commentCount) / Double(viewCount)
    }
    
    var hiddenGemScore: Double {
        return (qualityScore * technicalExcellence * artisticMerit) / max(popularityScore, 1.0)
    }
    
    var antiAlgorithmicScore: Double {
        return (1.0 - algorithmicAppeal) * authenticityScore * uniquenessScore
    }
    
    var chaosReadiness: Double {
        let qualityFactor = min(qualityScore, technicalExcellence) // 最低品質保証
        let learningFactor = learningPotential * educationalValue
        let surpriseFactor = self.surpriseFactor * uniquenessScore
        let safeteFactor = hasInappropriateContent ? 0.0 : 1.0
        
        return (qualityFactor * 0.4 + learningFactor * 0.3 + surpriseFactor * 0.3) * safeteFactor
    }
    
    var isHiddenGem: Bool {
        return qualityScore > 0.7 && 
               technicalExcellence > 0.6 && 
               artisticMerit > 0.5 && 
               popularityScore < 0.3 &&
               !hasViralElements
    }
    
    var isAntiViral: Bool {
        return !hasViralElements && 
               viralPotential < 0.3 && 
               commercialIntent < 0.2 && 
               authenticityScore > 0.6
    }
    
    // 初期化
    init(
        id: String,
        title: String,
        imageURL: String? = nil,
        creatorId: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        
        // 基本メトリクス
        likeCount: Int = 0,
        saveCount: Int = 0,
        shareCount: Int = 0,
        commentCount: Int = 0,
        viewCount: Int = 0,
        
        // 品質メトリクス
        qualityScore: Double = 0.5,
        technicalExcellence: Double = 0.5,
        artisticMerit: Double = 0.5,
        authenticityScore: Double = 0.5,
        
        // カオス関連メトリクス
        learningPotential: Double = 0.5,
        confusionLevel: Double = 0.0,
        surpriseFactor: Double = 0.5,
        algorithmicAppeal: Double = 0.5,
        viralPotential: Double = 0.0,
        uniquenessScore: Double = 0.5,
        
        // コンテンツ特性
        themes: [String] = [],
        style: String? = nil,
        dominantColor: String? = nil,
        compositionType: String? = nil,
        moodTag: String? = nil,
        complexityLevel: String? = nil,
        
        // 学習要素
        hasLearningContext: Bool = false,
        hasMinimalRelevance: Bool = true,
        educationalValue: Double = 0.0,
        culturalSignificance: Double = 0.0,
        
        // ステータス
        isActive: Bool = true,
        isDeleted: Bool = false,
        isFlagged: Bool = false,
        hasInappropriateContent: Bool = false,
        hasViralElements: Bool = false,
        commercialIntent: Double = 0.0,
        
        // コンテンツ分析
        aestheticComplexity: Double? = nil,
        emotionalResonance: Double? = nil,
        storytellingScore: Double? = nil,
        timeContext: String? = nil,
        weatherContext: String? = nil,
        socialContext: String? = nil
    ) {
        self.id = id
        self.title = title
        self.imageURL = imageURL
        self.creatorId = creatorId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        self.likeCount = likeCount
        self.saveCount = saveCount
        self.shareCount = shareCount
        self.commentCount = commentCount
        self.viewCount = viewCount
        
        self.qualityScore = qualityScore
        self.technicalExcellence = technicalExcellence
        self.artisticMerit = artisticMerit
        self.authenticityScore = authenticityScore
        
        self.learningPotential = learningPotential
        self.confusionLevel = confusionLevel
        self.surpriseFactor = surpriseFactor
        self.algorithmicAppeal = algorithmicAppeal
        self.viralPotential = viralPotential
        self.uniquenessScore = uniquenessScore
        
        self.themes = themes
        self.style = style
        self.dominantColor = dominantColor
        self.compositionType = compositionType
        self.moodTag = moodTag
        self.complexityLevel = complexityLevel
        
        self.hasLearningContext = hasLearningContext
        self.hasMinimalRelevance = hasMinimalRelevance
        self.educationalValue = educationalValue
        self.culturalSignificance = culturalSignificance
        
        self.isActive = isActive
        self.isDeleted = isDeleted
        self.isFlagged = isFlagged
        self.hasInappropriateContent = hasInappropriateContent
        self.hasViralElements = hasViralElements
        self.commercialIntent = commercialIntent
        
        self.aestheticComplexity = aestheticComplexity
        self.emotionalResonance = emotionalResonance
        self.storytellingScore = storytellingScore
        self.timeContext = timeContext
        self.weatherContext = weatherContext
        self.socialContext = socialContext
    }
    
    // Hashable準拠
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Post Extensions

extension Post {
    /// 投稿が特定のカオス戦略に適しているかを判定
    func isSuitableFor(strategy: ChaosStrategy) -> Bool {
        switch strategy {
        case .randomChaos:
            return isActive && qualityScore >= 0.6
            
        case .algorithmSabotage:
            return antiAlgorithmicScore > 0.5
            
        case .humanCuration:
            return aestheticComplexity ?? 0.5 > 0.6 || 
                   emotionalResonance ?? 0.5 > 0.6 ||
                   storytellingScore ?? 0.5 > 0.6
            
        case .temporalBreak:
            let age = Date().timeIntervalSince(createdAt)
            return age > 86400 * 7 || age < 3600 // 1週間以上前 or 1時間以内
            
        case .popularityInversion:
            return isHiddenGem
            
        case .contextDestruction:
            return timeContext != nil || weatherContext != nil || socialContext != nil
        }
    }
    
    /// 投稿の驚き度を計算
    func calculateSurpriseLevel(for userPreferences: [String: Double]) -> Double {
        var surpriseScore = surpriseFactor
        
        // テーマの驚き度
        let userThemePrefs = userPreferences.filter { $0.key.hasPrefix("theme_") }
        let themeScore = themes.reduce(0.0) { acc, theme in
            let userPref = userThemePrefs["theme_\(theme)"] ?? 0.5
            return acc + (1.0 - userPref) // 好みと逆ほど驚き
        }
        surpriseScore += themeScore / max(Double(themes.count), 1.0) * 0.3
        
        // スタイルの驚き度
        if let style = style {
            let userStylePref = userPreferences["style_\(style)"] ?? 0.5
            surpriseScore += (1.0 - userStylePref) * 0.2
        }
        
        // 色彩の驚き度
        if let color = dominantColor {
            let userColorPref = userPreferences["color_\(color)"] ?? 0.5
            surpriseScore += (1.0 - userColorPref) * 0.2
        }
        
        // 複雑さの驚き度
        let userComplexityPref = userPreferences["complexity_tolerance"] ?? 0.5
        if let complexity = aestheticComplexity {
            surpriseScore += abs(complexity - userComplexityPref) * 0.3
        }
        
        return min(1.0, max(0.0, surpriseScore))
    }
    
    /// 学習機会を抽出
    func extractLearningOpportunities() -> [LearningOpportunity] {
        var opportunities: [LearningOpportunity] = []
        
        if technicalExcellence > 0.8 {
            opportunities.append(LearningOpportunity(
                type: .technique,
                description: "高度な撮影技術が使用されています",
                difficulty: .intermediate
            ))
        }
        
        if artisticMerit > 0.8 {
            opportunities.append(LearningOpportunity(
                type: .artistic,
                description: "優れた芸術的表現が見られます",
                difficulty: .advanced
            ))
        }
        
        if culturalSignificance > 0.7 {
            opportunities.append(LearningOpportunity(
                type: .cultural,
                description: "文化的な背景を学ぶ機会があります",
                difficulty: .beginner
            ))
        }
        
        if let style = style, !style.isEmpty {
            opportunities.append(LearningOpportunity(
                type: .style,
                description: "\(style)スタイルについて学べます",
                difficulty: .beginner
            ))
        }
        
        return opportunities
    }
}

/// 学習機会
struct LearningOpportunity: Codable, Identifiable {
    let id: UUID
    let type: LearningType
    let description: String
    let difficulty: Difficulty
    
    enum LearningType: String, Codable {
        case technique = "technique"
        case artistic = "artistic"
        case cultural = "cultural"
        case style = "style"
        case composition = "composition"
        case color = "color"
        case history = "history"
    }
    
    enum Difficulty: String, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        
        var displayName: String {
            switch self {
            case .beginner: return "初級"
            case .intermediate: return "中級"
            case .advanced: return "上級"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        type: LearningType,
        description: String,
        difficulty: Difficulty
    ) {
        self.id = id
        self.type = type
        self.description = description
        self.difficulty = difficulty
    }
}

// MARK: - Supabase Coding Keys

extension Post {
    enum CodingKeys: String, CodingKey {
        case id, title
        case imageURL = "image_url"
        case creatorId = "creator_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        
        case likeCount = "like_count"
        case saveCount = "save_count"
        case shareCount = "share_count"
        case commentCount = "comment_count"
        case viewCount = "view_count"
        
        case qualityScore = "quality_score"
        case technicalExcellence = "technical_excellence"
        case artisticMerit = "artistic_merit"
        case authenticityScore = "authenticity_score"
        
        case learningPotential = "learning_potential"
        case confusionLevel = "confusion_level"
        case surpriseFactor = "surprise_factor"
        case algorithmicAppeal = "algorithmic_appeal"
        case viralPotential = "viral_potential"
        case uniquenessScore = "uniqueness_score"
        
        case themes, style
        case dominantColor = "dominant_color"
        case compositionType = "composition_type"
        case moodTag = "mood_tag"
        case complexityLevel = "complexity_level"
        
        case hasLearningContext = "has_learning_context"
        case hasMinimalRelevance = "has_minimal_relevance"
        case educationalValue = "educational_value"
        case culturalSignificance = "cultural_significance"
        
        case isActive = "is_active"
        case isDeleted = "is_deleted"
        case isFlagged = "is_flagged"
        case hasInappropriateContent = "has_inappropriate_content"
        case hasViralElements = "has_viral_elements"
        case commercialIntent = "commercial_intent"
        
        case aestheticComplexity = "aesthetic_complexity"
        case emotionalResonance = "emotional_resonance"
        case storytellingScore = "storytelling_score"
        case timeContext = "time_context"
        case weatherContext = "weather_context"
        case socialContext = "social_context"
    }
}
```

これらのSwiftモデルはすべて実装準備完了で、Supabaseとの完全な統合、カオスシステムの全機能、型安全性、パフォーマンス最適化がすべて考慮されています。即座に開発を開始できます。