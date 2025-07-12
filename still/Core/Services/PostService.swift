//======================================================================
// MARK: - PostService.swift
// Purpose: Handles post-related operations including CRUD operations and like management (投稿関連の操作：CRUD操作といいね管理)
// Path: still/Core/Services/PostService.swift
//======================================================================
import Foundation
import Supabase

class PostService: @unchecked Sendable {
    private let client = SupabaseManager.shared.client
    private let likeService = LikeService()
    static let useMockData = false // 写真共有アプリ用モックデータ - グリッドビューテスト用
    
    // モックデータ用のいいね状態を保存（actor-based thread safety）
    private actor MockLikedPostsManager {
        private var likedPosts: Set<String> = ["1", "3"] // 初期状態
        
        func contains(_ postId: String) -> Bool {
            return likedPosts.contains(postId)
        }
        
        func insert(_ postId: String) {
            likedPosts.insert(postId)
        }
        
        func remove(_ postId: String) {
            likedPosts.remove(postId)
        }
        
        func getAllPosts() -> Set<String> {
            return likedPosts
        }
    }
    
    private static let mockLikedPostsManager = MockLikedPostsManager()
    
    // フィード用の投稿一覧を取得
    func fetchFeedPosts(currentUserId: String? = nil) async throws -> [Post] {
        // モックモードの場合
        if PostService.useMockData {
            print("🔵 写真共有アプリ用モックデータを使用します")
            var posts = getMockPosts()
            
            // モックデータにもいいね状態を設定
            if let userId = currentUserId {
                for i in 0..<posts.count {
                    posts[i].isLikedByMe = await checkMockLikeStatus(postId: posts[i].id, userId: userId)
                }
            }
            
            return posts
        }
        
        // 本番モード
        
        do {
            // Check if the task is cancelled before making network request
            try Task.checkCancellation()
            
            // まず投稿のみを取得
            var posts: [Post] = try await client
                .from("posts")
                .select("*")
                .eq("is_public", value: true)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            
            // Check cancellation after each major operation
            try Task.checkCancellation()
            
            // いいね状態を取得
            if let userId = currentUserId {
                for i in 0..<posts.count {
                    do {
                        posts[i].isLikedByMe = try await likeService.checkUserLikeStatus(
                            postId: posts[i].id,
                            userId: userId
                        )
                    } catch {
                        print("⚠️ いいね状態取得エラー: \(error)")
                        posts[i].isLikedByMe = false
                    }
                }
            }
            
            // 投稿のユーザーIDを集めて一度にユーザー情報を取得
            let userIds = Array(Set(posts.map { $0.userId })) // 重複を除去
            
            var userMap: [String: UserProfile] = [:]
            
            if !userIds.isEmpty {
                do {
                    let userProfiles: [UserProfile] = try await client
                        .from("user_profiles")
                        .select("*")
                        .in("id", values: userIds)
                        .execute()
                        .value
                    
                    
                    for user in userProfiles {
                        userMap[user.id] = user
                    }
                    
                    // どのユーザーIDが見つからなかったかをチェック
                    let foundUserIds = Set(userProfiles.map { $0.id })
                    _ = Set(userIds).subtracting(foundUserIds)
                } catch {
                    print("❌ ユーザー情報一括取得エラー: \(error)")
                }
            }
            
            // 投稿にユーザー情報を設定
            for i in 0..<posts.count {
                if let user = userMap[posts[i].userId] {
                    posts[i].user = user
                } else {
                    print("⚠️ ユーザー情報が見つかりません: Post \(posts[i].id), User ID \(posts[i].userId)")
                    // ダミーユーザーを作成
                    posts[i].user = UserProfile(
                        id: posts[i].userId,
                        username: "user_\(posts[i].userId.suffix(8))",
                        displayName: "Unknown User",
                        avatarUrl: nil,
                        bio: nil,
                        createdAt: nil
                    )
                }
            }
            
            return posts
            
        } catch is CancellationError {
            print("🔄 PostService: リクエストがキャンセルされました")
            throw CancellationError()
        } catch {
            print("❌ PostService エラー: \(error)")
            throw error
        }
    }
    
    // 特定ユーザーの投稿を取得
    func fetchUserPosts(userId: String) async throws -> [Post] {
        if PostService.useMockData {
            return getMockPosts().filter { $0.userId == userId }
        }
        
        do {
            var posts: [Post] = try await client
                .from("posts")
                .select("*")
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // 手動でユーザー情報を取得
            for i in 0..<posts.count {
                do {
                    let userProfile: UserProfile = try await client
                        .from("profiles")
                        .select("*")
                        .eq("id", value: posts[i].userId)
                        .single()
                        .execute()
                        .value
                    posts[i].user = userProfile
                } catch {
                    print("⚠️ ユーザー情報取得エラー: \(error)")
                }
            }
            
            return posts
            
        } catch {
            print("❌ fetchUserPosts エラー: \(error)")
            throw error
        }
    }
    
    // 写真共有アプリ用モックデータ
    private func getMockPosts() -> [Post] {
        let users = getMockUsers()
        var posts: [Post] = []
        
        let captions = [
            "美しい夕日を撮影しました 📸✨", "今日のランチ 🍝 パスタが絶品でした！", "桜が満開です 🌸 春の訪れを感じます",
            "新しいカメラでテスト撮影 📷", "コーヒーアート ☕️ 今日も素敵な一杯", "海辺の散歩道 🌊 波の音が心地よい",
            "街角のアート 🎨 偶然見つけた素敵な壁画", "雨上がりの虹 🌈 幸せな瞬間", "夜景が綺麗 ✨ 都市の輝き",
            "友達とカフェタイム ☕️ 楽しい時間", "お気に入りの本 📚 静かな午後", "ペットの寝顔 😴 可愛すぎる",
            "朝の散歩 🚶‍♀️ 清々しい空気", "手作りケーキ 🍰 初挑戦成功！", "電車からの景色 🚃 移ろう風景",
            "公園のベンチ 🪑 のんびり時間", "花屋さんの前で 🌻 色とりどりの花", "図書館での勉強 📖 集中タイム",
            "スケートボード練習中 🛹 上達したい", "美術館にて 🖼️ 感動の作品に出会う", "山登りの途中 ⛰️ 絶景ポイント",
            "料理中の一コマ 🍳 今夜は手料理", "音楽ライブ 🎵 最高のパフォーマンス", "映画館で 🎬 話題の作品を鑑賞",
            "散髪後のすっきり感 ✂️ 新しい自分", "ジムでトレーニング 💪 健康第一", "ショッピング中 🛍️ お気に入り発見",
            "家族と食事 👨‍👩‍👧‍👦 温かい時間", "仕事終わりの一杯 🍺 お疲れ様", "早朝のジョギング 🏃‍♂️ 健康的な朝",
            "新しい服を試着 👔 気分転換", "友人の結婚式 💒 おめでとう", "子供の笑顔 😊 最高の瞬間",
            "ガーデニング 🌱 植物の成長が楽しみ", "DIY作業中 🔨 創作の時間", "ヨガクラス 🧘‍♀️ 心身ともにリフレッシュ",
            "新しいカフェ発見 ☕️ 隠れた名店", "古本屋巡り 📚 掘り出し物を探して", "夕焼け空 🌅 一日の終わりに",
            "お祭りの屋台 🏮 懐かしい味", "電車の中で読書 📖 通勤時間を有効活用", "公園でピクニック 🧺 自然の中で",
            "新商品をチェック 🛒 気になるアイテム", "友達と映画鑑賞 🍿 笑いあり涙あり", "早朝の散歩道 🌄 静寂の時間",
            "お気に入りのカフェ ☕️ いつもの場所", "新しい趣味に挑戦 🎯 楽しい発見", "家でのんびり 🏠 リラックスタイム",
            "街の夜景 🌃 ネオンが美しい", "友人との再会 🤝 久しぶりの時間", "料理の盛り付け 🍽️ 見た目も大切"
        ]
        
        let locations = [
            "渋谷スカイ", "恵比寿ガーデンプレイス", "上野公園", "表参道", "新宿御苑", "お台場海浜公園",
            "原宿竹下通り", "銀座", "浅草寺", "東京スカイツリー", "六本木ヒルズ", "代々木公園",
            "築地市場", "皇居外苑", "明治神宮", "池袋サンシャインシティ", "秋葉原", "神田神保町",
            "吉祥寺", "下北沢", "中目黒", "自由が丘", "二子玉川", "品川",
            "新橋", "有楽町", "日比谷公園", "赤坂", "青山", "麻布十番",
            "広尾", "白金台", "田町", "浜松町", "門前仲町", "清澄白河",
            "両国", "錦糸町", "亀戸", "小岩", "葛西", "新小岩",
            "北千住", "綾瀬", "金町", "立石", "青砥", "高砂"
        ]
        
        // 50投稿を生成
        for i in 1...50 {
            let userIndex = (i - 1) % users.count
            let user = users[userIndex]
            
            // 画像のアスペクト比をランダム設定
            let aspectRatios = [
                (800, 400),  // 横長 2:1
                (400, 800),  // 縦長 1:2  
                (400, 400),  // 正方形 1:1
                (600, 400),  // 横長 3:2
                (400, 600),  // 縦長 2:3
                (500, 400),  // 横長 5:4
                (400, 500),  // 縦長 4:5
                (700, 400),  // 横長 7:4
                (400, 700)   // 縦長 4:7
            ]
            
            let ratioIndex = i % aspectRatios.count
            let (width, height) = aspectRatios[ratioIndex]
            
            let post = Post(
                id: "\(i)",
                userId: user.id,
                mediaUrl: "https://picsum.photos/\(width)/\(height)?random=\(i)",
                mediaType: .photo,
                thumbnailUrl: nil,
                caption: captions[(i - 1) % captions.count],
                locationName: i % 3 == 0 ? nil : locations[(i - 1) % locations.count],
                latitude: i % 3 == 0 ? nil : Double.random(in: 35.6...35.8),
                longitude: i % 3 == 0 ? nil : Double.random(in: 139.6...139.8),
                isPublic: true,
                createdAt: Date().addingTimeInterval(-Double(i * 3600)),
                likeCount: Int.random(in: 0...100),
                commentCount: Int.random(in: 0...20),
                user: user
            )
            
            posts.append(post)
        }
        
        return posts
    }
    
    // 50ユーザーのモックデータ
    private func getMockUsers() -> [UserProfile] {
        let usernames = [
            "photo_lover", "food_explorer", "nature_shots", "coffee_artist", "street_photographer",
            "sunset_chaser", "urban_explorer", "vintage_vibes", "modern_minimalist", "color_pop",
            "black_white", "golden_hour", "rainy_days", "sunny_side", "night_owl",
            "early_bird", "weekend_warrior", "city_lights", "countryside", "beach_lover",
            "mountain_high", "forest_deep", "desert_sand", "ocean_blue", "sky_high",
            "ground_level", "macro_world", "wide_angle", "telephoto", "prime_lens",
            "zoom_master", "bokeh_king", "sharp_focus", "motion_blur", "long_exposure",
            "fast_shutter", "slow_life", "busy_bee", "calm_water", "rough_sea",
            "smooth_sailing", "bumpy_ride", "straight_line", "curved_path", "uphill_climb",
            "downhill_ride", "level_ground", "high_peak", "deep_valley", "wide_plain"
        ]
        
        let displayNames = [
            "フォトグラファー", "グルメ探検家", "自然写真家", "カフェ愛好家", "ストリート写真家",
            "夕日ハンター", "都市探検家", "ヴィンテージ好き", "ミニマリスト", "カラフル写真家",
            "モノクロ写真家", "ゴールデンアワー", "雨の日写真家", "晴れ好き", "夜行性",
            "早起き鳥", "週末戦士", "夜景撮影", "田舎暮らし", "海好き",
            "山男", "森の人", "砂漠の旅人", "海の青", "空高く",
            "地上レベル", "マクロ世界", "広角派", "望遠鏡", "単焦点",
            "ズームマスター", "ボケ王", "シャープフォーカス", "モーションブラー", "長時間露光",
            "高速シャッター", "スローライフ", "忙しい蜂", "静かな水", "荒い海",
            "順風満帆", "でこぼこ道", "直線道路", "曲がりくねった道", "上り坂",
            "下り坂", "平地", "高峰", "深い谷", "広い平原"
        ]
        
        let bios = [
            "写真が好きです📷", "美味しいもの巡り中", "自然の美しさを伝えます", "コーヒーとアートが好き", "街の瞬間を切り取ります",
            "毎日が冒険✨", "都市の隠れた美を発見", "古き良き時代の魅力", "シンプルイズベスト", "色彩豊かな世界",
            "白黒の世界観", "光と影のマジック", "雨音と写真", "太陽の恵み", "夜の静寂を愛す",
            "朝の光が好き", "自由な週末", "都市の煌めき", "田園風景が心の故郷", "波の音が好き",
            "山頂からの景色", "森林浴で癒される", "砂漠の神秘", "海の深さに魅了", "雲を追いかけて",
            "足元の小さな世界", "細部に宿る美", "広がる景色を愛す", "遠くを見つめて", "一点に集中",
            "自在な視点", "美しいボケ味", "鮮明な世界", "動きのある写真", "時の流れを写す",
            "瞬間を凍結", "ゆっくりと生きる", "活動的な毎日", "穏やかな時間", "荒波に立ち向かう",
            "風に任せて", "困難も楽しむ", "まっすぐな生き方", "柔軟な思考", "努力を惜しまない",
            "楽な道を選ばない", "バランス重視", "頂点を目指す", "深く考える", "自由な発想"
        ]
        
        let backgroundColors = [
            "0D8ABC", "E91E63", "4CAF50", "FF5722", "9C27B0", "F44336", "2196F3", "FF9800",
            "795548", "607D8B", "3F51B5", "009688", "CDDC39", "FFC107", "8BC34A", "00BCD4",
            "FFEB3B", "E91E63", "673AB7", "FF5722", "9E9E9E", "FF9800", "4CAF50", "2196F3",
            "F44336", "9C27B0", "795548", "607D8B", "3F51B5", "009688", "CDDC39", "FFC107",
            "8BC34A", "00BCD4", "FFEB3B", "E91E63", "673AB7", "FF5722", "9E9E9E", "FF9800",
            "4CAF50", "2196F3", "F44336", "9C27B0", "795548", "607D8B", "3F51B5", "009688",
            "CDDC39", "FFC107"
        ]
        
        var users: [UserProfile] = []
        
        for i in 1...50 {
            let username = usernames[i - 1]
            let displayName = displayNames[i - 1]
            let bio = bios[i - 1]
            let backgroundColor = backgroundColors[i - 1]
            
            let user = UserProfile(
                id: "user-\(i)",
                username: username,
                displayName: displayName,
                avatarUrl: "https://ui-avatars.com/api/?name=\(username.prefix(2).uppercased())&background=\(backgroundColor)&color=fff",
                bio: bio,
                createdAt: Date().addingTimeInterval(-Double(i * 86400))
            )
            
            users.append(user)
        }
        
        return users
    }
    
    // MARK: - Like Operations
    
    func toggleLike(postId: String, userId: String) async throws -> Bool {
        if PostService.useMockData {
            // モックデータ用のいいね処理
            let isCurrentlyLiked = await PostService.mockLikedPostsManager.contains(postId)
            if isCurrentlyLiked {
                await PostService.mockLikedPostsManager.remove(postId)
                return false
            } else {
                await PostService.mockLikedPostsManager.insert(postId)
                return true
            }
        } else {
            let isNowLiked = try await likeService.toggleLike(postId: postId, userId: userId)
            return isNowLiked
        }
    }
    
    func getLikes(for postId: String) async throws -> [Like] {
        return try await likeService.getLikes(for: postId)
    }
    
    func getLikeCount(for postId: String) async throws -> Int {
        return try await likeService.getLikeCount(for: postId)
    }
    
    // MARK: - Delete Operations
    
    func deletePost(postId: String, userId: String) async throws -> Bool {
        if PostService.useMockData {
            // モックデータでは削除をシミュレート（実際には削除しない）
            return true
        } else {
            // 実際のデータベースから削除
            try await client
                .from("posts")
                .delete()
                .eq("id", value: postId)
                .eq("user_id", value: userId) // 自分の投稿のみ削除可能
                .execute()
            
            return true
        }
    }
    
    // MARK: - Mock Data Helper
    
    private func checkMockLikeStatus(postId: String, userId: String) async -> Bool {
        // モックデータ用：動的ないいね状態を返す
        return await PostService.mockLikedPostsManager.contains(postId)
    }
}

