# STILL Project - Claude Memory

## Project Overview
- iOS social media app with photo sharing and article features
- Built with SwiftUI and Supabase backend
- 80% complete - be careful with changes to avoid breaking existing functionality

## Build & Test Commands
- Build: `xcodebuild -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro" build`
- Run lint: `swiftlint` (if available)
- Run tests: `xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"`

## Code Style Guidelines
- Use SwiftUI's declarative syntax
- Follow existing code patterns and conventions
- Maintain consistent spacing and indentation (4 spaces)
- Use MinimalDesign.Colors for consistent theming
- No comments unless explicitly requested
- Keep responses concise and to the point

### File Header Requirements
**ALWAYS** include this header format in every new file created:
```swift
//======================================================================
// MARK: - FileName.swift
// Purpose: Brief description of file purpose (日本語での簡潔な説明)
// Path: relative/path/to/file.swift
//======================================================================
```

**Example:**
```swift
//======================================================================
// MARK: - AuthManager.swift
// Purpose: Authentication manager with user session handling, secure token management, and Supabase auth integration (ユーザーセッション処理、セキュアトークン管理、Supabase認証統合を持つ認証マネージャー)
// Path: still/Core/Auth/AuthManager.swift
//======================================================================
```

**Important**: If you encounter files without this header, add it immediately during any file modification.

## Architecture Patterns
- MVVM pattern with @StateObject and @ObservableObject
- ViewModels handle business logic
- Services handle API/database interactions
- Repositories manage data persistence

## Project Structure
```
still/
├── Application/          # App entry point and environment
├── Core/                # Shared components, models, services
│   ├── Components/      # Reusable UI components
│   ├── DataModels/      # Data structures
│   ├── Services/        # Business logic services
│   └── Repositories/    # Data persistence
├── Features/           # Feature modules
│   ├── HomeFeed/       # Photo feed functionality
│   ├── Articles/       # Article creation and viewing
│   ├── Messages/       # Direct messaging and group chats
│   ├── Profile/        # User profiles
│   └── SharedViews/    # Shared UI components
└── supabase/          # Database migrations
```

## Important Components
- **UnifiedHeader**: Centralized header component used throughout the app
- **CustomTabBar**: Main navigation with feed, articles, post button, messages, and profile
- **PostTypeSelectionPopup**: New popup for selecting between photo and article posts
- **ScrollableHeaderView**: Header that scrolls naturally with content (no animation)

## Current Implementation Details
- Photo posts: CustomTabBar → PostTypeSelectionPopup → PhotoPickerView → ModernPhotoEditorView
- Article posts: CustomTabBar → PostTypeSelectionPopup → ArticleEditorView
- Headers scroll with content, not animated hide/show
- Messages show participant names correctly after UUID case sensitivity fix
- Feed uses masonry grid layout with alternating patterns

## Supabase Integration
- Uses Supabase for backend
- Authentication via AuthManager
- Real-time features for messaging
- Image storage for posts and profiles
- Database views used instead of RPC functions to avoid caching issues

## Security Requirements & Standards

### Database Security (Implemented)
- **RLS (Row Level Security)** enabled on all tables with appropriate policies
- **Function Security**: search_path explicitly set to prevent SQL injection
- **Extension Security**: pgaudit moved to extensions schema with proper permissions
- **Data Retention**: Policies configured for automated cleanup

### Authentication Security
- ✅ **Keychain Storage**: Secrets migrated from Secrets.plist to secure Keychain
- ✅ **SecureConfig**: Centralized secure configuration management
- ⚠️ **Password Protection**: HaveIBeenPwned breach detection (requires Supabase dashboard config)
- ⚠️ **MFA Enhancement**: Additional multi-factor auth methods needed

### Application Security Standards
- **Never expose or log secrets/keys** - Use SecureConfig for all sensitive data
- **Input validation** using InputValidator for all user inputs
- **Message encryption** for private communications
- **Rate limiting** implemented to prevent brute force attacks
- **Security monitoring** via audit logs and honeypot tables

### Key Management
- **Supabase URL**: `https://yccjlkcxqybxqewzchen.supabase.co`
- **API Keys**: Stored in Keychain, accessed via SecureConfig
- **Environment Variables**: Use for development, Keychain for production

### Ongoing Security Tasks
1. Enable HaveIBeenPwned protection in Supabase dashboard
2. Configure additional MFA methods (TOTP, SMS)
3. Regular security audits using `mcp__supabase__get_advisors`
4. Monitor security logs for anomalies

### Security Incident Response
- Immediately rotate API keys if compromised
- Review audit logs for suspicious activity
- Update RLS policies if data access patterns change

## UI/UX Principles & Design Philosophy

### Design Reference
- **Atlassian Design System**: https://atlassian.design/
- Follow Atlassian's philosophy: "Design with clarity, Build with confidence"
- Reference their foundations for systematic design approach

### Core Design Principles
- **Clarity First**: Users should never be confused about how to interact with the interface
- **Minimal design aesthetic**: Clean, purposeful elements without unnecessary decoration
- **Systematic approach**: Use design tokens for consistency across all components
- **Accessibility**: Design for broad usability and good user experience
- **Modular components**: Reusable, flexible UI elements that can be composed

### Visual Design Standards
- **Red accent color**: MinimalDesign.Colors.accentRed for primary actions and highlights
- **Dark mode support**: Full theme compatibility throughout the app
- **Typography**: Consistent font weights and sizes that enhance readability
- **Spacing**: Systematic spacing using design tokens for visual hierarchy
- **No emojis**: Unless explicitly requested by user

### Interaction Design
- **Intuitive navigation**: Users should understand where they are and how to get where they want to go
- **Immediate feedback**: Visual responses to user actions (button states, loading indicators)
- **Gentle animations**: Subtle transitions that guide attention without distraction
- **Touch targets**: Appropriate sizing for mobile interaction following design standards

## Common Issues & Solutions
- UUID case sensitivity: Always convert to lowercase for comparisons
- Supabase RPC caching: Use database views or fresh client instances
- Header positioning: Adjust padding values carefully
- Scroll indicators: Use `showsIndicators: false` on ScrollViews

## Testing Approach
- Check README or search codebase for test commands
- Always run lint/typecheck after changes
- Test on iPhone 16 Pro simulator

## Important Reminders
- **ALWAYS** read tasks.md at the start of each session for current task status
- **NEVER** create files unless absolutely necessary
- **ALWAYS** prefer editing existing files
- **NEVER** proactively create documentation unless requested
- **ALWAYS** investigate thoroughly before making changes
- Ask user if unsure about potential breaking changes