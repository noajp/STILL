//======================================================================
// MARK: - CustomCameraView.swift
// Purpose: SwiftUI view component (CustomCameraViewビューコンポーネント)
// Path: still/Features/Camera/Views/CustomCameraView.swift
//======================================================================
//
//  CustomCameraView.swift
//  tete
//
//  カスタムカメラUI実装
//

import SwiftUI
import AVFoundation
import CoreImage

struct CustomCameraView: View {
    // MARK: - Properties
    @StateObject private var viewModel = CustomCameraViewModel()
    @Environment(\.dismiss) var dismiss
    let onPhotoTaken: (UIImage) -> Void
    
    @State private var selectedFilter: FilterType = .none
    @State private var showingFilterSelection = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ナビゲーションエリア
                navigationArea
                
                // カメラプレビューエリア
                cameraPreviewArea
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastZoomScale
                                lastZoomScale = value
                                let newScale = zoomScale * delta
                                zoomScale = min(max(newScale, 1.0), 10.0)
                                viewModel.setZoomLevel(zoomScale)
                            }
                            .onEnded { _ in
                                lastZoomScale = 1.0
                            }
                    )
                
                // コントロールエリア
                controlsArea
            }
            
            // フィルター選択シート
            if showingFilterSelection {
                filterSelectionOverlay
            }
        }
        .onAppear {
            viewModel.startSession()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .alert("カメラエラー", isPresented: $viewModel.showError) {
            Button("OK") { dismiss() }
        } message: {
            Text(viewModel.errorMessage ?? "カメラにアクセスできません")
        }
    }
    
    // MARK: - Views
    
    private var navigationArea: some View {
        HStack {
            Button("キャンセル") {
                dismiss()
            }
            .foregroundColor(.white)
            .padding(.leading)
            
            Spacer()
            
            Text("カメラ")
                .foregroundColor(.white)
                .font(.headline)
            
            Spacer()
            
            Button(action: { viewModel.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .foregroundColor(.white)
                    .font(.title2)
            }
            .padding(.trailing)
        }
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
    }
    
    private var cameraPreviewArea: some View {
        GeometryReader { geometry in
            CustomCameraPreview(
                session: viewModel.session,
                currentFilter: selectedFilter
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            
            // フォーカス指示
            if let focusPoint = viewModel.focusPoint {
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .frame(width: 80, height: 80)
                    .position(focusPoint)
                    .animation(.easeInOut(duration: 0.3), value: focusPoint)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            viewModel.focusAt(point: location)
        }
    }
    
    private var controlsArea: some View {
        VStack(spacing: 20) {
            // フィルタープレビュー
            filterPreviewArea
            
            // メインコントロール
            HStack {
                // ギャラリーボタン
                Button(action: {}) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "photo.on.rectangle")
                                .foregroundColor(.white)
                        )
                }
                
                Spacer()
                
                // シャッターボタン
                Button(action: {
                    viewModel.capturePhoto { image in
                        onPhotoTaken(image)
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 60, height: 60)
                            )
                    }
                }
                .scaleEffect(viewModel.isCapturing ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: viewModel.isCapturing)
                
                Spacer()
                
                // フラッシュボタン
                Button(action: { viewModel.toggleFlash() }) {
                    Image(systemName: viewModel.flashMode == .on ? "bolt.fill" : "bolt.slash")
                        .foregroundColor(viewModel.flashMode == .on ? .yellow : .white)
                        .font(.title2)
                        .frame(width: 50, height: 50)
                }
            }
            .padding(.horizontal, 30)
        }
        .padding(.bottom, 30)
        .background(Color.black.opacity(0.3))
    }
    
    private var filterPreviewArea: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(FilterType.allCases.prefix(8)) { filterType in
                    Button(action: {
                        selectedFilter = filterType
                        viewModel.setCurrentFilter(filterType)
                    }) {
                        VStack(spacing: 4) {
                            Circle()
                                .fill(selectedFilter == filterType ? Color.white : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(filterType.rawValue.prefix(2)))
                                        .font(.caption)
                                        .foregroundColor(selectedFilter == filterType ? .black : .white)
                                )
                            
                            Text(filterType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // もっと見るボタン
                Button(action: {
                    showingFilterSelection = true
                }) {
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "ellipsis")
                                    .foregroundColor(.white)
                            )
                        
                        Text("もっと")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var filterSelectionOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    showingFilterSelection = false
                }
            
            VStack {
                Text("フィルターを選択")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(FilterType.allCases) { filterType in
                        Button(action: {
                            selectedFilter = filterType
                            viewModel.setCurrentFilter(filterType)
                            showingFilterSelection = false
                        }) {
                            VStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedFilter == filterType ? Color.white : Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Text(String(filterType.rawValue.prefix(2)))
                                            .font(.title2)
                                            .foregroundColor(selectedFilter == filterType ? .black : .white)
                                    )
                                
                                Text(filterType.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                }
                .padding()
                
                Button("閉じる") {
                    showingFilterSelection = false
                }
                .foregroundColor(.white)
                .padding()
            }
            .background(Color.black.opacity(0.9))
            .cornerRadius(20)
            .padding()
        }
    }
}

#if DEBUG
struct CustomCameraView_Previews: PreviewProvider {
    static var previews: some View {
        CustomCameraView { _ in }
    }
}
#endif