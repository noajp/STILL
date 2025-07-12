//======================================================================
// MARK: - SecureLogger
// Purpose: セキュアなログ管理システム（機密情報の自動マスキング）
// Usage: SecureLogger.shared.info("message"), SecureLogger.shared.authEvent("login", userID: "123")
//======================================================================
import Foundation
import os.log

/// セキュアなログ管理システム
final class SecureLogger: @unchecked Sendable {
    static let shared = SecureLogger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.tete"
    private let generalLogger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.tete", category: "general")
    private let securityLogger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.tete", category: "security")
    private let authLogger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.tete", category: "auth")
    
    private init() {}
    
    // MARK: - Standard Logging
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        #if DEBUG
        let sanitizedMessage = sanitizeLogMessage(message)
        logMessage(sanitizedMessage, level: .debug, logger: generalLogger, file: file, function: function, line: line)
        #endif
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let sanitizedMessage = sanitizeLogMessage(message)
        logMessage(sanitizedMessage, level: .info, logger: generalLogger, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let sanitizedMessage = sanitizeLogMessage(message)
        logMessage(sanitizedMessage, level: .default, logger: generalLogger, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let sanitizedMessage = sanitizeLogMessage(message)
        logMessage(sanitizedMessage, level: .error, logger: generalLogger, file: file, function: function, line: line)
    }
    
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Error: \(error.localizedDescription)"
        let sanitizedMessage = sanitizeLogMessage(message)
        logMessage(sanitizedMessage, level: .error, logger: generalLogger, file: file, function: function, line: line)
    }
    
    // MARK: - Security Logging
    func securityEvent(_ event: String, details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        let sanitizedEvent = sanitizeLogMessage(event)
        let sanitizedDetails = sanitizeSecurityDetails(details)
        let message = "SECURITY: \(sanitizedEvent) | \(sanitizedDetails)"
        
        logMessage(message, level: .info, logger: securityLogger, file: file, function: function, line: line)
    }
    
    func authEvent(_ event: String, userID: String? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let maskedUserID = userID.map { maskUserID($0) } ?? "unknown"
        let sanitizedEvent = sanitizeLogMessage(event)
        let message = "AUTH: \(sanitizedEvent) | User: \(maskedUserID)"
        
        logMessage(message, level: .info, logger: authLogger, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    private func logMessage(_ message: String, level: OSLogType, logger: OSLog, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        
        #if DEBUG
        let emoji = emojiForLevel(level)
        let debugMessage = "\(emoji) [\(fileName):\(line)] \(function) - \(message)"
        print(debugMessage)
        #endif
        
        os_log("%{public}@", log: logger, type: level, message)
    }
    
    private func emojiForLevel(_ level: OSLogType) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .default: return "⚠️"
        case .error: return "❌"
        case .fault: return "💥"
        default: return "📝"
        }
    }
    
    // MARK: - Message Sanitization
    private func sanitizeLogMessage(_ message: String) -> String {
        var sanitized = message
        
        // 機密情報パターンをマスク
        let patterns = [
            // JWT Token
            (pattern: "eyJ[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]+\\.[A-Za-z0-9-_]*", replacement: "JWT_TOKEN_***"),
            // Google API Key
            (pattern: "AIza[0-9A-Za-z-_]{35}", replacement: "API_KEY_***"),
            // Email (部分的マスク)
            (pattern: "([A-Za-z0-9._%+-]+)@([A-Za-z0-9.-]+\\.[A-Za-z]{2,})", replacement: "$1***@$2"),
            // UUID (部分的マスク)
            (pattern: "([0-9a-fA-F]{8})-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-([0-9a-fA-F]{12})", replacement: "$1-***-***-***-$2"),
            // Password field
            (pattern: "(?i)password[\"'\\s]*[=:][\"'\\s]*[^\\s\"']+", replacement: "password: ***"),
            // Token field
            (pattern: "(?i)token[\"'\\s]*[=:][\"'\\s]*[^\\s\"']+", replacement: "token: ***"),
            // Credit Card (完全マスク)
            (pattern: "\\b[0-9]{4}[\\s-]?[0-9]{4}[\\s-]?[0-9]{4}[\\s-]?[0-9]{4}\\b", replacement: "CARD_***"),
            // Phone Number (部分的マスク)
            (pattern: "\\b([0-9]{3})[0-9]{4}([0-9]{4})\\b", replacement: "$1***$2")
        ]
        
        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern.pattern,
                with: pattern.replacement,
                options: .regularExpression
            )
        }
        
        return sanitized
    }
    
    private func sanitizeSecurityDetails(_ details: [String: Any]) -> String {
        var sanitizedDetails: [String: String] = [:]
        
        for (key, value) in details {
            let stringValue = String(describing: value)
            
            if isSensitiveKey(key) {
                sanitizedDetails[key] = maskSensitiveValue(stringValue)
            } else {
                sanitizedDetails[key] = sanitizeLogMessage(stringValue)
            }
        }
        
        return sanitizedDetails.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
    }
    
    private func isSensitiveKey(_ key: String) -> Bool {
        let sensitiveKeys = ["password", "token", "key", "secret", "auth", "credential", "email", "id", "pin", "ssn"]
        return sensitiveKeys.contains { key.lowercased().contains($0) }
    }
    
    private func maskSensitiveValue(_ value: String) -> String {
        guard value.count > 4 else { return "***" }
        return String(value.prefix(2)) + "***" + String(value.suffix(2))
    }
    
    private func maskUserID(_ userID: String) -> String {
        guard userID.count > 8 else { return "***" }
        return String(userID.prefix(4)) + "***" + String(userID.suffix(4))
    }
}

// MARK: - Production Safety
#if !DEBUG
extension SecureLogger {
    /// 本番環境では追加の機密情報マスキング
    private func productionSanitize(_ message: String) -> String {
        return message
            .replacingOccurrences(of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#, with: "***@***.***", options: .regularExpression)
            .replacingOccurrences(of: #"[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"#, with: "***-***-***-***-***", options: .regularExpression)
            .replacingOccurrences(of: #"[0-9]{10,}"#, with: "***", options: .regularExpression)
    }
}
#endif