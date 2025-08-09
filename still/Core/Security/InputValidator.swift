//======================================================================
// MARK: - InputValidator
// Purpose: ユーザー入力の検証・サニタイズシステム
// Usage: InputValidator.sanitizeText(), InputValidator.validateEmail()
//======================================================================
import Foundation

/// 入力検証・サニタイズシステム
struct InputValidator {
    
    // MARK: - Text Sanitization
    
    /// テキストのサニタイズ（XSS・インジェクション攻撃対策）
    static func sanitizeText(_ input: String, maxLength: Int = 1000) -> String {
        var sanitized = input
        
        // 長さ制限
        if sanitized.count > maxLength {
            sanitized = String(sanitized.prefix(maxLength))
        }
        
        // 危険なHTMLタグの除去
        sanitized = removeDangerousHTML(sanitized)
        
        // SQLインジェクション対策
        sanitized = escapeSQLCharacters(sanitized)
        
        // 制御文字の除去
        sanitized = removeControlCharacters(sanitized)
        
        // 前後の空白文字を除去
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// HTML特殊文字のエスケープ
    static func escapeHTML(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
            .replacingOccurrences(of: "/", with: "&#x2F;")
    }
    
    private static func removeDangerousHTML(_ input: String) -> String {
        let dangerousPatterns = [
            "<script[^>]*>.*?</script>",
            "<iframe[^>]*>.*?</iframe>",
            "<object[^>]*>.*?</object>",
            "<embed[^>]*>.*?</embed>",
            "<form[^>]*>.*?</form>",
            "javascript:",
            "vbscript:",
            "data:",
            "on\\w+\\s*="
        ]
        
        var cleaned = input
        for pattern in dangerousPatterns {
            cleaned = cleaned.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        return cleaned
    }
    
    private static func escapeSQLCharacters(_ input: String) -> String {
        return input
            .replacingOccurrences(of: "'", with: "''")
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
    
    private static func removeControlCharacters(_ input: String) -> String {
        return input.filter { !$0.isNewline && !$0.isWhitespace || $0 == " " || $0 == "\n" }
    }
    
    // MARK: - Email Validation
    
    /// メールアドレスの検証
    static func validateEmail(_ email: String) -> ValidationResult {
        let sanitizedEmail = sanitizeText(email, maxLength: 254)
        
        // 基本的な形式チェック
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: sanitizedEmail) else {
            return .invalid("Invalid email format")
        }
        
        // 危険なパターンチェック
        let dangerousPatterns = ["javascript:", "data:", "vbscript:"]
        for pattern in dangerousPatterns {
            if sanitizedEmail.lowercased().contains(pattern) {
                return .invalid("Email contains dangerous content")
            }
        }
        
        return .valid(sanitizedEmail)
    }

    // MARK: - Username Validation
    
    /// ユーザー名の検証
    static func validateUsername(_ username: String) -> ValidationResult {
        let sanitizedUsername = sanitizeText(username, maxLength: 20)
        
        let usernameRegex = #"^[a-zA-Z0-9_]{3,20}$"#
        let usernamePredicate = NSPredicate(format: "SELF MATCHES %@", usernameRegex)
        
        guard usernamePredicate.evaluate(with: sanitizedUsername) else {
            return .invalid("Username must be 3-20 characters long and can only contain letters, numbers, and underscores.")
        }
        
        return .valid(sanitizedUsername)
    }
    
    // MARK: - Password Validation
    
    /// パスワードの検証
    static func validatePassword(_ password: String) -> ValidationResult {
        let passwordRegex = #"^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$"#
        let passwordPredicate = NSPredicate(format: "SELF MATCHES %@", passwordRegex)
        
        if passwordPredicate.evaluate(with: password) {
            return .valid(password)
        } else {
            return .invalid("Password must be at least 8 characters long and contain at least one letter and one number.")
        }
    }
    
    
    
    /// URL の検証
    static func validateURL(_ urlString: String) -> ValidationResult {
        let sanitized = sanitizeText(urlString, maxLength: 2048)
        
        guard let url = URL(string: sanitized) else {
            return .invalid("Invalid URL format")
        }
        
        // HTTPSのみ許可
        guard url.scheme == "https" else {
            return .invalid("Only HTTPS URLs are allowed")
        }
        
        // 危険なドメインチェック
        if isDangerousDomain(url.host) {
            return .invalid("Domain not allowed")
        }
        
        return .valid(sanitized)
    }
    
    private static func isDangerousDomain(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return true }
        
        let blockedDomains = [
            "localhost", "127.0.0.1", "0.0.0.0", "::1",
            "bit.ly", "tinyurl.com", "t.co" // 短縮URLサービス
        ]
        
        return blockedDomains.contains(host)
    }
    
    // MARK: - Phone Number Validation
    
    /// 電話番号の検証
    static func validatePhoneNumber(_ phone: String) -> ValidationResult {
        let sanitized = phone.replacingOccurrences(of: "[^0-9+\\-\\s()]", with: "", options: .regularExpression)
        
        // 日本の電話番号形式
        let phoneRegex = "^(\\+81|0)[0-9\\-\\s]{9,13}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if phonePredicate.evaluate(with: sanitized) {
            return .valid(sanitized)
        }
        
        return .invalid("Invalid phone number format")
    }
}

// MARK: - Result Types

enum ValidationResult {
    case valid(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    var value: String? {
        switch self {
        case .valid(let value): return value
        case .invalid: return nil
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let message): return message
        }
    }
}



// MARK: - Content Validation

extension InputValidator {
    
    /// 投稿コンテンツの検証
    static func validatePostContent(_ content: String) -> ValidationResult {
        let sanitized = sanitizeText(content, maxLength: 2000)
        
        // 空の投稿チェック
        if sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .invalid("Post content cannot be empty")
        }
        
        // スパムパターンチェック
        if containsSpamPattern(sanitized) {
            return .invalid("Content appears to be spam")
        }
        
        return .valid(sanitized)
    }
    
    private static func containsSpamPattern(_ content: String) -> Bool {
        let spamPatterns = [
            "buy now", "click here", "free money", "guaranteed",
            "limited time", "act now", "call now", "urgent"
        ]
        
        let lowercased = content.lowercased()
        return spamPatterns.contains { lowercased.contains($0) }
    }
}