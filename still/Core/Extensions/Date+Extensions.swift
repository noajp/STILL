//======================================================================
// MARK: - Date+Extensions.swift
// Purpose: Swift extensions for enhanced functionality (Date+Extensionsの機能拡張)
// Path: still/Core/Extensions/Date+Extensions.swift
//======================================================================
import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(self)
        
        // 1分未満
        if timeInterval < 60 {
            return "今"
        }
        // 1時間未満（分単位）
        else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)分前"
        }
        // 24時間未満（時間単位）
        else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)時間前"
        }
        // 7日未満（日単位）
        else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)日前"
        }
        // それ以上は日付表示
        else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: self)
        }
    }
}