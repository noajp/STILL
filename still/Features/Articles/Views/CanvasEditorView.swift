//======================================================================
// MARK: - CanvasEditorView.swift
// Purpose: Canvas editor for articles with templates, images, and text
// Path: still/Features/Articles/Views/CanvasEditorView.swift
//======================================================================

import SwiftUI
import PhotosUI
import UIKit

struct CanvasEditorView: View {
    let initialTemplate: CanvasTemplate?
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = CanvasEditorViewModel()
    
    @State private var showTemplateSelector: Bool
    @State private var showTextEditor = false
    @State private var showImagePicker = false
    @State private var showImageEditor = false
    @State private var selectedImageItem: PhotosPickerItem?
    @State private var canvasElements: [CanvasElement] = []
    @State private var selectedElement: CanvasElement?
    @State private var editingElement: CanvasElement? // 編集中の要素を保存
    @State private var dragOffset = CGSize.zero
    @State private var canvasSize: CGSize = CGSize(width: 400, height: 400) // デフォルトサイズ
    @State private var canvasBackgroundColor: Color = .white
    
    init(initialTemplate: CanvasTemplate? = nil) {
        self.initialTemplate = initialTemplate
        // 初期テンプレートがある場合はテンプレート選択をスキップ
        self._showTemplateSelector = State(initialValue: initialTemplate == nil)
    }
    
    var body: some View {
        ZStack {
            // クリーム色の編集画面背景
            Color(red: 0.98, green: 0.96, blue: 0.92)
                .ignoresSafeArea()
            
            // Scrollable Canvas Container
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    // Canvas Background
                    canvasBackground
                    
                    // Canvas Elements
                    ForEach(canvasElements, id: \.id) { element in
                CanvasElementView(
                    element: element,
                    isSelected: selectedElement?.id == element.id,
                    onTap: { 
                        selectedElement = element
                        print("要素をタップ: \(element.type), ID: \(element.id)")
                    },
                    onDragChanged: { offset in
                        updateElementPosition(element: element, offset: offset)
                    },
                    onResizeChanged: { offset in
                        resizeElement(element: element, offset: offset)
                    },
                    onDelete: {
                        deleteElement(element)
                    },
                    onEdit: {
                        selectedElement = element
                        editingElement = element // 編集中の要素を保存
                        print("編集ボタンをタップ: \(element.type), ID: \(element.id)")
                        if element.type == .image {
                            DispatchQueue.main.async {
                                showImageEditor = true
                            }
                        } else if element.type == .text {
                            DispatchQueue.main.async {
                                showTextEditor = true
                            }
                        }
                    },
                    onCropChanged: { rect in
                        updateElementCrop(element: element, cropRect: rect)
                    },
                    onCropToggle: {
                        toggleElementCropping(element)
                    }
                )
            }
                }
                .frame(minWidth: scrollFrameWidth,
                       minHeight: scrollFrameHeight)
            }
            .clipped()
            
            // Floating Add Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingAddButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 100)
                }
            }
            
            // Top Navigation
            VStack {
                topNavigationBar
                Spacer()
            }
        }
        .onTapGesture {
            selectedElement = nil
        }
        .sheet(isPresented: $showTemplateSelector) {
            TemplateSelectionSheet(onTemplateSelected: { template in
                applyTemplate(template)
                showTemplateSelector = false
            })
        }
        .sheet(isPresented: $showTextEditor) {
            TextEditorSheet(
                initialText: editingElement?.type == .text ? editingElement?.content ?? "" : "",
                onTextAdded: { text in
                    print("テキストエディタから完了: \(text)")
                    if let element = editingElement, element.type == .text {
                        print("既存テキスト要素を更新")
                        updateElementContent(element: element, newContent: text)
                    } else {
                        print("新しいテキスト要素を追加")
                        addTextElement(text)
                    }
                    editingElement = nil // 編集完了後にクリア
                    showTextEditor = false
                }
            )
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedImageItem)
        .onChange(of: selectedImageItem) { _, newItem in
            if let newItem = newItem {
                addImageElement(newItem)
            }
        }
        .sheet(isPresented: $showImageEditor) {
            if let element = selectedElement, element.type == .image {
                ImageEditorSheet(
                    element: element,
                    onSave: { updatedElement in
                        updateElement(updatedElement)
                        showImageEditor = false
                    }
                )
            }
        }
        .onAppear {
            // 初期テンプレートがあれば適用
            if let template = initialTemplate {
                applyTemplate(template)
            }
            print("onAppear - canvasElements数: \(canvasElements.count)")
        }
    }
    
    // MARK: - Canvas Background
    private var canvasBackground: some View {
        Rectangle()
            .fill(canvasBackgroundColor)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .overlay(
                // 薄いグリッドパターン（オプション）
                Path { path in
                    let spacing: CGFloat = 20
                    let width = canvasSize.width
                    let height = canvasSize.height
                    
                    for i in stride(from: 0, to: width, by: spacing) {
                        path.move(to: CGPoint(x: i, y: 0))
                        path.addLine(to: CGPoint(x: i, y: height))
                    }
                    
                    for i in stride(from: 0, to: height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: i))
                        path.addLine(to: CGPoint(x: width, y: i))
                    }
                }
                .stroke(Color.gray.opacity(0.05), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: isSquareStyle ? 16 : 8))
            .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
    
    // 正方形スタイルかどうかを判定
    private var isSquareStyle: Bool {
        canvasSize.width == canvasSize.height
    }
    
    // 全画面表示スタイルかどうかを判定
    private var isFullScreenStyle: Bool {
        // 雑誌スタイル(3:4)または横長記事スタイル(16:9)
        let ratio = canvasSize.width / canvasSize.height
        return ratio > 1.5 || ratio < 0.9 // 横長または縦長
    }
    
    // ScrollViewのフレームサイズを計算
    private var scrollFrameWidth: CGFloat {
        if isFullScreenStyle {
            return max(canvasSize.width + 40, UIScreen.main.bounds.width)
        } else {
            // 正方形スタイルは余白を多めに
            return max(canvasSize.width + 120, UIScreen.main.bounds.width)
        }
    }
    
    private var scrollFrameHeight: CGFloat {
        if isFullScreenStyle {
            return max(canvasSize.height + 160, UIScreen.main.bounds.height)
        } else {
            // 正方形スタイルは余白を多めに
            return max(canvasSize.height + 240, UIScreen.main.bounds.height)
        }
    }
    
    // MARK: - Top Navigation
    private var topNavigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            // 背景色変更ボタン
            Menu {
                Button("白") { canvasBackgroundColor = .white }
                Button("クリーム") { canvasBackgroundColor = Color(red: 0.99, green: 0.97, blue: 0.94) }
                Button("淡いグレー") { canvasBackgroundColor = Color(red: 0.95, green: 0.95, blue: 0.95) }
                Button("淡いブルー") { canvasBackgroundColor = Color(red: 0.94, green: 0.97, blue: 1.0) }
                Button("淡いピンク") { canvasBackgroundColor = Color(red: 1.0, green: 0.94, blue: 0.96) }
            } label: {
                Image(systemName: "paintpalette")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Canvas Editor")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            Button(action: publishCanvas) {
                Text("Publish")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(canvasElements.isEmpty ? .gray : Color(red: 0.949, green: 0.098, blue: 0.020))
            }
            .disabled(canvasElements.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background(Color.white.opacity(0.9))
    }
    
    // MARK: - Floating Add Button
    private var floatingAddButton: some View {
        Menu {
            // 初期テンプレートがない場合のみテンプレート選択を表示
            if initialTemplate == nil {
                Button(action: { showTemplateSelector = true }) {
                    Label("Template", systemImage: "doc.text")
                }
            }
            
            Button(action: { showImagePicker = true }) {
                Label("Photo", systemImage: "photo")
            }
            
            Button(action: { 
                selectedElement = nil // 新規追加の場合はselectedElementをnilに
                editingElement = nil // 編集中の要素もnilに
                DispatchQueue.main.async {
                    showTextEditor = true
                }
            }) {
                Label("Text", systemImage: "textformat")
            }
            
            Button(action: { addLineElement() }) {
                Label("Line", systemImage: "minus")
            }
            
            Button(action: { addShapeElement() }) {
                Label("Shape", systemImage: "rectangle")
            }
        } label: {
            Circle()
                .fill(Color(red: 0.949, green: 0.098, blue: 0.020))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Actions
    private func applyTemplate(_ template: CanvasTemplate) {
        canvasElements.removeAll()
        canvasElements = template.elements
        canvasSize = template.canvasSize
        print("テンプレート適用: \(template.name), 要素数: \(template.elements.count)")
    }
    
    private func addTextElement(_ text: String) {
        let element = CanvasElement(
            type: .text,
            content: text,
            position: CGPoint(x: 200, y: 300),
            size: CGSize(width: 200, height: 50)
        )
        canvasElements.append(element)
    }
    
    private func addImageElement(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let element = CanvasElement(
                    type: .image,
                    content: "",
                    position: CGPoint(x: 150, y: 200),
                    size: CGSize(width: 150, height: 150),
                    imageData: data,
                    rotation: 0,
                    cropRect: CGRect(x: 0, y: 0, width: 1, height: 1),
                    isCropping: false
                )
                await MainActor.run {
                    canvasElements.append(element)
                }
            }
        }
    }
    
    private func updateElementPosition(element: CanvasElement, offset: CGSize) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            canvasElements[index].position = CGPoint(
                x: element.position.x + offset.width,
                y: element.position.y + offset.height
            )
        }
    }
    
    private func resizeElement(element: CanvasElement, offset: CGSize) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            let newWidth = max(50, element.size.width + offset.width)
            let newHeight = max(50, element.size.height + offset.height)
            canvasElements[index].size = CGSize(width: newWidth, height: newHeight)
        }
    }
    
    private func deleteElement(_ element: CanvasElement) {
        canvasElements.removeAll { $0.id == element.id }
        selectedElement = nil
    }
    
    private func updateElement(_ element: CanvasElement) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            canvasElements[index] = element
        }
    }
    
    private func updateElementContent(element: CanvasElement, newContent: String) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            canvasElements[index].content = newContent
        }
    }
    
    private func updateElementCrop(element: CanvasElement, cropRect: CGRect) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            canvasElements[index].cropRect = cropRect
        }
    }
    
    private func applyCrop(to element: CanvasElement) {
        guard let index = canvasElements.firstIndex(where: { $0.id == element.id }),
              let imageData = element.imageData,
              let uiImage = UIImage(data: imageData) else { return }
        
        // Convert crop rect (normalized 0-1) to pixel coordinates
        let cropRect = CGRect(
            x: element.cropRect.minX * uiImage.size.width,
            y: element.cropRect.minY * uiImage.size.height,
            width: element.cropRect.width * uiImage.size.width,
            height: element.cropRect.height * uiImage.size.height
        )
        
        // Apply the crop
        if let croppedImage = uiImage.cropped(to: cropRect),
           let croppedData = croppedImage.pngData() {
            
            // Update the element with cropped image data
            canvasElements[index].imageData = croppedData
            canvasElements[index].size = CGSize(
                width: element.size.width * element.cropRect.width,
                height: element.size.height * element.cropRect.height
            )
            // Reset crop rect to full image since we've applied the crop
            canvasElements[index].cropRect = CGRect(x: 0, y: 0, width: 1, height: 1)
            canvasElements[index].isCropping = false
        }
    }
    
    private func toggleElementCropping(_ element: CanvasElement) {
        if let index = canvasElements.firstIndex(where: { $0.id == element.id }) {
            if canvasElements[index].isCropping {
                // User is finishing crop mode - apply the crop
                applyCrop(to: element)
            } else {
                // User is starting crop mode
                canvasElements[index].isCropping = true
            }
        }
    }
    
    private func addLineElement() {
        let element = CanvasElement(
            type: .line,
            content: "",
            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
            size: CGSize(width: 100, height: 2)
        )
        canvasElements.append(element)
    }
    
    private func addShapeElement() {
        let element = CanvasElement(
            type: .shape,
            content: "",
            position: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2),
            size: CGSize(width: 80, height: 80)
        )
        canvasElements.append(element)
    }
    
    private func publishCanvas() {
        // TODO: Implement canvas publishing
        print("Publishing canvas with \(canvasElements.count) elements")
        dismiss()
    }
}

// MARK: - Canvas Element Model
struct CanvasElement: Identifiable, Equatable {
    let id = UUID()
    let type: ElementType
    var content: String
    var position: CGPoint
    var size: CGSize
    var imageData: Data?
    var rotation: Double = 0
    var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    var isCropping: Bool = false
    
    enum ElementType {
        case text
        case image
        case shape
        case line
    }
}

// MARK: - Canvas Element View
struct CanvasElementView: View {
    let element: CanvasElement
    let isSelected: Bool
    let onTap: () -> Void
    let onDragChanged: (CGSize) -> Void
    let onResizeChanged: ((CGSize) -> Void)?
    let onDelete: (() -> Void)?
    let onEdit: (() -> Void)?
    let onCropChanged: ((CGRect) -> Void)?
    let onCropToggle: (() -> Void)?
    
    @State private var dragOffset = CGSize.zero
    @State private var resizeOffset = CGSize.zero
    
    var body: some View {
        ZStack {
            // Main element content
            Group {
                switch element.type {
                case .text:
                    Text(element.content)
                        .font(.system(size: 16))
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(4)
                case .image:
                    if let imageData = element.imageData,
                       let uiImage = UIImage(data: imageData) {
                        // Base image
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: element.size.width + resizeOffset.width,
                                height: element.size.height + resizeOffset.height
                            )
                            .clipped()
                            .cornerRadius(8)
                    }
                case .shape:
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(
                            width: element.size.width + resizeOffset.width,
                            height: element.size.height + resizeOffset.height
                        )
                        .cornerRadius(4)
                        
                case .line:
                    Rectangle()
                        .fill(Color.black)
                        .frame(
                            width: element.size.width + resizeOffset.width,
                            height: 2 // 線の太さ
                        )
                }
            }
            .position(
                x: element.position.x + dragOffset.width,
                y: element.position.y + dragOffset.height
            )
            .rotationEffect(.degrees(element.rotation))
            
            // Crop overlay when in cropping mode
            if element.isCropping && element.type == .image {
                CropOverlayView(
                    cropRect: element.cropRect,
                    imageSize: CGSize(
                        width: element.size.width + resizeOffset.width,
                        height: element.size.height + resizeOffset.height
                    ),
                    onCropChanged: { rect in
                        onCropChanged?(rect)
                    }
                )
                .position(
                    x: element.position.x + dragOffset.width,
                    y: element.position.y + dragOffset.height
                )
            }

            // Selection overlay and controls
            if isSelected {
                // Debug: 選択状態であることをログに出力
                let _ = print("要素が選択状態: \(element.type), ID: \(element.id)")
                // Selection border
                Rectangle()
                    .stroke(Color.blue, lineWidth: 2)
                    .frame(
                        width: element.size.width + resizeOffset.width + 4,
                        height: element.size.height + resizeOffset.height + 4
                    )
                    .position(
                        x: element.position.x + dragOffset.width,
                        y: element.position.y + dragOffset.height
                    )
                
                // Delete button (top-left)
                Button(action: {
                    onDelete?()
                }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .position(
                    x: element.position.x + dragOffset.width - (element.size.width + resizeOffset.width) / 2 - 8,
                    y: element.position.y + dragOffset.height - (element.size.height + resizeOffset.height) / 2 - 8
                )
                
                // Edit/Crop button (top-right)
                if element.type == .image {
                    Button(action: {
                        onCropToggle?()
                    }) {
                        Circle()
                            .fill(element.isCropping ? Color.green : Color.blue)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: element.isCropping ? "checkmark" : "crop")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .position(
                        x: element.position.x + dragOffset.width + (element.size.width + resizeOffset.width) / 2 + 8,
                        y: element.position.y + dragOffset.height - (element.size.height + resizeOffset.height) / 2 - 8
                    )
                } else if element.type == .text {
                    // Edit button for text
                    Button(action: {
                        print("編集ボタンがタップされました - テキスト要素: \(element.id)")
                        onEdit?()
                    }) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .position(
                        x: element.position.x + dragOffset.width + (element.size.width + resizeOffset.width) / 2 + 8,
                        y: element.position.y + dragOffset.height - (element.size.height + resizeOffset.height) / 2 - 8
                    )
                }
                
                // Resize handle (bottom-right) - hide during cropping
                if !element.isCropping {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .position(
                            x: element.position.x + dragOffset.width + (element.size.width + resizeOffset.width) / 2,
                            y: element.position.y + dragOffset.height + (element.size.height + resizeOffset.height) / 2
                        )
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    resizeOffset = value.translation
                                }
                                .onEnded { value in
                                    onResizeChanged?(value.translation)
                                    resizeOffset = .zero
                                }
                        )
                }
            }
        }
        .onTapGesture {
            onTap()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    if !isSelected {
                        return
                    }
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if !isSelected {
                        return
                    }
                    onDragChanged(value.translation)
                    dragOffset = .zero
                }
        )
    }
}

// MARK: - Template Selection Sheet
struct TemplateSelectionSheet: View {
    let onTemplateSelected: (CanvasTemplate) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(CanvasTemplate.defaultTemplates, id: \.id) { template in
                        TemplatePreviewCard(template: template) {
                            onTemplateSelected(template)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("記事の形式を選択")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TemplatePreviewCard: View {
    let template: CanvasTemplate
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            // Preview area with aspect ratio
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(template.canvasSize.width / template.canvasSize.height, contentMode: .fit)
                .frame(height: 100)
                .overlay(
                    VStack(spacing: 4) {
                        Text(template.name)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(Int(template.canvasSize.width))×\(Int(template.canvasSize.height))")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            
            VStack(spacing: 2) {
                Text(template.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(template.description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Text Editor Sheet
struct TextEditorSheet: View {
    @State private var text: String
    let onTextAdded: (String) -> Void
    @Environment(\.dismiss) var dismiss
    private let isEditing: Bool
    
    init(initialText: String = "", onTextAdded: @escaping (String) -> Void) {
        self._text = State(initialValue: initialText)
        self.onTextAdded = onTextAdded
        self.isEditing = !initialText.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $text)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle(isEditing ? "Edit Text" : "Add Text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        onTextAdded(text)
                        dismiss()
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
    }
}

// MARK: - Canvas Template Model
struct CanvasTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let canvasSize: CGSize
    let elements: [CanvasElement]
    
    static let defaultTemplates: [CanvasTemplate] = [
        CanvasTemplate(
            name: "Instagram Post",
            description: "正方形（1:1）SNS投稿に最適",
            canvasSize: CGSize(width: 400, height: 400),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "タイトル",
                    position: CGPoint(x: 200, y: 80),
                    size: CGSize(width: 300, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "Magazine Cover",
            description: "雑誌表紙スタイル（3:4）",
            canvasSize: CGSize(width: 300, height: 400),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "MAGAZINE",
                    position: CGPoint(x: 150, y: 60),
                    size: CGSize(width: 250, height: 40)
                )
            ]
        ),
        CanvasTemplate(
            name: "Story Format",
            description: "ストーリー形式（9:16）",
            canvasSize: CGSize(width: 300, height: 533),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "ストーリー",
                    position: CGPoint(x: 150, y: 100),
                    size: CGSize(width: 200, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "Wide Article",
            description: "横長記事（16:9）",
            canvasSize: CGSize(width: 533, height: 300),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "記事タイトル",
                    position: CGPoint(x: 266, y: 80),
                    size: CGSize(width: 400, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "Newspaper",
            description: "新聞スタイル（4:5）",
            canvasSize: CGSize(width: 320, height: 400),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "新聞見出し",
                    position: CGPoint(x: 160, y: 70),
                    size: CGSize(width: 280, height: 40)
                )
            ]
        ),
        CanvasTemplate(
            name: "Blank Canvas",
            description: "自由なキャンバス（1:1）",
            canvasSize: CGSize(width: 400, height: 400),
            elements: []
        )
    ]
    
    // Article用のテンプレート
    static let articleTemplates: [CanvasTemplate] = [
        CanvasTemplate(
            name: "雑誌スタイル",
            description: "縦長レイアウト（3:4）",
            canvasSize: CGSize(width: 375, height: 500),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "タイトル",
                    position: CGPoint(x: 187, y: 80),
                    size: CGSize(width: 320, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "横長記事スタイル",
            description: "横長レイアウト（16:9）",
            canvasSize: CGSize(width: 600, height: 337),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "記事タイトル",
                    position: CGPoint(x: 300, y: 80),
                    size: CGSize(width: 500, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "正方形スタイル",
            description: "正方形レイアウト（1:1）",
            canvasSize: CGSize(width: 400, height: 400),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "タイトル",
                    position: CGPoint(x: 200, y: 80),
                    size: CGSize(width: 320, height: 50)
                )
            ]
        ),
        CanvasTemplate(
            name: "小説スタイル",
            description: "縦長テキスト重視（2:3）",
            canvasSize: CGSize(width: 350, height: 525),
            elements: [
                CanvasElement(
                    type: .text,
                    content: "小説タイトル",
                    position: CGPoint(x: 175, y: 80),
                    size: CGSize(width: 300, height: 50)
                ),
                CanvasElement(
                    type: .text,
                    content: "本文をここに入力してください...",
                    position: CGPoint(x: 175, y: 200),
                    size: CGSize(width: 300, height: 280)
                )
            ]
        )
    ]
}

// MARK: - Crop Overlay View
struct CropOverlayView: View {
    let cropRect: CGRect
    let imageSize: CGSize
    let onCropChanged: (CGRect) -> Void
    
    @State private var currentCropRect: CGRect
    @State private var isDragging = false
    
    init(cropRect: CGRect, imageSize: CGSize, onCropChanged: @escaping (CGRect) -> Void) {
        self.cropRect = cropRect
        self.imageSize = imageSize
        self.onCropChanged = onCropChanged
        self._currentCropRect = State(initialValue: cropRect)
    }
    
    private var cropFrame: CGRect {
        CGRect(
            x: currentCropRect.minX * imageSize.width - imageSize.width / 2,
            y: currentCropRect.minY * imageSize.height - imageSize.height / 2,
            width: currentCropRect.width * imageSize.width,
            height: currentCropRect.height * imageSize.height
        )
    }
    
    var body: some View {
        ZStack {
            // Dark overlay covering the entire image
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .frame(width: imageSize.width, height: imageSize.height)
            
            // Clear area for crop region
            Rectangle()
                .fill(Color.clear)
                .frame(width: cropFrame.width, height: cropFrame.height)
                .position(
                    x: imageSize.width / 2 + cropFrame.minX + cropFrame.width / 2,
                    y: imageSize.height / 2 + cropFrame.minY + cropFrame.height / 2
                )
                .blendMode(.destinationOut)
            
            // Crop frame border
            Rectangle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: cropFrame.width, height: cropFrame.height)
                .position(
                    x: imageSize.width / 2 + cropFrame.minX + cropFrame.width / 2,
                    y: imageSize.height / 2 + cropFrame.minY + cropFrame.height / 2
                )
            
            // Corner handles
            Group {
                // Top-left
                cropHandle(at: CGPoint(x: cropFrame.minX, y: cropFrame.minY)) { translation in
                    updateCropRect(corner: .topLeft, translation: translation)
                }
                
                // Top-right
                cropHandle(at: CGPoint(x: cropFrame.maxX, y: cropFrame.minY)) { translation in
                    updateCropRect(corner: .topRight, translation: translation)
                }
                
                // Bottom-left
                cropHandle(at: CGPoint(x: cropFrame.minX, y: cropFrame.maxY)) { translation in
                    updateCropRect(corner: .bottomLeft, translation: translation)
                }
                
                // Bottom-right
                cropHandle(at: CGPoint(x: cropFrame.maxX, y: cropFrame.maxY)) { translation in
                    updateCropRect(corner: .bottomRight, translation: translation)
                }
            }
        }
        .compositingGroup()
        .allowsHitTesting(true)
    }
    
    private func cropHandle(at position: CGPoint, onDrag: @escaping (CGSize) -> Void) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 16, height: 16)
            .position(
                x: imageSize.width / 2 + position.x,
                y: imageSize.height / 2 + position.y
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        onDrag(value.translation)
                    }
                    .onEnded { _ in
                        onCropChanged(currentCropRect)
                    }
            )
    }
    
    private enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    private func updateCropRect(corner: Corner, translation: CGSize) {
        let deltaX = translation.width / imageSize.width
        let deltaY = translation.height / imageSize.height
        
        var newRect = currentCropRect
        
        switch corner {
        case .topLeft:
            newRect.origin.x = max(0, min(currentCropRect.maxX - 0.1, currentCropRect.minX + deltaX))
            newRect.origin.y = max(0, min(currentCropRect.maxY - 0.1, currentCropRect.minY + deltaY))
            newRect.size.width = currentCropRect.maxX - newRect.minX
            newRect.size.height = currentCropRect.maxY - newRect.minY
            
        case .topRight:
            newRect.origin.y = max(0, min(currentCropRect.maxY - 0.1, currentCropRect.minY + deltaY))
            newRect.size.width = max(0.1, min(1 - currentCropRect.minX, currentCropRect.width + deltaX))
            newRect.size.height = currentCropRect.maxY - newRect.minY
            
        case .bottomLeft:
            newRect.origin.x = max(0, min(currentCropRect.maxX - 0.1, currentCropRect.minX + deltaX))
            newRect.size.width = currentCropRect.maxX - newRect.minX
            newRect.size.height = max(0.1, min(1 - currentCropRect.minY, currentCropRect.height + deltaY))
            
        case .bottomRight:
            newRect.size.width = max(0.1, min(1 - currentCropRect.minX, currentCropRect.width + deltaX))
            newRect.size.height = max(0.1, min(1 - currentCropRect.minY, currentCropRect.height + deltaY))
        }
        
        currentCropRect = newRect
    }
}

// MARK: - Image Editor Sheet
struct ImageEditorSheet: View {
    let element: CanvasElement
    let onSave: (CanvasElement) -> Void
    
    @State private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let imageData = element.imageData,
                   let uiImage = UIImage(data: imageData) {
                    
                    // Image preview with controls
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .rotationEffect(.degrees(rotation))
                            .clipped()
                    }
                    .frame(height: 300)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                    
                    // Controls
                    VStack(spacing: 20) {
                        // Scale control
                        VStack {
                            Text("Size: \(String(format: "%.1f", scale))x")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "minus.magnifyingglass")
                                    .foregroundColor(.blue)
                                
                                Slider(value: $scale, in: 0.5...3.0, step: 0.1)
                                
                                Image(systemName: "plus.magnifyingglass")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Rotation control
                        VStack {
                            Text("Rotation: \(String(format: "%.0f", rotation))°")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "rotate.left")
                                    .foregroundColor(.blue)
                                
                                Slider(value: $rotation, in: 0...360, step: 15)
                                
                                Image(systemName: "rotate.right")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Reset button
                        Button("Reset") {
                            scale = 1.0
                            rotation = 0
                        }
                        .foregroundColor(.orange)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedElement = element
                        updatedElement.rotation = rotation
                        // Apply scale to size
                        updatedElement.size = CGSize(
                            width: element.size.width * scale,
                            height: element.size.height * scale
                        )
                        onSave(updatedElement)
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
}

// MARK: - Canvas Editor ViewModel
@MainActor
class CanvasEditorViewModel: ObservableObject {
    @Published var elements: [CanvasElement] = []
    @Published var selectedElement: CanvasElement?
    
    func addElement(_ element: CanvasElement) {
        elements.append(element)
    }
    
    func removeElement(_ element: CanvasElement) {
        elements.removeAll { $0.id == element.id }
    }
    
    func updateElement(_ element: CanvasElement) {
        if let index = elements.firstIndex(where: { $0.id == element.id }) {
            elements[index] = element
        }
    }
}

// MARK: - Article Canvas Editor View
struct ArticleCanvasEditorView: View {
    let initialTemplate: CanvasTemplate
    
    var body: some View {
        CanvasEditorView(initialTemplate: initialTemplate)
    }
}