//======================================================================
// MARK: - EditProfileView.swift (プロフィール編集画面)
// Path: foodai/Features/MyPage/Views/EditProfileView.swift
//======================================================================
import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: MyPageViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    HStack {
                        Text("Username")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        TextField("@username", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    HStack {
                        Text("Display Name")
                            .foregroundColor(MinimalDesign.Colors.secondary)
                        TextField("Your name", text: $displayName)
                    }
                }
                
                Section(header: Text("Bio")) {
                    TextEditor(text: $bio)
                        .frame(minHeight: 100)
                        .padding(.vertical, 4)
                }
                
                Section {
                    Text("Maximum 200 characters")
                        .font(.caption)
                        .foregroundColor(MinimalDesign.Colors.secondary)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .actionTextButtonStyle()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .actionTextButtonStyle()
                    .fontWeight(.semibold)
                    .disabled(username.isEmpty || displayName.isEmpty)
                }
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
                    .actionTextButtonStyle()
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentProfile()
            }
        }
    }
    
    private func loadCurrentProfile() {
        if let profile = viewModel.userProfile {
            username = profile.username
            displayName = profile.displayName ?? ""
            bio = profile.bio ?? ""
        }
    }
    
    private func saveProfile() {
        guard bio.count <= 200 else {
            alertMessage = "Bio must be 200 characters or less"
            showAlert = true
            return
        }
        
        Task {
            await viewModel.updateProfile(
                username: username,
                displayName: displayName,
                bio: bio
            )
            dismiss()
        }
    }
}