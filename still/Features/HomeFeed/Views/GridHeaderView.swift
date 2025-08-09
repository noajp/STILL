//======================================================================
// MARK: - GridHeaderView.swift
// Purpose: Header components for the home grid including upload status and controls
// Path: still/Features/HomeFeed/Views/GridHeaderView.swift
//======================================================================

import SwiftUI

/**
 * GridHeaderView provides header functionality for the home grid.
 * 
 * Features:
 * - Post upload status tracking with progress bar
 * - Status message display with dismiss functionality
 * - Visual progress indicators
 * - Smooth animations and transitions
 */
struct GridHeaderView: View {
    // MARK: - Properties
    
    @StateObject private var postStatusManager = PostStatusManager.shared
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            if postStatusManager.showStatus {
                uploadStatusSection
            }
        }
    }
    
    // MARK: - Upload Status Section
    
    @ViewBuilder
    private var uploadStatusSection: some View {
        VStack(spacing: 0) {
            // Status message
            statusMessageRow
            
            // Progress bar
            progressBar
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var statusMessageRow: some View {
        HStack {
            Text(postStatusManager.statusMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Dismiss button
            Button("×") {
                postStatusManager.hideStatus()
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
    
    @ViewBuilder
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            // Background bar
            Rectangle()
                .fill(Color(hex: "121212"))
                .frame(height: 2)
            
            // Progress bar
            Rectangle()
                .fill(postStatusManager.statusColor)
                .frame(maxWidth: .infinity)
                .scaleEffect(
                    x: postStatusManager.progress, 
                    y: 1, 
                    anchor: .leading
                )
                .frame(height: 2)
                .animation(.easeInOut(duration: 0.3), value: postStatusManager.progress)
        }
    }
}

// MARK: - Grid Control Header

/**
 * GridControlHeaderView provides additional controls for grid management.
 */
struct GridControlHeaderView: View {
    // MARK: - Properties
    
    @Binding var showGridMode: Bool
    let onRefresh: (() -> Void)?
    let postCount: Int
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Mode toggle
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showGridMode.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showGridMode ? "rectangle.grid.3x2" : "list.bullet")
                                .font(.system(size: 16))
                            
                            Text(showGridMode ? "Grid" : "Feed")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                // Post count
                if postCount > 0 {
                    Text("\(postCount) posts")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Refresh button
                if let onRefresh = onRefresh {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
    }
}

// MARK: - Empty State Header

/**
 * EmptyStateHeaderView displays when there are no posts.
 */
struct EmptyStateHeaderView: View {
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.white)
                
            Text("No posts yet")
                .font(.headline)
                .foregroundColor(.white)
                
            Text("Tap the + button\nto create your first post")
                .font(.caption)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Loading State Header

/**
 * LoadingStateHeaderView displays during loading.
 */
struct LoadingStateHeaderView: View {
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            
            Text("Loading...")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
}

// MARK: - Preview Provider

struct GridHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GridHeaderView()
            
            GridControlHeaderView(
                showGridMode: .constant(true),
                onRefresh: {},
                postCount: 42
            )
            
            EmptyStateHeaderView()
        }
        .background(MinimalDesign.Colors.background)
    }
}