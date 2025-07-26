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

## Security Considerations
- Never expose or log secrets/keys
- Input validation using InputValidator
- Secure configuration via SecureConfig
- Message encryption for private communications

## UI/UX Principles
- Minimal design aesthetic
- Red accent color (MinimalDesign.Colors.accentRed)
- Dark mode support throughout
- No emojis unless user requests
- Clean, simple interfaces

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
- **NEVER** create files unless absolutely necessary
- **ALWAYS** prefer editing existing files
- **NEVER** proactively create documentation unless requested
- **ALWAYS** investigate thoroughly before making changes
- Ask user if unsure about potential breaking changes