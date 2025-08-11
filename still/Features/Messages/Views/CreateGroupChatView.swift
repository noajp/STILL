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
    @State private var groupName = ""
    @State private var selectedEmoji = "👥"

    let onCreateGroup: (String, String, [String]) -> Void // (name, emoji, userIds)
    
    var body: some View {
        VStack(spacing: 0) {
            // グループ情報入力セクション
            VStack(spacing: 16) {
                // グループアイコンとグループ名
                HStack(spacing: 16) {
                    // 絵文字アイコン入力
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Icon")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("🎉", text: $selectedEmoji)
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .multilineTextAlignment(.center)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .keyboardType(.default)
                            .onReceive(selectedEmoji.publisher.collect()) { characters in
                                // 絵文字のみ許可し、1文字に制限
                                let text = String(characters)
                                let filtered = String(text.prefix(1).filter { $0.unicodeScalars.allSatisfy { $0.properties.isEmoji } })
                                if filtered != selectedEmoji {
                                    selectedEmoji = filtered.isEmpty ? "👥" : filtered
                                }
                            }
                    }
                    
                    // グループ名入力
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                        
                        TextField("Enter group name", text: $groupName)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.horizontal, 20)
            }
            .padding(.top, 16)
            
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
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
            .padding(.horizontal, 20)
                
            // ユーザーリスト
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundColor(.white)
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
                        .foregroundColor(.white)
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
                        .foregroundColor(.white)
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
            .background(selectedUsers.isEmpty || groupName.isEmpty ? Color.gray.opacity(0.3) : MinimalDesign.Colors.accentRed)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .disabled(selectedUsers.isEmpty || groupName.isEmpty || isCreating)
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
        .background(MinimalDesign.Colors.background)

    }
    
    private func createGroup() {
        guard !selectedUsers.isEmpty, !groupName.isEmpty else { return }
        
        isCreating = true
        onCreateGroup(groupName, selectedEmoji, Array(selectedUsers))
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
                Group {
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
                                    .foregroundColor(.white)
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(user.profileDisplayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
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





#Preview {
    NavigationView {
        CreateGroupChatView { groupName, emoji, selectedUserIds in
            print("Group name: \(groupName), emoji: \(emoji), users: \(selectedUserIds)")
        }
    }
}