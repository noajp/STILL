//======================================================================
// MARK: - CreateGroupChatView.swift
// Purpose: グループチャット作成画面
// Path: still/Features/Messages/Views/CreateGroupChatView.swift
//======================================================================
import SwiftUI

struct CreateGroupChatView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = UserSearchViewModel()
    @State private var searchText = ""
    @State private var selectedUsers: Set<String> = []
    @State private var selectedUserProfiles: [UserProfile] = []
    @State private var isCreating = false
    let onCreateGroup: ([String]) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 選択されたユーザーの表示
            if !selectedUserProfiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(selectedUserProfiles, id: \.id) { user in
                            SelectedUserChip(user: user) {
                                // ユーザーの選択を解除
                                selectedUsers.remove(user.id)
                                selectedUserProfiles.removeAll { $0.id == user.id }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 60)
                .padding(.top, 16)
            }
            
            // 検索バー
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray.opacity(0.6))
                    .font(.system(size: 16))
                
                TextField("Search users", text: $searchText)
                    .font(.system(size: 16))
                    .onChange(of: searchText) { _, newValue in
                        Task {
                            await viewModel.searchUsers(query: newValue)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 20)
                
            // ユーザーリスト
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.users.isEmpty && !searchText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("No users found")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else if searchText.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.6))
                    Text("Search for users to add to group")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.users, id: \.id) { user in
                            GroupUserRowView(
                                user: user,
                                isSelected: selectedUsers.contains(user.id),
                                onToggle: {
                                    if selectedUsers.contains(user.id) {
                                        selectedUsers.remove(user.id)
                                        selectedUserProfiles.removeAll { $0.id == user.id }
                                    } else {
                                        selectedUsers.insert(user.id)
                                        if !selectedUserProfiles.contains(where: { $0.id == user.id }) {
                                            selectedUserProfiles.append(user)
                                        }
                                    }
                                }
                            )
                            
                            if user.id != viewModel.users.last?.id {
                                Divider()
                                    .padding(.leading, 70)
                            }
                        }
                    }
                    .padding(.top, 16)
                }
            }
            
            // 作成ボタン
            Button(action: createGroup) {
                if isCreating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Create Group (\(selectedUsers.count))")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(selectedUsers.isEmpty ? Color.gray.opacity(0.3) : MinimalDesign.Colors.accentRed)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .disabled(selectedUsers.isEmpty || isCreating)
        }
        .navigationTitle("New Group")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(MinimalDesign.Colors.accentRed)
            }
        }
    }
    
    private func createGroup() {
        guard !selectedUsers.isEmpty else { return }
        
        isCreating = true
        onCreateGroup(Array(selectedUsers))
        dismiss()
    }
}

struct GroupUserRowView: View {
    let user: UserProfile
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 16) {
                // プロフィール画像
                if let avatarUrl = user.avatarUrl {
                    RemoteImageView(imageURL: avatarUrl)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(user.profileDisplayName.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.profileDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(MinimalDesign.Colors.primary)
                    
                    Text("@\(user.username)")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
                    
                    if let bio = user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.system(size: 13))
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // チェックボックス
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? MinimalDesign.Colors.accentRed : Color.clear)
                    )
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedUserChip: View {
    let user: UserProfile
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // ユーザーアバター
            if let avatarUrl = user.avatarUrl {
                RemoteImageView(imageURL: avatarUrl)
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(String(user.profileDisplayName.prefix(1)).uppercased())
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    )
            }
            
            Text(user.profileDisplayName)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationView {
        CreateGroupChatView { selectedUserIds in
            print("Selected users: \(selectedUserIds)")
        }
    }
}