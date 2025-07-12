//======================================================================
// MARK: - MapView（写真共有アプリ版）
// Path: foodai/Features/Map/Views/MapView.swift
//======================================================================
import SwiftUI
import MapKit

@MainActor
class MapViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var searchText = ""
    @Published var isLoading = false
    
    private let postService = PostService()
    
    init() {
        loadPostsWithLocation()
    }
    
    func loadPostsWithLocation() {
        Task {
            do {
                let allPosts = try await postService.fetchFeedPosts()
                self.posts = allPosts.filter { $0.latitude != nil && $0.longitude != nil }
            } catch {
                print("❌ 位置情報付き投稿の取得に失敗: \(error)")
            }
        }
    }
    
    func toggleLike(for post: Post) {
        Task {
            do {
                let isNowLiked = try await postService.toggleLike(postId: post.id, userId: "current-user-id")
                
                // 投稿のいいね状態を更新
                if let index = posts.firstIndex(where: { $0.id == post.id }) {
                    posts[index].isLikedByMe = isNowLiked
                    posts[index].likeCount += isNowLiked ? 1 : -1
                }
            } catch {
                print("❌ いいね操作に失敗: \(error)")
            }
        }
    }
}

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var isMapMoving = false
    @State private var dragGestureActive = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // iOS 17+の新しいMap構文
                Map(position: $cameraPosition) {
                    ForEach(viewModel.posts) { post in
                        if let lat = post.latitude,
                           let lng = post.longitude {
                            Annotation(post.locationName ?? "写真", coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                PhotoMapPin(post: post, onLikeTapped: { post in
                                    viewModel.toggleLike(for: post)
                                })
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .ignoresSafeArea(.all)
                .onMapCameraChange(frequency: .continuous) { _ in
                    isMapMoving = true
                }
                .onMapCameraChange(frequency: .onEnd) { _ in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        isMapMoving = false
                    }
                }
                
                // 検索バー
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        TextField("場所を検索", text: $viewModel.searchText)
                            .foregroundColor(MinimalDesign.Colors.primary)
                    }
                    .padding()
                    .background(
                        MinimalDesign.Colors.background.opacity(
                            isMapMoving ? 0.3 : 0.8
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 2)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .animation(.easeInOut(duration: 0.3), value: isMapMoving)
                
                // 現在地ボタン
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            // TODO: 現在地に移動
                            print("現在地に移動")
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(MinimalDesign.Colors.background)
                                .padding()
                                .background(MinimalDesign.Colors.primary)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(MinimalDesign.Colors.accentRed)
    }
}

// 写真のマップピン
struct PhotoMapPin: View {
    let post: Post
    let onLikeTapped: (Post) -> Void
    
    var body: some View {
        Button(action: {}) {
            AsyncImage(url: URL(string: post.mediaUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Rectangle())
            .overlay(
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(radius: 3)
        }
    }
}

// 写真のクイックビュー
struct PhotoQuickView: View {
    let post: Post
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: post.mediaUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(1, contentMode: .fit)
                }
                .frame(maxHeight: 300)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(post.user?.username ?? "unknown")
                            .font(.headline)
                        Spacer()
                    }
                    
                    if let caption = post.caption {
                        Text(caption)
                            .font(.body)
                    }
                    
                    if let locationName = post.locationName {
                        Label(locationName, systemImage: "location")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("写真")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}
