//======================================================================
// MARK: - PaperBasedEditorView.swift
// Purpose: Minimalist article editor with paper-based interface (ミニマルな紙ベースの記事エディター)
// Path: still/Features/ArticleEditor/Views/PaperBasedEditorView.swift
//======================================================================
import SwiftUI

struct PaperBasedEditorView: View {
    @StateObject private var viewModel = PaperBasedEditorViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPageIndex: Int = 0
    @State private var showColorPicker = false
    @State private var showOrientationPicker = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.opacity(0.95)
                    .ignoresSafeArea()
                
                // Main Content Area
                HStack(spacing: 0) {
                    // Left Sidebar - Tools
                    VStack(spacing: 24) {
                        // Close Button
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .light))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 44, height: 44)
                        }
                        
                        Spacer()
                        
                        // Orientation Toggle
                        Button(action: { 
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.toggleOrientation(for: selectedPageIndex)
                            }
                        }) {
                            Image(systemName: viewModel.pages[selectedPageIndex].isPortrait ? "rectangle.portrait" : "rectangle.landscape")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        // Color Picker
                        Button(action: { showColorPicker.toggle() }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.pages[selectedPageIndex].backgroundColor)
                                    .frame(width: 32, height: 32)
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }
                            .frame(width: 44, height: 44)
                        }
                        
                        // Text Tool
                        Button(action: { viewModel.addTextToPage(at: selectedPageIndex) }) {
                            Image(systemName: "textformat")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        // Layer Stack
                        Button(action: { viewModel.toggleLayerMode() }) {
                            Image(systemName: "square.3.layers.3d")
                                .font(.system(size: 20, weight: .light))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(viewModel.isLayerMode ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        // Save Button
                        Button(action: { 
                            Task {
                                await viewModel.saveArticle()
                                dismiss()
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.black)
                                .frame(width: 44, height: 44)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(width: 80)
                    .background(Color.black.opacity(0.3))
                    
                    // Center - Paper Canvas
                    ZStack {
                        // Paper Stack
                        ForEach(viewModel.pages.indices, id: \.self) { index in
                            PaperView(
                                page: $viewModel.pages[index],
                                isSelected: selectedPageIndex == index,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedPageIndex = index
                                    }
                                }
                            )
                            .scaleEffect(viewModel.isLayerMode ? 0.8 : (index == selectedPageIndex ? 1.0 : 0.95))
                            .offset(
                                x: viewModel.isLayerMode ? CGFloat(index - selectedPageIndex) * 30 : 0,
                                y: viewModel.isLayerMode ? CGFloat(index - selectedPageIndex) * 30 : 0
                            )
                            .zIndex(index == selectedPageIndex ? 1000 : Double(index))
                            .animation(.spring(response: 0.4), value: viewModel.isLayerMode)
                            .animation(.spring(response: 0.4), value: selectedPageIndex)
                        }
                        
                        // Add Page Button (Bottom Right)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.addNewPage()
                                        selectedPageIndex = viewModel.pages.count - 1
                                    }
                                }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .padding(.trailing, 40)
                                .padding(.bottom, 40)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Right Sidebar - Page Navigation & Angle Control
                    VStack(spacing: 20) {
                        // Page Thumbnails
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(viewModel.pages.indices, id: \.self) { index in
                                    PageThumbnail(
                                        page: viewModel.pages[index],
                                        isSelected: selectedPageIndex == index,
                                        pageNumber: index + 1
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedPageIndex = index
                                        }
                                    }
                                }
                            }
                            .padding(.top, 60)
                        }
                        .frame(maxHeight: .infinity)
                        
                        // Angle Slider
                        VStack(spacing: 8) {
                            Text("Angle")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(.white.opacity(0.6))
                            
                            RotationSlider(
                                value: $viewModel.pages[selectedPageIndex].rotation,
                                range: -30...30
                            )
                            .frame(height: 40)
                            .padding(.horizontal, 12)
                        }
                        .padding(.bottom, 20)
                    }
                    .frame(width: 120)
                    .background(Color.black.opacity(0.3))
                }
                
                // Color Picker Overlay
                if showColorPicker {
                    ColorPickerOverlay(
                        selectedColor: $viewModel.pages[selectedPageIndex].backgroundColor,
                        isShowing: $showColorPicker
                    )
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Paper View
struct PaperView: View {
    @Binding var page: ArticlePage
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let paperSize = calculatePaperSize(for: geometry.size, isPortrait: page.isPortrait)
            
            ZStack {
                // Paper Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(page.backgroundColor)
                    .shadow(color: .black.opacity(0.3), radius: isSelected ? 20 : 10, y: 5)
                
                // Content
                ForEach(page.textElements) { element in
                    EditableTextView(element: element)
                }
            }
            .frame(width: paperSize.width, height: paperSize.height)
            .rotationEffect(.degrees(page.rotation))
            .scaleEffect(isSelected ? 1.0 : 0.95)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onTapGesture(perform: onTap)
            .animation(.spring(response: 0.3), value: isSelected)
            .animation(.spring(response: 0.3), value: page.rotation)
        }
    }
    
    private func calculatePaperSize(for containerSize: CGSize, isPortrait: Bool) -> CGSize {
        let maxWidth = containerSize.width * 0.6
        let maxHeight = containerSize.height * 0.8
        let aspectRatio: CGFloat = isPortrait ? 0.7 : 1.4
        
        if isPortrait {
            let width = min(maxWidth, maxHeight * aspectRatio)
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            let height = min(maxHeight, maxWidth / aspectRatio)
            return CGSize(width: height * aspectRatio, height: height)
        }
    }
}

// MARK: - Page Thumbnail
struct PageThumbnail: View {
    let page: ArticlePage
    let isSelected: Bool
    let pageNumber: Int
    
    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 4)
                .fill(page.backgroundColor)
                .frame(width: 60, height: page.isPortrait ? 85 : 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                )
                .rotationEffect(.degrees(page.rotation * 0.3))
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
            
            Text("\(pageNumber)")
                .font(.system(size: 10, weight: .light))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

// MARK: - Rotation Slider
struct RotationSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                
                // Fill
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: geometry.size.width * normalizedValue)
                
                // Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: geometry.size.width * normalizedValue - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = gesture.location.x / geometry.size.width
                                let clampedValue = min(max(newValue, 0), 1)
                                value = range.lowerBound + (range.upperBound - range.lowerBound) * clampedValue
                            }
                    )
            }
        }
    }
    
    private var normalizedValue: CGFloat {
        CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
    }
}

// MARK: - Color Picker Overlay
struct ColorPickerOverlay: View {
    @Binding var selectedColor: Color
    @Binding var isShowing: Bool
    
    let colors: [Color] = [
        .white, .gray, .black,
        Color(hex: "FFF5E6"), Color(hex: "FFE5CC"), Color(hex: "FFDAB3"),
        Color(hex: "E6F3FF"), Color(hex: "CCE5FF"), Color(hex: "B3D9FF"),
        Color(hex: "E6FFE6"), Color(hex: "CCFFCC"), Color(hex: "B3FFB3"),
        Color(hex: "FFE6F0"), Color(hex: "FFCCE0"), Color(hex: "FFB3D1")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { isShowing = false }
            
            VStack(spacing: 16) {
                Text("Paper Color")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(50)), count: 3), spacing: 12) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                            isShowing = false
                        }) {
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                )
                        }
                    }
                }
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// MARK: - Editable Text View
struct EditableTextView: View {
    let element: TextElement
    @State private var isEditing = false
    @State private var text: String = ""
    
    var body: some View {
        ZStack {
            if isEditing {
                TextField("Enter text", text: $text)
                    .font(.system(size: element.fontSize, weight: .light))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .onSubmit {
                        isEditing = false
                    }
            } else {
                Text(element.text)
                    .font(.system(size: element.fontSize, weight: .light))
                    .foregroundColor(.black)
                    .onTapGesture {
                        text = element.text
                        isEditing = true
                    }
            }
        }
        .position(element.position)
    }
}

// MARK: - Article Page Model
struct ArticlePage: Identifiable {
    let id = UUID()
    var isPortrait: Bool = true
    var backgroundColor: Color = .white
    var rotation: Double = 0
    var textElements: [TextElement] = []
}

struct TextElement: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
    var fontSize: CGFloat = 18
}

// MARK: - View Model
@MainActor
class PaperBasedEditorViewModel: ObservableObject {
    @Published var pages: [ArticlePage] = [ArticlePage()]
    @Published var isLayerMode: Bool = false
    
    func addNewPage() {
        pages.append(ArticlePage())
    }
    
    func toggleOrientation(for index: Int) {
        guard index < pages.count else { return }
        pages[index].isPortrait.toggle()
    }
    
    func toggleLayerMode() {
        isLayerMode.toggle()
    }
    
    func addTextToPage(at index: Int) {
        guard index < pages.count else { return }
        let newElement = TextElement(
            text: "Tap to edit",
            position: CGPoint(x: 200, y: 200)
        )
        pages[index].textElements.append(newElement)
    }
    
    func saveArticle() async {
        // Save logic here
        print("Saving article with \(pages.count) pages")
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}