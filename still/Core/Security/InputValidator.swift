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
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
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
    
    // MARK: - Password Validation
    
    /// パスワードの検証（軽量版：6文字以上、文字と数字があればOK）
    static func validatePassword(_ password: String) -> PasswordValidationResult {
        var errors: [String] = []
        var strength: PasswordStrength = .weak
        
        // 長さチェック（6文字以上に変更）
        if password.count < 6 {
            errors.append("Password must be at least 6 characters long")
        }
        
        if password.count > 128 {
            errors.append("Password must be less than 128 characters")
        }
        
        // 簡易文字種チェック（文字と数字があればOK）
        let hasLetter = password.contains { $0.isLetter }
        let hasDigit = password.contains { $0.isNumber }
        
        if !hasLetter {
            errors.append("Password must contain at least one letter")
        }
        
        if !hasDigit {
            errors.append("Password must contain at least one number")
        }
        
        // 強度判定（簡易版）
        if password.count >= 8 && hasLetter && hasDigit {
            strength = .strong
        } else if password.count >= 6 && hasLetter && hasDigit {
            strength = .medium
        } else {
            strength = .weak
        }
        
        // 一般的な脆弱パスワードチェック
        if isCommonPassword(password) {
            errors.append("Password is too common. Please choose a more unique password")
            strength = .weak
        }
        
        return PasswordValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            strength: strength
        )
    }
    
    private static func isCommonPassword(_ password: String) -> Bool {
        let commonPasswords = [
            "password", "123456", "123456789", "qwerty", "abc123",
            "password123", "admin", "letmein", "welcome", "monkey"
        ]
        
        return commonPasswords.contains(password.lowercased())
    }
    
    // MARK: - URL Validation
    
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

struct PasswordValidationResult {
    let isValid: Bool
    let errors: [String]
    let strength: PasswordStrength
}

enum PasswordStrength: String, CaseIterable {
    case veryWeak = "Very Weak"
    case weak = "Weak"
    case medium = "Medium"
    case strong = "Strong"
    case veryStrong = "Very Strong"
    
    var color: String {
        switch self {
        case .veryWeak: return "red"
        case .weak: return "orange"
        case .medium: return "yellow"
        case .strong: return "lightgreen"
        case .veryStrong: return "green"
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