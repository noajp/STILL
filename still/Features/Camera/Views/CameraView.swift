//======================================================================
// MARK: - CameraView（フィルムカメラ機能）
// Path: still/Features/Camera/Views/CameraView.swift
//======================================================================
import SwiftUI
@preconcurrency import AVFoundation

struct CameraView: View {
    @Namespace private var filmAnimationNamespace
    @State private var selectedFilm: Film?
    @State private var isFilmLoaded = false
    @State private var isShutterEnabled = false
    @StateObject private var cameraManager = CameraManager()
    
    let films: [Film] = [
        Film(id: "1", name: "Classic", color: Color.orange),
        Film(id: "2", name: "Noir", color: Color.gray),
        Film(id: "3", name: "Vivid", color: Color.blue),
        Film(id: "4", name: "Vintage", color: Color.brown)
    ]
    
    var body: some View {
        ZStack {
            // カメラプレビュー
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
            
            // オーバーレイUI
            VStack {
                // 上部のフィルム装填エリア
                HStack {
                    Spacer()
                    
                    if let film = selectedFilm {
                        FilmLoadedView(
                            film: film,
                            namespace: filmAnimationNamespace,
                            isFilmLoaded: $isFilmLoaded,
                            isShutterEnabled: $isShutterEnabled
                        )
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // シャッターボタン
                ShutterButton(isEnabled: isShutterEnabled) {
                    cameraManager.takePhoto()
                }
                .padding(.bottom, 30)
                
                // 下部のフィルム選択UI
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(films) { film in
                            if selectedFilm?.id != film.id {
                                FilmCylinderView(film: film)
                                    .matchedGeometryEffect(id: film.id, in: filmAnimationNamespace)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            // リセット
                                            isFilmLoaded = false
                                            isShutterEnabled = false
                                            selectedFilm = film
                                        }
                                    }
                            } else {
                                // 選択されたフィルムのプレースホルダー
                                FilmCylinderView(film: film)
                                    .opacity(0.3)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
                .background(
                    LinearGradient(
                        colors: [Color.black.opacity(0), Color.black.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .onAppear {
            cameraManager.checkPermissions()
        }
    }
}

// MARK: - Film Model
struct Film: Identifiable {
    let id: String
    let name: String
    let color: Color
}

// MARK: - Film Cylinder View
struct FilmCylinderView: View {
    let film: Film
    
    var body: some View {
        VStack(spacing: 8) {
            // フィルムケース
            ZStack {
                // 円柱の側面
                RoundedRectangle(cornerRadius: 15)
                    .fill(
                        LinearGradient(
                            colors: [film.color.opacity(0.8), film.color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 50, height: 80)
                
                // 上部のキャップ
                Ellipse()
                    .fill(film.color.opacity(0.9))
                    .frame(width: 50, height: 20)
                    .offset(y: -30)
                
                // ラベル
                Text(film.name)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(-90))
            }
            .shadow(radius: 5)
            
            // フィルム名
            Text(film.name)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Film Loaded View
struct FilmLoadedView: View {
    let film: Film
    let namespace: Namespace.ID
    @Binding var isFilmLoaded: Bool
    @Binding var isShutterEnabled: Bool
    
    @State private var pullOffset: CGFloat = 0
    @State private var filmTailHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // 装填されたフィルムケース
            FilmCylinderView(film: film)
                .matchedGeometryEffect(id: film.id, in: namespace)
                .scaleEffect(1.2)
            
            // 垂れ下がるフィルム
            if isFilmLoaded {
                // フィルムの先端
                VStack(spacing: 0) {
                    // フィルム本体
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.black, Color.black.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 35, height: filmTailHeight)
                    
                    // つまみ部分
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.orange)
                        .frame(width: 40, height: 20)
                        .overlay(
                            Text("PULL")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.black)
                        )
                }
                .offset(y: pullOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                pullOffset = value.translation.height
                                filmTailHeight = 50 + value.translation.height * 0.5
                            }
                        }
                        .onEnded { value in
                            if pullOffset > 80 {
                                withAnimation(.spring()) {
                                    isShutterEnabled = true
                                    filmTailHeight = 100
                                }
                            } else {
                                withAnimation(.spring()) {
                                    pullOffset = 0
                                    filmTailHeight = 50
                                }
                            }
                        }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isFilmLoaded = true
                    filmTailHeight = 50
                }
            }
        }
    }
}

// MARK: - Shutter Button
struct ShutterButton: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 外側のリング
                Circle()
                    .stroke(
                        isEnabled ? Color.white : Color.gray,
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                
                // 内側のボタン
                Circle()
                    .fill(isEnabled ? Color.white : Color.gray.opacity(0.5))
                    .frame(width: 65, height: 65)
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Camera Preview View (Placeholder)
// 現在は使用されていない - Rectangleで代替

// MARK: - Camera Manager
@MainActor
class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, @unchecked Sendable {
    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    @Published var capturedImage: UIImage?
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    Task { @MainActor in
                        self?.setupCamera { _ in }
                    }
                }
            }
        default:
            // Handle denied or restricted
            break
        }
    }
    
    func setupCamera(completion: @MainActor @escaping (AVCaptureVideoPreviewLayer) -> Void) {
        let session = AVCaptureSession()
        session.beginConfiguration()
        
        // カメラデバイスの設定
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        // 写真出力の設定
        let output = AVCapturePhotoOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            photoOutput = output
        }
        
        session.commitConfiguration()
        captureSession = session
        
        // プレビューレイヤーの作成
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        // セッション開始
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
        
        Task { @MainActor in
            completion(previewLayer)
        }
    }
    
    func takePhoto() {
        guard let photoOutput = photoOutput else { return }
        
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    nonisolated func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }
        
        Task { @MainActor [weak self] in
            self?.capturedImage = image
            // TODO: Apply film filter and save to photo library
        }
    }
}