//======================================================================
// MARK: - NetworkTest.swift（修正版）
// Path: foodai/Core/Utilities/NetworkTest.swift
//======================================================================
import Foundation

class NetworkTest {
    static func testSupabaseConnection() async {
        print("🔵 Supabase接続テスト開始")
        print("URL: \(Config.supabaseURL)")
        print("Key: \(String(Config.supabaseAnonKey.prefix(20)))...")
        
        // 1. 基本的な接続テスト - 別のURLでテスト
        do {
            let testUrl = URL(string: "https://httpbin.org/get")!
            let (_, response) = try await URLSession.shared.data(from: testUrl)
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ インターネット接続OK: \(httpResponse.statusCode)")
            }
        } catch {
            print("❌ インターネット接続エラー: \(error)")
            return
        }
        
        // 2. Supabase URLが有効か確認（修正: urlを使用しない）
        guard let _ = URL(string: Config.supabaseURL) else {
            print("❌ 無効なSupabase URL")
            return
        }
        
        // 3. Supabase Health Check
        do {
            let healthUrl = URL(string: "\(Config.supabaseURL)/auth/v1/health")!
            var request = URLRequest(url: healthUrl)
            request.timeoutInterval = 60
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("✅ Supabase Health Check Status: \(httpResponse.statusCode)")
                
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    print("✅ Supabaseプロジェクトは正常に動作しています")
                } else {
                    print("⚠️ Supabaseプロジェクトのステータスコード: \(httpResponse.statusCode)")
                }
            }
        } catch {
            print("❌ Supabase接続エラー: \(error)")
            print("💡 新しいSupabaseプロジェクトの作成を検討してください")
        }
    }
    
    static func openSupabaseDashboard() {
        if let url = URL(string: "https://app.supabase.com") {
            print("🔗 Supabaseダッシュボード: \(url)")
        }
    }
}
