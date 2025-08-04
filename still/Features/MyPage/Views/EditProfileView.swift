//======================================================================
// MARK: - EditProfileView.swift (プロフィール編集画面)
// Path: foodai/Features/MyPage/Views/EditProfileView.swift
//======================================================================
import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @ObservedObject var viewModel: MyPageViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var displayName: String = ""
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var profileImage: UIImage?
    @State private var isUploadingImage = false
    
    var body: some View {
        NavigationView {
            Form {
                profilePhotoSection
                basicInfoSection
                bioSection
                bioHintSection
            }
            .scrollContentBackground(.hidden)
            .background(MinimalDesign.Colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
                    .foregroundColor(.white)
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentProfile()
            }
            .onChange(of: selectedImage) { _, newValue in
                if let newValue = newValue {
                    loadSelectedImage(newValue)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var profilePhotoSection: some View {
        Section(header: Text("Profile Photo")) {
            HStack {
                profileImageView
                photoPickerSection
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var profileImageView: some View {
        Group {
            if let profileImage = profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 3)
                    )
            } else if let avatarUrl = viewModel.userProfile?.avatarUrl {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                        )
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 3)
                )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white, lineWidth: 3)
                    )
            }
        }
    }
    
    private var photoPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker("Change Photo", selection: $selectedImage, matching: .images)
                .foregroundColor(.blue)
                .disabled(isUploadingImage)
            
            if isUploadingImage {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Uploading...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private var basicInfoSection: some View {
        Section(header: Text("Basic Information")) {
            HStack {
                Text("Username")
                    .foregroundColor(.white)
                TextField("@username", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            HStack {
                Text("Display Name")
                    .foregroundColor(.white)
                TextField("Your name", text: $displayName)
            }
        }
    }
    
    private var bioSection: some View {
        Section(header: Text("Bio")) {
            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(.vertical, 4)
        }
    }
    
    private var bioHintSection: some View {
        Section {
            Text("Maximum 200 characters")
                .font(.caption)
                .foregroundColor(.white)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(.white)
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
                saveProfile()
            }
            .foregroundColor(.white)
            .fontWeight(.semibold)
            .disabled(username.isEmpty || displayName.isEmpty)
        }
    }
    
    private func loadCurrentProfile() {
        if let profile = viewModel.userProfile {
            username = profile.username
            displayName = profile.displayName ?? ""
            bio = profile.bio ?? ""
        }
    }
    
    private func loadSelectedImage(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                await MainActor.run {
                    self.profileImage = uiImage
                    uploadProfileImage(uiImage)
                }
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        isUploadingImage = true
        
        Task {
            do {
                let success = await viewModel.updateProfilePhoto(image)
                await MainActor.run {
                    isUploadingImage = false
                    if !success {
                        alertMessage = "Failed to upload profile image"
                        showAlert = true
                    }
                }
            }
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