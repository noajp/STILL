import SwiftUI

struct TestMessagesView: View {
    @State private var isGroupChatMode = false
    
    var body: some View {
        NavigationStack {
            MessagesView(isGroupChatMode: $isGroupChatMode)
        }
        .environmentObject(AuthManager.shared)
    }
}

#Preview {
    TestMessagesView()
}