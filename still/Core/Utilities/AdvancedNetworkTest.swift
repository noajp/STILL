//======================================================================
// MARK: - AdvancedNetworkTest（詳細なネットワーク診断）
// Path: foodai/Core/Utilities/AdvancedNetworkTest.swift
//======================================================================
import Foundation
import Network // ネットワーク診断用

class AdvancedNetworkTest {
    
    static func runCompleteDiagnostics() async {
        print("\n🔥🔥🔥 完全ネットワーク診断開始 🔥🔥🔥\n")
        
        // 1. 基本的なインターネット接続
        await testBasicInternet()
        
        // 2. DNS解決テスト（簡略化）
        await testDNSResolution()
        
        // 3. Supabase直接アクセス
        await testSupabaseDirectAccess()
        
        // 4. 代替Supabaseエンドポイント
        await testAlternativeEndpoints()
        
        // 5. ネットワーク設定の詳細
        printNetworkConfiguration()
        
        print("\n🔥🔥🔥 診断完了 🔥🔥🔥\n")
    }
    
    // 1. 基本的なインターネット接続テスト
    static func testBasicInternet() async {
        print("📡 === 基本インターネット接続テスト ===")
        
        let testURLs = [
            "https://www.google.com",
            "https://api.github.com",
            "https://httpbin.org/get"
        ]
        
        for urlString in testURLs {
            guard let url = URL(string: urlString) else { continue }
            
            do {
                let start = Date()
                let (_, response) = try await URLSession.shared.data(from: url)
                let elapsed = Date().timeIntervalSince(start)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ \(urlString): Status \(httpResponse.statusCode) - \(String(format: "%.2f", elapsed))秒")
                }
            } catch {
                print("❌ \(urlString): \(error.localizedDescription)")
            }
        }
    }
    
    // 2. DNS解決テスト（簡略化版）
    static func testDNSResolution() async {
        print("\n🌐 === DNS解決テスト ===")
        
        let host = "yccjlkcxqybxqewzchen.supabase.co"
        
        // URLSessionを使った簡易的なDNS確認
        if let url = URL(string: "https://\(host)") {
            do {
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                request.timeoutInterval = 5
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ DNS解決成功: \(host) - Status: \(httpResponse.statusCode)")
                }
            } catch {
                print("❌ DNS解決失敗: \(host) - \(error.localizedDescription)")
            }
        }
    }
    
    // 3. Supabase直接アクセステスト
    static func testSupabaseDirectAccess() async {
        print("\n🔗 === Supabase直接アクセステスト ===")
        
        let baseURL = Config.supabaseURL
        let endpoints = [
            "",  // ルート
            "/rest/v1/",
            "/auth/v1/health",
            "/auth/v1/"
        ]
        
        for endpoint in endpoints {
            let urlString = baseURL + endpoint
            guard let url = URL(string: urlString) else { continue }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let start = Date()
                let (data, response) = try await URLSession.shared.data(for: request)
                let elapsed = Date().timeIntervalSince(start)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ \(endpoint): Status \(httpResponse.statusCode) - \(String(format: "%.2f", elapsed))秒")
                    
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("   レスポンス: \(String(responseString.prefix(100)))...")
                    }
                }
            } catch let error as NSError {
                print("❌ \(endpoint): エラーコード \(error.code) - \(error.localizedDescription)")
                analyzeError(error)
            }
        }
    }
    
    // 4. 代替エンドポイントテスト
    static func testAlternativeEndpoints() async {
        print("\n🔄 === 代替エンドポイントテスト ===")
        
        // 別のSupabaseプロジェクトでテスト（公開プロジェクト）
        let testURL = "https://xyzcompany.supabase.co/rest/v1/"
        
        if let url = URL(string: testURL) {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            
            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ 他のSupabaseプロジェクト: Status \(httpResponse.statusCode)")
                    print("   → Supabase自体は接続可能")
                }
            } catch {
                print("❌ 他のSupabaseプロジェクト: \(error.localizedDescription)")
            }
        }
    }
    
    // 5. ネットワーク設定の詳細
    static func printNetworkConfiguration() {
        print("\n⚙️ === ネットワーク設定 ===")
        
        let config = URLSessionConfiguration.default
        print("タイムアウト設定:")
        print("  - リクエストタイムアウト: \(config.timeoutIntervalForRequest)秒")
        print("  - リソースタイムアウト: \(config.timeoutIntervalForResource)秒")
        print("  - HTTP最大接続数: \(config.httpMaximumConnectionsPerHost)")
        print("  - クッキー受け入れ: \(config.httpCookieAcceptPolicy.rawValue)")
        
        // Network frameworkを使った接続状態確認
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        
        monitor.pathUpdateHandler = { path in
            print("\nネットワーク状態:")
            print("  - 接続状態: \(path.status == .satisfied ? "接続中" : "未接続")")
            print("  - 接続タイプ: \(path.isExpensive ? "従量制" : "定額制")")
            
            if path.usesInterfaceType(.wifi) {
                print("  - インターフェース: Wi-Fi")
            } else if path.usesInterfaceType(.cellular) {
                print("  - インターフェース: モバイルデータ")
            } else if path.usesInterfaceType(.wiredEthernet) {
                print("  - インターフェース: 有線LAN")
            }
        }
        
        monitor.start(queue: queue)
        
        // 少し待機してから停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            monitor.cancel()
        }
    }
    
    // エラー分析
    static func analyzeError(_ error: NSError) {
        print("\n🔍 エラー詳細分析:")
        print("  - ドメイン: \(error.domain)")
        print("  - コード: \(error.code)")
        
        switch error.code {
        case -1001:
            print("  💡 タイムアウト: サーバーが応答しない")
            print("     → プロジェクトが一時停止中の可能性")
        case -1003:
            print("  💡 ホストが見つからない: DNSエラー")
        case -1004:
            print("  💡 サーバーに接続できない")
        case -1005:
            print("  💡 ネットワーク接続が失われた")
        case -1009:
            print("  💡 インターネット接続なし")
        default:
            print("  💡 その他のネットワークエラー")
        }
    }
}
