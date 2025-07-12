//======================================================================
// MARK: - ForceReloadView.swift
// Purpose: SwiftUI view component (ForceReloadViewビューコンポーネント)
// Path: still/Features/AppEntry/ForceReloadView.swift
//======================================================================
//
//  ForceReloadView.swift
//  tete
//
//  強制的に設定をリロードするためのビュー
//

import SwiftUI

struct ForceReloadView: View {
    @State private var isReloading = false
    @State private var reloadMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("設定のリロード")
                .font(.title)
                .fontWeight(.bold)
            
            if isReloading {
                ProgressView()
                    .scaleEffect(1.5)
            }
            
            Text(reloadMessage)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("設定をリロード") {
                reloadConfiguration()
            }
            .buttonStyle(.borderedProminent)
            .disabled(isReloading)
            
            Button("Keychainをクリア") {
                clearKeychain()
            }
            .buttonStyle(.bordered)
            .disabled(isReloading)
        }
        .padding()
        .onAppear {
            checkCurrentConfiguration()
        }
    }
    
    private func checkCurrentConfiguration() {
        let config = SecureConfig.shared
        reloadMessage = """
        現在の設定:
        URL: \(config.supabaseURL.isEmpty ? "未設定" : "設定済み")
        Key: \(config.supabaseAnonKey.isEmpty ? "未設定" : "設定済み")
        """
    }
    
    private func reloadConfiguration() {
        isReloading = true
        reloadMessage = "設定をリロード中..."
        
        // Keychainをクリアして再読み込み
        SecureConfig.shared.clearAllCredentials()
        
        // 少し待ってから再読み込み
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Secrets.plistから再読み込みを強制
            SecureConfig.shared.reloadFromSecrets()
            
            isReloading = false
            checkCurrentConfiguration()
            reloadMessage += "\nリロード完了！アプリを再起動してください。"
        }
    }
    
    private func clearKeychain() {
        isReloading = true
        reloadMessage = "Keychainをクリア中..."
        
        SecureConfig.shared.clearAllCredentials()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isReloading = false
            checkCurrentConfiguration()
            reloadMessage += "\nKeychainをクリアしました。"
        }
    }
}

#if DEBUG
struct ForceReloadView_Previews: PreviewProvider {
    static var previews: some View {
        ForceReloadView()
    }
}
#endif