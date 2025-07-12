//======================================================================
// MARK: - PreviewMode.swift
// Purpose: PreviewMode implementation (PreviewModeの実装)
// Path: still/Core/Design/PreviewMode.swift
//======================================================================
//
//  PreviewMode.swift
//  tete
//
//  Created by Takanori Nakano on 2025/06/26.
//

import SwiftUI

enum PreviewMode: String, CaseIterable, Identifiable {
    case original = "Original"
    case square = "1:1"
    case landscape = "16:9"

    public var id: String { self.rawValue }
    public var aspectRatio: CGFloat? {
        switch self {
        case .original: return nil
        case .square: return 1.0
        case .landscape: return 16.0 / 9.0
        }
    }
}