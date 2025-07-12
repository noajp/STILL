//======================================================================
// MARK: - Logger
// Purpose: Centralized logging system for the app
// Usage: Logger.shared.info("message"), Logger.shared.error("error")
//======================================================================
import Foundation
import os.log

/// Centralized logging system
final class Logger: @unchecked Sendable {
    static let shared = Logger()
    
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.tete"
    
    private init() {}
    
    /// Log levels
    enum Level {
        case debug
        case info
        case warning
        case error
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    /// Log a debug message
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Log an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Log an error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Log an error object
    func error(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
        let message = "Error: \(error.localizedDescription)"
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    private func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let category = "\(fileName):\(line)"
        
        let osLog = OSLog(subsystem: subsystem, category: category)
        
        #if DEBUG
        let debugMessage = "\(level.emoji) [\(fileName):\(line)] \(function) - \(message)"
        print(debugMessage)
        #endif
        
        os_log("%{public}@", log: osLog, type: level.osLogType, message)
    }
}