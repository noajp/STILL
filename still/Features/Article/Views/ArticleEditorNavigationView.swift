//======================================================================
// MARK: - ArticleEditorNavigationView.swift
// Purpose: SwiftUI view component (ArticleEditorNavigationViewビューコンポーネント)
// Path: still/Features/Article/Views/ArticleEditorNavigationView.swift
//======================================================================
//
//  ArticleEditorNavigationView.swift
//  tete
//
//  Navigation wrapper for article editor
//

import SwiftUI

struct ArticleEditorNavigationView: View {
    var body: some View {
        ArticleEditorView()
    }
}

#if DEBUG
struct ArticleEditorNavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleEditorNavigationView()
    }
}
#endif