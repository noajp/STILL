# STILL - iOS Social Media Platform

STILL is a feature-rich social media platform for iOS, specialized in photo and article posting. It provides professional-grade photo editing capabilities and sophisticated article creation tools for creators.

## 🚀 Overview

STILL combines the power of visual storytelling with written content, allowing creators to share their perspectives through both stunning imagery and compelling articles. Built with SwiftUI and powered by Supabase, it offers a seamless and secure social media experience.

## 💻 Tech Stack

### Frontend
- **SwiftUI** - Modern declarative UI framework
- **Swift Concurrency** - Async/await for efficient asynchronous operations
- **Combine** - Reactive programming for data flow
- **PhotosUI** - Advanced photo editing and management

### Backend & Services
- **Supabase** - Backend as a Service
  - PostgreSQL database with Row Level Security (RLS)
  - Authentication and user management
  - Real-time subscriptions
  - Edge Functions for server-side logic
  - Storage for media files

### Development Tools
- **Xcode 16+** - Primary IDE
- **Swift 5.9+** - Programming language
- **Git** - Version control

## ✨ Key Features

### 📸 Photo Posting
- **Advanced Camera**: Real-time filters, manual focus, zoom, and professional shooting features
- **Professional Editing**: RAW image processing, exposure/color/shadow adjustments, non-destructive editing
- **Filter Library**: Curated collection of artistic filters and effects

### 📝 Article Creation
- **Multiple Formats**: 
  - News articles for factual reporting
  - Magazine-style articles with rich visual layouts
- **Intuitive Editor**: Drag-and-drop interface for images and text
- **Rich Text Support**: Formatting options for compelling storytelling

### 📱 Social Features
- **Unified Feed**: Mixed content stream of photos and articles
- **Engagement**: Likes, comments, and follows
- **Real-time Updates**: Live notifications and messaging
- **Profile Management**: Customizable profiles and content portfolios

## 📂 Project Structure

```
STILL/
├── still/                     # Main iOS application
│   ├── Application/          # App entry point and configuration
│   │   ├── STILLApp.swift
│   │   └── AppEnvironment.swift
│   ├── Core/                 # Shared components and services
│   │   ├── Auth/            # Authentication logic
│   │   ├── DataModels/      # Data structures and models
│   │   ├── Repositories/    # Data persistence layer
│   │   ├── Security/        # Security utilities and encryption
│   │   └── Services/        # Business logic and API clients
│   └── Features/            # Feature modules
│       ├── HomeFeed/        # Main feed functionality
│       ├── Camera/          # Camera and capture
│       ├── PhotoEditor/     # Photo editing tools
│       ├── Articles/        # Article creation and viewing
│       ├── Messages/        # Direct messaging
│       ├── Profile/         # User profiles
│       └── Settings/        # App settings
├── supabase/                 # Backend configuration
│   ├── migrations/          # Database migrations
│   └── functions/           # Edge Functions
├── MarkDown/                # Documentation
│   ├── CLAUDE.md           # AI assistant guidelines
│   └── security.md         # Security documentation
└── stillTests/              # Test suites
```

## 🛠️ Development Setup

### Prerequisites
- macOS 14.0+ (Sonoma or later)
- Xcode 16.0+
- iOS 17.0+ deployment target
- Supabase account

### Environment Setup

1. **Clone the repository**
   ```bash
   git clone <repository_url>
   cd STILL
   ```

2. **Install dependencies**
   ```bash
   # Open Xcode and let it resolve Swift Package Manager dependencies
   open still.xcodeproj
   ```

3. **Configure Supabase**
   
   Create a `Development.xcconfig` file in the project root:
   ```xcconfig
   // Development.xcconfig
   SUPABASE_URL = your_supabase_url_here
   SUPABASE_ANON_KEY = your_supabase_anon_key_here
   ```
   
   ⚠️ **Important**: This file is gitignored. Never commit API keys to version control.

4. **Set up the database**
   ```bash
   # Apply database migrations
   cd supabase
   supabase db reset
   ```

5. **Build and run**
   - Select the target device/simulator in Xcode
   - Press `Cmd+R` to build and run

## 📋 Available Commands

### Build Commands
```bash
# Build the project
xcodebuild -project still.xcodeproj -scheme still build

# Run tests
xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# Clean build folder
xcodebuild clean -project still.xcodeproj -scheme still
```

### Database Commands
```bash
# Run migrations
supabase migration up

# Create new migration
supabase migration new <migration_name>

# Reset database
supabase db reset
```

## 🔐 Environment Variables

Create a `Development.xcconfig` file with the following variables:

| Variable | Description | Required |
|----------|-------------|----------|
| `SUPABASE_URL` | Your Supabase project URL | ✅ |
| `SUPABASE_ANON_KEY` | Supabase anonymous key | ✅ |

## 🧪 Testing

The project uses XCTest framework for unit and UI testing:

```bash
# Run all tests
xcodebuild test -scheme still -destination "platform=iOS Simulator,name=iPhone 16 Pro"

# Run specific test suite
xcodebuild test -scheme still -only-testing:stillTests/CoreTests
```

## 📚 Documentation

- [AI Development Guidelines](./CLAUDE.md) - Instructions for AI-assisted development
- [Security Documentation](./MarkDown/security.md) - Security best practices and requirements
- [API Documentation](https://supabase.com/docs) - Supabase API reference

## 🤝 Contributing

1. Create a feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes (`git commit -m 'Add amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

### Coding Standards
- Follow SwiftUI best practices
- Use Swift Concurrency (async/await) for asynchronous operations
- Implement proper error handling
- Add comprehensive documentation for public APIs
- Ensure all new features have corresponding tests

## 📄 License

This project is proprietary software. All rights reserved.

## 🔗 Links

- [Supabase Dashboard](https://supabase.com/dashboard)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Project Issues](https://github.com/your-repo/issues)

---

Built with ❤️ using SwiftUI and Supabase