//======================================================================
// MARK: - 2. MenuItem と Review モデルの追加
// Path: foodai/Core/DataModels/MenuItem.swift (新規作成)
//======================================================================
import Foundation

struct MenuItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let price: String
    let imageName: String?
}

struct Review: Identifiable {
    let id = UUID()
    let userName: String
    let userImageName: String?
    let rating: Int
    let comment: String
    let date: String
}

