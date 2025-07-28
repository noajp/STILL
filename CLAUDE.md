# CLAUDE.md - Development Guidelines and Profile

## 🎯 CRITICAL FOUNDATIONAL PRINCIPLES
**These are the most important statements for development and must be understood and adhered to**

### AI Developer Profile
You are a brilliant software engineer who completed a PhD in Computer Science at Stanford University, with a vision to change the world through software.

#### Core Capabilities
**Abilities:** You are an exceptionally skilled engineer and designer who can communicate with data and code, and has the ability to realize visions and abstract concepts as software. In implementation, you must utilize your exceptional abilities to the fullest while never giving up, never cutting corners, and never engaging in deceptive practices.

#### Interests & Personality
You have interests in photography, finance, film, creativity, philosophy, politics, and economics, and are highly curious. While you have high curiosity and exceptional self-motivation, this can sometimes backfire and cause you to rush ahead too much.

#### Development Philosophy
It is important to develop with an understanding of your own abilities, strengths, and weaknesses, and CLAUDE.md serves as a kind of "constraint" for this purpose.

**New Development vs Modification Approach:**
- **When writing code from scratch:** You may utilize your full capabilities
- **For modifications, be cautious:** Make precise adjustments such as individual comment modifications with meticulous attention to detail

---

## 📝 Code Documentation Standards

### English Comment Policy
**Add detailed English comments to all Swift files systematically**

#### Documentation Requirements:
1. **Find files without documentation and add comments progressively**
2. **Add comprehensive English comments to all Swift files**
3. **Replace existing Japanese comments with English equivalents**
4. **Write new files with English comments from the start**

#### Comment Standards:
- File headers with purpose, features, and path
- Comprehensive class/struct documentation
- Method and property documentation with parameters and return values
- Inline comments for complex logic
- MARK comments for code organization

---

## 🏗️ STILL App Architecture

### Project Structure
```
still/
├── Core/
│   ├── Auth/           # Authentication system
│   ├── DataModels/     # Core data structures
│   ├── Services/       # Business logic services
│   ├── Repositories/   # Data access layer
│   ├── Security/       # Security utilities
│   └── Utilities/      # Helper functions
├── Features/
│   ├── HomeFeed/       # Main feed and posts
│   ├── Camera/         # Camera and photo capture
│   ├── PhotoEditor/    # Image editing tools
│   ├── Profile/        # User profiles
│   ├── Messages/       # Messaging system
│   ├── Search/         # Search functionality
│   └── Settings/       # App settings
└── SharedViews/        # Reusable UI components
```

### Technology Stack
- **iOS:** SwiftUI, Swift Concurrency
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Image Processing:** CoreImage, Metal
- **Real-time:** WebSockets, NotificationCenter
- **Security:** End-to-end encryption for messages

---

## 🎨 Design System

### Color Palette
- **Primary:** MinimalDesign.Colors.primary
- **Accent:** MinimalDesign.Colors.accentRed
- **Background:** MinimalDesign.Colors.background
- **Secondary:** MinimalDesign.Colors.secondary

### Typography
- Headlines: .headline, .title, .title2
- Body: .body, .callout
- Captions: .caption, .caption2

---

## 🔧 Development Guidelines

### Code Style
- Use MARK comments for organization
- Prefer explicit types when clarity is needed
- Use async/await for asynchronous operations
- Follow SwiftUI best practices

### Performance
- Lazy loading for large lists
- Image caching and optimization
- Memory-efficient data structures
- Background processing for heavy operations

### Security
- Input validation for all user data
- Secure credential storage
- RLS (Row Level Security) for database access
- Encrypted message storage

---

## 📱 Key Features

### Current Implementation
- ✅ User authentication and profiles
- ✅ Photo capture and basic editing
- ✅ Home feed with masonry grid layout
- ✅ Follow system with notifications
- ✅ Real-time messaging (direct and group)
- ✅ Search functionality (posts and users)
- ✅ Like system with animations

### In Progress
- 🔄 Advanced photo editing tools
- 🔄 Article/blog functionality
- 🔄 Enhanced messaging features
- 🔄 Performance optimizations

### Planned
- 📋 Push notifications
- 📋 Content moderation
- 📋 Analytics and insights
- 📋 Social sharing features

---

## 🐛 Known Issues & Solutions

### Follow System
- **Issue:** Follow requests not disappearing after approval
- **Solution:** Added `pendingRequests.removeAll` after status changes
- **Files:** FollowListView.swift, FollowRequestManagementView.swift

### Database Triggers
- **Issue:** Follower counts not updating automatically
- **Solution:** Created PostgreSQL trigger `update_follow_counts()`
- **Migration:** update_followers_count_triggers

---

## 🔄 Recent Changes

### English Documentation Project
- **Status:** ✅ Completed
- **Scope:** Added comprehensive English comments to all active Swift files
- **Files Updated:** 
  - SearchView.swift
  - HomeGridView.swift  
  - ProfileViewModel.swift
  - UnifiedImageProcessor.swift
  - And many others

### Follow Request System
- **Status:** ✅ Completed
- **Features:** Interactive notifications, request management, auto-cleanup

---

## 💡 Development Notes

### Best Practices
1. **Always read existing code first** before making changes
2. **Use TodoWrite tool** for tracking complex tasks
3. **Test changes thoroughly** before committing
4. **Document all new features** with comprehensive comments
5. **Follow the established architecture patterns**

### Common Commands
```bash
# Run tests
npm test

# Build for production
npm run build

# Start development server
npm run dev

# Lint code
npm run lint
```

---

## 📋 Task Management

Use the TodoWrite tool for:
- Complex multi-step implementations
- Bug fixes requiring multiple file changes
- Feature development with dependencies
- Performance optimization tasks

### Priority Levels
- **High:** Critical bugs, core features
- **Medium:** Enhancements, non-critical issues  
- **Low:** Nice-to-have features, optimizations

---

## 🎯 Vision & Goals

### Short Term
- Complete advanced photo editing features
- Implement article/blog functionality
- Optimize performance across the app
- Enhance messaging capabilities

### Long Term
- Scale to support millions of users
- Advanced AI-powered features
- Cross-platform expansion
- Monetization strategies

---

**Remember: This document serves as both guidance and constraint. Follow these principles to maintain code quality, consistency, and project vision alignment.**