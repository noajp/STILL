//======================================================================
// MARK: - MessageInputSection.swift
// Purpose: Reusable message input component for conversation views
// Path: still/Features/Messages/Views/MessageInputSection.swift
//======================================================================

import SwiftUI

/**
 * MessageInputSection provides a reusable message input interface
 * for sending messages in conversations.
 * 
 * Features:
 * - Text field with placeholder for message composition
 * - Send button with enabled/disabled states
 * - Loading state indicator during message sending
 * - Keyboard submission support
 * - Clean minimal design with proper styling
 */
struct MessageInputSection: View {
    // MARK: - Properties
    
    @Binding var messageText: String
    let isSending: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    // MARK: - Computed Properties
    
    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Top separator line
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
            
            // Input container
            HStack(spacing: 12) {
                // Message text field
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTextFieldFocused)
                    .disabled(isSending)
                    .onSubmit {
                        if canSend {
                            onSend()
                        }
                    }
                
                // Send button
                Button(action: {
                    if canSend {
                        onSend()
                    }
                }) {
                    if isSending {
                        // Show loading indicator while sending
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 20, height: 20)
                    } else {
                        // Send icon
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(
                                canSend ? MinimalDesign.Colors.accentRed : Color.gray.opacity(0.5)
                            )
                    }
                }
                .disabled(!canSend)
            }
            .padding()
            .background(MinimalDesign.Colors.background)
        }
        .background(MinimalDesign.Colors.background)
    }
}

// MARK: - Extended Input Section with Additional Features

/**
 * ExtendedMessageInputSection provides an enhanced message input interface
 * with additional features like attachment support and typing indicators.
 * 
 * This can be used when more functionality is needed beyond basic text input.
 */
struct ExtendedMessageInputSection: View {
    // MARK: - Properties
    
    @Binding var messageText: String
    let isSending: Bool
    let isTyping: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    let onAttachmentTap: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Typing indicator
            if isTyping {
                HStack {
                    Text("Someone is typing...")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    Spacer()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Main input section
            MessageInputSection(
                messageText: $messageText,
                isSending: isSending,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: onSend
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isTyping)
    }
}

// MARK: - Preview Provider

struct MessageInputSection_Previews: PreviewProvider {
    @FocusState static var isFocused: Bool
    
    static var previews: some View {
        Group {
            // Basic input section
            MessageInputSection(
                messageText: .constant(""),
                isSending: false,
                isTextFieldFocused: $isFocused,
                onSend: {}
            )
            .previewDisplayName("Empty State")
            
            // Input with text
            MessageInputSection(
                messageText: .constant("Hello!"),
                isSending: false,
                isTextFieldFocused: $isFocused,
                onSend: {}
            )
            .previewDisplayName("With Text")
            
            // Sending state
            MessageInputSection(
                messageText: .constant("Sending message..."),
                isSending: true,
                isTextFieldFocused: $isFocused,
                onSend: {}
            )
            .previewDisplayName("Sending State")
        }
        .background(MinimalDesign.Colors.background)
    }
}