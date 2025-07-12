//======================================================================
// MARK: - CreatePostViewModel（画像・動画対応版）
// Path: foodai/Features/CreatePost/ViewModels/CreatePostViewModel.swift
//======================================================================
import SwiftUI
import PhotosUI
@preconcurrency import AVFoundation
import Supabase

extension Notification.Name {
    static let postUploadStarted = Notification.Name("postUploadStarted")
    static let postUploadProgress = Notification.Name("postUploadProgress")
    static let postUploadCompleted = Notification.Name("postUploadCompleted")
    static let postUploadFailed = Notification.Name("postUploadFailed")
}

@MainActor
class CreatePostViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedVideoURL: URL?
    @Published var mediaType: Post.MediaType = .photo
    @Published var caption = ""
    @Published var locationName = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var isPostCreated = false
    @Published var uploadProgress: Double = 0
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var isPublic = true
    
    private let postService = PostService()
    private let supabase = SupabaseManager.shared.client
    
    var canPost: Bool {
        selectedImage != nil || selectedVideoURL != nil
    }
    
    func createPost() async {
        guard canPost else { return }
        guard let userId = AuthManager.shared.currentUser?.id else {
            errorMessage = "Login required"
            showError = true
            return
        }
        
        print("🔵 CreatePost: User ID = \(userId)")
        
        isLoading = true
        uploadProgress = 0
        
        do {
            // 1. メディアをアップロード
            uploadProgress = 0.3
            let mediaUrl: String
            if let image = selectedImage {
                mediaUrl = try await uploadImage(image)
            } else if let videoURL = selectedVideoURL {
                mediaUrl = try await uploadVideo(videoURL)
            } else {
                throw PostError.noMediaSelected
            }
            
            // 2. 投稿を作成
            uploadProgress = 0.8
            try await createPostRecord(
                userId: userId,
                mediaUrl: mediaUrl
            )
            
            uploadProgress = 1.0
            isPostCreated = true
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            print("❌ 投稿エラー: \(error)")
            print("❌ エラー詳細: \(error)")
            print("❌ エラータイプ: \(type(of: error))")
        }
        
        isLoading = false
    }
    
    func createPostInBackground() {
        guard canPost else { 
            print("🔴 Cannot post: canPost = false")
            return 
        }
        guard let userId = AuthManager.shared.currentUser?.id else {
            print("🔴 Cannot post: No user ID")
            print("🔴 AuthManager.shared.currentUser: \(String(describing: AuthManager.shared.currentUser))")
            print("🔴 AuthManager.shared.isAuthenticated: \(AuthManager.shared.isAuthenticated)")
            errorMessage = "Login required"
            showError = true
            return
        }
        
        print("🟢 User ID: \(userId)")
        print("🟢 User authenticated: \(AuthManager.shared.isAuthenticated)")
        
        print("🟢 Starting background post creation for user: \(userId)")
        print("🟢 Has image: \(selectedImage != nil)")
        print("🟢 Has video: \(selectedVideoURL != nil)")
        print("🟢 Caption: \(caption)")
        
        // Capture current state
        let image = selectedImage
        let videoURL = selectedVideoURL
        let captionText = caption
        let location = locationName
        let lat = latitude
        let lng = longitude
        let isPublicPost = isPublic
        let currentMediaType = mediaType
        
        // Notify upload started
        NotificationCenter.default.post(
            name: .postUploadStarted,
            object: nil,
            userInfo: ["caption": captionText]
        )
        
        Task.detached { [weak self] in
            // Capture supabase client at the start
            guard let supabase = self?.supabase else {
                print("🔴 Supabase client is nil at task start")
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .postUploadFailed,
                        object: nil,
                        userInfo: ["error": "Supabase client not available"]
                    )
                }
                return
            }
            
            do {
                // Check if user profile exists
                print("🔵 Checking if user profile exists...")
                let profileCheck = try await supabase
                    .from("user_profiles")
                    .select("id", head: true, count: .exact)
                    .eq("id", value: userId)
                    .execute()
                
                let profileCount = profileCheck.count ?? 0
                print("🔵 Profile check result: \(profileCount) profiles found")
                
                if profileCount == 0 {
                    print("🔴 User profile not found in database")
                    await MainActor.run { [weak self] in
                        self?.errorMessage = "Please complete your profile setup first"
                        self?.showError = true
                    }
                    return
                }
                
                // 1. Upload media
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .postUploadProgress,
                        object: nil,
                        userInfo: ["progress": 0.3]
                    )
                }
                
                let mediaUrl: String
                if let image = image {
                    mediaUrl = try await self?.uploadImage(image) ?? ""
                } else if let videoURL = videoURL {
                    mediaUrl = try await self?.uploadVideo(videoURL) ?? ""
                } else {
                    throw PostError.noMediaSelected
                }
                
                // 2. Create post record
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .postUploadProgress,
                        object: nil,
                        userInfo: ["progress": 0.8]
                    )
                }
                
                // Create new post with captured values including dimensions
                struct NewPost: Encodable {
                    let user_id: UUID
                    let media_url: String
                    let media_type: String
                    let media_width: Double?
                    let media_height: Double?
                    let caption: String?
                    let location_name: String?
                    let latitude: Double?
                    let longitude: Double?
                    let is_public: Bool
                }
                
                // Get media dimensions
                var mediaDimensions: (width: Double, height: Double)? = nil
                if let image = image {
                    let width = Double(image.size.width)
                    let height = Double(image.size.height)
                    let aspectRatio = width / height
                    mediaDimensions = (width: width, height: height)
                    print("🟢 Image dimensions: \(width) x \(height) (aspect ratio: \(String(format: "%.2f", aspectRatio)))")
                    print("🟢 Would be displayed as: \(aspectRatio >= 1.3 ? "landscape" : "square")")
                }
                
                let newPost = NewPost(
                    user_id: UUID(uuidString: userId)!,
                    media_url: mediaUrl,
                    media_type: currentMediaType.rawValue,
                    media_width: mediaDimensions?.width,
                    media_height: mediaDimensions?.height,
                    caption: captionText.isEmpty ? nil : captionText,
                    location_name: location.isEmpty ? nil : location,
                    latitude: lat,
                    longitude: lng,
                    is_public: isPublicPost
                )
                
                print("🟢 Inserting post to database...")
                print("🟢 Post data: user_id=\(userId), media_url=\(mediaUrl)")
                print("🟢 NewPost object: \(newPost)")
                
                // Verify auth session (supabase is already captured above)
                do {
                    let session = try await supabase.auth.session
                    print("🔵 Auth session user ID: \(session.user.id)")
                    print("🔵 Post user ID: \(userId)")
                    if session.user.id.uuidString.lowercased() != userId.lowercased() {
                        print("🔴 User ID mismatch! Session: \(session.user.id), Post: \(userId)")
                    }
                } catch {
                    print("🔴 Failed to get auth session: \(error)")
                }
                
                let response = try await supabase
                    .from("posts")
                    .insert(newPost)
                    .select()
                    .single()
                    .execute()
                print("🟢 Database insert response received")
                print("🟢 Response status: \(response.response.statusCode)")
                print("🟢 Response data length: \(response.data.count) bytes")
                
                if !response.data.isEmpty {
                    let createdPost = try JSONDecoder().decode(Post.self, from: response.data)
                    print("🟢 Post created successfully: \(createdPost.id)")
                    
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .postUploadCompleted,
                            object: nil,
                            userInfo: ["post": createdPost]
                        )
                        print("🟢 Post upload completed notification sent")
                        
                        // Send notification to refresh feed
                        NotificationCenter.default.post(name: NSNotification.Name("PostCreated"), object: nil)
                        print("🟢 Post created notification sent for feed refresh")
                    }
                } else {
                    print("🔴 No response data from post creation")
                    print("🔴 Response status code: \(response.response.statusCode)")
                    if let responseStr = String(data: response.data, encoding: .utf8) {
                        print("🔴 Response body: \(responseStr)")
                    }
                    throw PostError.uploadFailed
                }
                
            } catch {
                print("🔴 Post creation failed: \(error)")
                print("🔴 Error type: \(type(of: error))")
                print("🔴 Error localized: \(error.localizedDescription)")
                
                // Check for specific Supabase errors
                if let supabaseError = error as? PostgrestError {
                    print("🔴 Supabase error code: \(supabaseError.code ?? "unknown")")
                    print("🔴 Supabase error message: \(supabaseError.message)")
                    // PostgrestError doesn't have 'details' property
                    print("🔴 Supabase error hint: \(supabaseError.hint ?? "unknown")")
                }
                
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .postUploadFailed,
                        object: nil,
                        userInfo: ["error": error.localizedDescription]
                    )
                }
            }
        }
    }
    
    private func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw PostError.imageProcessingFailed
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "posts/\(fileName)"
        
        print("🔵 画像アップロード開始: \(filePath)")
        
        // Supabase Storageにアップロード
        _ = try await supabase.storage
            .from("user-uploads")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        // 公開URLを構築
        let projectUrl = SecureConfig.shared.supabaseURL
        let publicUrl = "\(projectUrl)/storage/v1/object/public/user-uploads/\(filePath)"
        
        print("✅ 画像アップロード完了: \(publicUrl)")
        return publicUrl
    }
    
    private func uploadVideo(_ videoURL: URL) async throws -> String {
        // 動画データを読み込む
        let videoData = try Data(contentsOf: videoURL)
        
        let fileName = "\(UUID().uuidString).mp4"
        let filePath = "posts/\(fileName)"
        
        print("🔵 動画アップロード開始: \(filePath)")
        
        // Supabase Storageにアップロード
        _ = try await supabase.storage
            .from("user-uploads")
            .upload(
                filePath,
                data: videoData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        // 公開URLを構築
        let projectUrl = SecureConfig.shared.supabaseURL
        let publicUrl = "\(projectUrl)/storage/v1/object/public/user-uploads/\(filePath)"
        
        print("✅ 動画アップロード完了: \(publicUrl)")
        return publicUrl
    }
    
    private func createPostRecord(userId: String, mediaUrl: String) async throws {
        struct NewPost: Encodable {
            let user_id: UUID
            let media_url: String
            let media_type: String
            let media_width: Double?
            let media_height: Double?
            let caption: String?
            let location_name: String?
            let latitude: Double?
            let longitude: Double?
            let is_public: Bool
        }
        
        // Get media dimensions
        var mediaDimensions: (width: Double, height: Double)? = nil
        if let image = selectedImage {
            let width = Double(image.size.width)
            let height = Double(image.size.height)
            let aspectRatio = width / height
            mediaDimensions = (width: width, height: height)
            print("🟢 Image dimensions: \(width) x \(height) (aspect ratio: \(String(format: "%.2f", aspectRatio)))")
            print("🟢 Would be displayed as: \(aspectRatio >= 1.3 ? "landscape" : "square")")
        }
        
        let newPost = NewPost(
            user_id: UUID(uuidString: userId)!,
            media_url: mediaUrl,
            media_type: mediaType.rawValue,
            media_width: mediaDimensions?.width,
            media_height: mediaDimensions?.height,
            caption: caption.isEmpty ? nil : caption,
            location_name: locationName.isEmpty ? nil : locationName,
            latitude: latitude,
            longitude: longitude,
            is_public: isPublic
        )
        
        print("🔵 Creating post record: \(newPost)")
        
        // Check current session before insert
        do {
            let session = try await supabase.auth.session
            print("🔵 Current session user ID: \(session.user.id)")
            print("🔵 Session access token exists: \(!session.accessToken.isEmpty)")
        } catch {
            print("❌ No valid session: \(error)")
            throw PostError.uploadFailed
        }
        
        try await supabase
            .from("posts")
            .insert(newPost)
            .execute()
    }
    
    // 動画のサムネイル生成
    // generateThumbnail関数を更新（iOS 18対応）
    func generateThumbnail(from videoURL: URL) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL) // 修正: AVAsset → AVURLAsset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        
        // iOS 18対応の非同期メソッドを使用
        return await withCheckedContinuation { continuation in
            imageGenerator.generateCGImageAsynchronously(for: time) { cgImage, actualTime, error in
                if let cgImage = cgImage {
                    continuation.resume(returning: UIImage(cgImage: cgImage))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // ビデオの寸法を取得するヘルパーメソッド
    private func getVideoDimensions(from videoURL: URL) async -> (width: Double, height: Double)? {
        let asset = AVURLAsset(url: videoURL)
        
        do {
            // ビデオトラックを取得
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else {
                print("❌ No video track found")
                return nil
            }
            
            // ナチュラルサイズを取得
            let naturalSize = try await videoTrack.load(.naturalSize)
            
            // トランスフォームを考慮（回転など）
            let transform = try await videoTrack.load(.preferredTransform)
            let size = naturalSize.applying(transform)
            
            let width = abs(size.width)
            let height = abs(size.height)
            
            print("🟢 Video natural size: \(naturalSize)")
            print("🟢 Video transform: \(transform)")
            print("🟢 Video final size: \(width) x \(height)")
            
            return (width: Double(width), height: Double(height))
        } catch {
            print("❌ Failed to get video dimensions: \(error)")
            return nil
        }
    }
}

enum PostError: LocalizedError {
    case imageProcessingFailed
    case uploadFailed
    case noMediaSelected
    
    var errorDescription: String? {
        switch self {
        case .imageProcessingFailed:
            return "Image processing failed"
        case .uploadFailed:
            return "Upload failed"
        case .noMediaSelected:
            return "Please select an image or video"
        }
    }
}

