//======================================================================
// MARK: - CreatePostViewModel.swift
// Purpose: View model for post creation (投稿作成のビューモデル)
// Path: still/Features/CreatePost/ViewModels/CreatePostViewModel.swift
//======================================================================
import SwiftUI
import PhotosUI
@preconcurrency import AVFoundation
import Supabase

/// Extension for post upload-related notification names
extension Notification.Name {
    /// Notification sent when post upload begins
    static let postUploadStarted = Notification.Name("postUploadStarted")
    /// Notification sent with upload progress updates
    static let postUploadProgress = Notification.Name("postUploadProgress")
    /// Notification sent when post upload completes successfully
    static let postUploadCompleted = Notification.Name("postUploadCompleted")
    /// Notification sent when post upload fails
    static let postUploadFailed = Notification.Name("postUploadFailed")
}

/// ViewModel for managing post creation workflow including media upload and post submission
/// Handles image/video processing, location data, and background upload with progress tracking
@MainActor
class CreatePostViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Selected image for the post
    @Published var selectedImage: UIImage?
    
    /// Selected video URL for the post
    @Published var selectedVideoURL: URL?
    
    /// Type of media being posted (photo or video)
    @Published var mediaType: Post.MediaType = .photo
    
    /// Post caption text
    @Published var caption = ""
    
    /// Location name for the post
    @Published var locationName = ""
    
    /// Loading state indicator
    @Published var isLoading = false
    
    /// Whether to show error alert
    @Published var showError = false
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether post creation was successful
    @Published var isPostCreated = false
    
    /// Upload progress percentage (0.0 to 1.0)
    @Published var uploadProgress: Double = 0
    
    /// Latitude coordinate for location
    @Published var latitude: Double?
    
    /// Longitude coordinate for location
    @Published var longitude: Double?
    
    /// Whether the post should be publicly visible
    @Published var isPublic = true
    
    // MARK: - Dependencies
    
    /// Service for post operations
    private let postService = PostService()
    
    /// Supabase client for database and storage operations
    private let supabase = SupabaseManager.shared.client
    
    // MARK: - Computed Properties
    
    /// Whether the user can create a post (has selected media)
    var canPost: Bool {
        selectedImage != nil || selectedVideoURL != nil
    }
    
    // MARK: - Public Methods
    
    /// Creates a post synchronously with UI feedback
    /// Uploads media and creates post record in sequence with progress updates
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
            // 1. Upload media to storage
            uploadProgress = 0.3
            let mediaUrl: String
            if let image = selectedImage {
                mediaUrl = try await uploadImage(image)
            } else if let videoURL = selectedVideoURL {
                mediaUrl = try await uploadVideo(videoURL)
            } else {
                throw PostError.noMediaSelected
            }
            
            // 2. Create post record in database
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
            print("❌ Post creation error: \(error)")
            print("❌ Error details: \(error)")
            print("❌ Error type: \(type(of: error))")
        }
        
        isLoading = false
    }
    
    /// Creates a post in the background without blocking the UI
    /// Uses detached task and notifications to communicate progress and completion
    /// Validates user authentication and profile before proceeding with upload
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
                    .from("profiles")
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
                    let updated_at: String?
                    
                    init(user_id: UUID, media_url: String, media_type: String, media_width: Double?, media_height: Double?, caption: String?, location_name: String?, latitude: Double?, longitude: Double?, is_public: Bool) {
                        self.user_id = user_id
                        self.media_url = media_url
                        self.media_type = media_type
                        self.media_width = media_width
                        self.media_height = media_height
                        self.caption = caption
                        self.location_name = location_name
                        self.latitude = latitude
                        self.longitude = longitude
                        self.is_public = is_public
                        self.updated_at = ISO8601DateFormatter().string(from: Date())
                    }
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
                    .select("""
                        id,
                        user_id,
                        media_url,
                        media_type,
                        thumbnail_url,
                        media_width,
                        media_height,
                        caption,
                        location_name,
                        latitude,
                        longitude,
                        is_public,
                        like_count,
                        comment_count,
                        created_at,
                        updated_at
                    """)
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
        
        // サムネイルを作成してアップロード
        let imageProcessor = ImageProcessor()
        let thumbnails = imageProcessor.generateThumbnails(image)
        
        // サムネイルをアップロード
        for (size, thumbnail) in thumbnails {
            guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) else { continue }
            
            let thumbnailFileName = "\(UUID().uuidString)_\(size).jpg"
            let thumbnailFilePath = "thumbnails/\(thumbnailFileName)"
            
            _ = try await supabase.storage
                .from("user-uploads")
                .upload(
                    thumbnailFilePath,
                    data: thumbnailData,
                    options: FileOptions(contentType: "image/jpeg")
                )
        }
        
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
            let updated_at: String?
            
            init(user_id: UUID, media_url: String, media_type: String, media_width: Double?, media_height: Double?, caption: String?, location_name: String?, latitude: Double?, longitude: Double?, is_public: Bool) {
                self.user_id = user_id
                self.media_url = media_url
                self.media_type = media_type
                self.media_width = media_width
                self.media_height = media_height
                self.caption = caption
                self.location_name = location_name
                self.latitude = latitude
                self.longitude = longitude
                self.is_public = is_public
                self.updated_at = ISO8601DateFormatter().string(from: Date())
            }
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
    
    // MARK: - Video Processing
    
    /// Generates a thumbnail image from a video URL
    /// Updated for iOS 18 compatibility using async/await patterns
    /// - Parameter videoURL: Local URL of the video
    /// - Returns: Thumbnail UIImage or nil if generation fails
    func generateThumbnail(from videoURL: URL) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let time = CMTime(seconds: 1, preferredTimescale: 1)
        
        // Use iOS 18 compatible async method
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
    
    /// Helper method to extract video dimensions accounting for transformations
    /// - Parameter videoURL: Local URL of the video
    /// - Returns: Tuple of (width, height) or nil if extraction fails
    private func getVideoDimensions(from videoURL: URL) async -> (width: Double, height: Double)? {
        let asset = AVURLAsset(url: videoURL)
        
        do {
            // Load video tracks from the asset
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else {
                print("❌ No video track found")
                return nil
            }
            
            // Get natural size of the video
            let naturalSize = try await videoTrack.load(.naturalSize)
            
            // Apply transform to account for rotation
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

// MARK: - Error Types

/// Errors that can occur during post creation process
enum PostError: LocalizedError {
    /// Failed to process or compress image data
    case imageProcessingFailed
    /// Failed to upload media or create post record
    case uploadFailed
    /// User attempted to create post without selecting media
    case noMediaSelected
    
    /// Human-readable error descriptions
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

