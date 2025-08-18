# WallyHub

**Modern iOS Educational Photo Sharing Platform**

WallyHub is a complete iOS application built with Uber's RIBs (Router-Interactor-Builder) architecture framework, designed for educational photo sharing with comprehensive role-based access control.

## 🏗️ Architecture Overview

### Role-Based RIBs Design

WallyHub implements a **business scope-driven architecture** where each user role represents a distinct business domain with its own RIB hierarchy:

```
🏢 Business Scopes (User Roles)
├── 👑 Admin    - System administration & oversight
├── 👨‍🏫 Teacher  - Board creation & student management  
└── 👨‍🎓 Student  - Photo sharing & board participation
```

This design ensures:
- **Clear business boundaries** between user roles
- **Scalable team development** with isolated business domains
- **Enhanced security** through role-based access control
- **Maintainable codebase** with single responsibility per RIB

## 📱 Application Features

### 👑 Admin Dashboard
- **System Monitoring**: Real-time Firebase metrics and performance analytics
- **Board Management**: Complete CRUD operations across all boards
- **User Management**: Teacher account administration
- **Analytics**: Data insights and usage statistics

### 👨‍🏫 Teacher Portal
- **Board Creation**: Custom photo sharing boards with QR access
- **Student Management**: Invitation system and participation tracking
- **Photo Moderation**: Content review and approval workflows
- **Board Settings**: Privacy controls and configuration options

### 👨‍🎓 Student Experience
- **QR Scanner**: Quick board access through QR codes
- **Photo Upload**: Seamless photo sharing with privacy controls
- **Gallery View**: Personal and board photo collections
- **Participation History**: Track engagement across multiple boards

## 🔧 Technical Stack

### Core Technologies
- **iOS 17.0+** - Latest iOS SDK with Swift 6
- **RIBs Framework** - Uber's business logic-driven architecture
- **SwiftUI** - Modern declarative UI framework
- **Firebase** - Backend-as-a-Service with real-time database
- **Swift Package Manager** - Dependency management

### Key Dependencies
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/uber/RIBs", from: "0.15.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/ReactiveX/RxSwift", from: "6.6.0")
]
```

## 🏛️ Project Structure

### Complete RIBs Hierarchy (87 Swift Files)

```
WallyHub/
├── 📱 App Layer
│   ├── WallyHubApp.swift              # App entry point
│   ├── AppDelegate.swift              # iOS lifecycle management
│   └── SceneDelegate.swift            # Scene-based app architecture
│
├── 🌳 RootRIB/                        # Application root
│   ├── RootRouter.swift               # Top-level navigation
│   ├── RootInteractor.swift           # App lifecycle business logic
│   ├── RootBuilder.swift              # Dependency injection root
│   └── RootComponent.swift            # Global dependency container
│
├── 🔐 AuthRIB/                        # Authentication flow
│   ├── AuthRouter.swift               # Auth navigation logic
│   ├── AuthInteractor.swift           # Authentication business logic
│   ├── AuthViewController.swift       # Authentication UI
│   │
│   ├── LoginRIB/                      # Teacher/Admin login
│   │   ├── LoginRouter.swift
│   │   ├── LoginInteractor.swift
│   │   └── LoginViewController.swift
│   │
│   ├── RoleSelectionRIB/              # User role selection
│   │   ├── RoleSelectionRouter.swift
│   │   ├── RoleSelectionInteractor.swift
│   │   └── RoleSelectionViewController.swift
│   │
│   └── StudentLoginRIB/               # Student direct access
│       ├── StudentLoginRouter.swift
│       ├── StudentLoginInteractor.swift
│       └── StudentLoginViewController.swift
│
├── 👑 AdminRIB/                       # Admin business scope
│   ├── AdminRouter.swift              # Admin child RIB navigation
│   ├── AdminInteractor.swift          # Admin business logic coordination
│   ├── AdminViewController.swift      # Black theme admin dashboard
│   │
│   ├── SystemDashboardRIB/            # Real-time monitoring
│   │   ├── SystemDashboardRouter.swift
│   │   ├── SystemDashboardInteractor.swift    # Firebase metrics calculation
│   │   └── SystemDashboardViewController.swift # Performance charts
│   │
│   ├── AllBoardsManagementRIB/        # Complete board management
│   │   ├── AllBoardsManagementRouter.swift
│   │   ├── AllBoardsManagementInteractor.swift # Board CRUD operations
│   │   └── AllBoardsManagementViewController.swift # Board list with filters
│   │
│   └── UserManagementRIB/             # User account management
│       ├── UserManagementRouter.swift
│       ├── UserManagementInteractor.swift
│       └── UserManagementViewController.swift
│
├── 👨‍🏫 TeacherRIB/                     # Teacher business scope
│   ├── TeacherRouter.swift            # Teacher navigation
│   ├── TeacherInteractor.swift        # Teacher business logic
│   ├── TeacherViewController.swift    # Teacher dashboard
│   │
│   ├── BoardCreationRIB/              # Board creation workflow
│   ├── BoardManagementRIB/            # Individual board management
│   ├── StudentManagementRIB/          # Student invitation & tracking
│   └── QRGenerationRIB/               # QR code generation
│
├── 👨‍🎓 StudentRIB/                     # Student business scope
│   ├── StudentRouter.swift           # Student navigation
│   ├── StudentInteractor.swift       # Student business logic
│   ├── StudentViewController.swift   # Student dashboard
│   │
│   ├── QRScannerRIB/                 # QR code scanning
│   ├── PhotoUploadRIB/               # Photo upload workflow
│   ├── GalleryRIB/                   # Photo gallery viewing
│   └── BoardParticipationRIB/        # Board joining & participation
│
├── 🔧 Shared/                        # Shared business components
│   ├── 🔄 Services/                  # Firebase service layer
│   │   ├── AuthenticationService.swift    # User authentication
│   │   ├── BoardService.swift            # Board operations
│   │   ├── StudentService.swift          # Student data management
│   │   ├── PhotoService.swift            # Photo upload/retrieval
│   │   └── QRCodeService.swift           # QR generation/scanning
│   │
│   ├── 📦 Models/                    # Data models
│   │   ├── User.swift                # User data structures
│   │   ├── Board.swift               # Board models
│   │   ├── Photo.swift               # Photo metadata
│   │   ├── Student.swift             # Student information
│   │   └── WallyError.swift          # Error handling
│   │
│   ├── 🎨 Components/               # Reusable UI components
│   │   ├── ModernLoadingView.swift   # Loading states
│   │   ├── ModernErrorView.swift     # Error handling UI
│   │   ├── QRCodeView.swift          # QR code display
│   │   └── PhotoGridView.swift       # Photo layout
│   │
│   └── 🔧 Extensions/               # Utility extensions
│       ├── Color+Extensions.swift    # Custom colors
│       ├── View+Extensions.swift     # SwiftUI helpers
│       └── String+Extensions.swift   # String utilities
│
└── 📂 Resources/                    # App resources
    ├── Assets.xcassets/             # App icons & images
    ├── Info.plist                  # App configuration
    ├── AppConfig.json              # Environment configuration
    └── .env                        # Firebase credentials (ignored)
```

## 🔥 Firebase Integration

### Database Configuration
```swift
// Always use "wallydb" database
let db = Firestore.firestore(database: "wallydb")
```

### Service Architecture
```swift
protocol BoardService {
    func createBoard(_ board: Board) async throws -> String
    func fetchBoards(for adminId: String) async throws -> [Board]
    func updateBoard(_ board: Board) async throws
    func deleteBoard(id: String) async throws
}
```

### Firestore Collections
```
wallydb/
├── users/              # User accounts (Admin, Teacher)
├── boards/             # Photo sharing boards
├── students/           # Student participants
├── photos/             # Photo metadata & URLs
└── system_metrics/     # Analytics & monitoring
```

## 🔐 Security & Configuration

### Environment-Based Authentication
```swift
// AppConfig.json (tracked)
{
    "firebase_project_id": "wally-b635c",
    "database_name": "wallydb",
    "storage_bucket": "wally-b635c.appspot.com"
}

// .env (not tracked - secure credentials)
ADMIN_EMAIL=admin@example.com
FIREBASE_API_KEY=your_api_key_here
```

### Role-Based Access Control
- **Admin**: Full system access & user management
- **Teacher**: Board creation & student management within owned boards
- **Student**: Photo upload & viewing within joined boards

## 🚀 Getting Started

### Prerequisites
- **Xcode 15.0+** with iOS 17.0+ SDK
- **Firebase Project** with Firestore enabled
- **Apple Developer Account** for device testing

### Setup Instructions

1. **Clone Repository**
   ```bash
   git clone https://github.com/your-username/wallyhub.git
   cd wallyhub
   ```

2. **Configure Environment**
   ```bash
   cp WallyHub/Resources/.env.example WallyHub/Resources/.env
   # Edit .env with your Firebase credentials
   ```

3. **Firebase Setup**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Deploy Firestore indexes
   firebase use wally-b635c
   firebase deploy --only firestore:indexes
   ```

4. **Open in Xcode**
   ```bash
   open WallyHub.xcodeproj
   ```

5. **Build & Run**
   - Select target device/simulator
   - Press `⌘+R` to build and run

## 🧪 Testing

### Unit Testing
```bash
# Run all tests
⌘+U in Xcode

# RIBs unit tests
- Router navigation logic
- Interactor business logic  
- Builder dependency injection
```

### Integration Testing
```bash
# Firebase integration tests
- Service layer functionality
- Real-time data synchronization
- Authentication flows
```

## 📊 Performance & Monitoring

### Memory Management
- **RIBs LeakDetector**: Automatic memory leak detection
- **Swift 6 Concurrency**: Proper async/await patterns with weak self
- **Task Cancellation**: Lifecycle-aware task management

### Firebase Analytics
- **Real-time Metrics**: User engagement & system performance
- **Error Tracking**: Comprehensive error logging & monitoring
- **Usage Analytics**: Feature adoption & user behavior insights

## 🔄 Development Workflow

### RIBs Development Pattern
1. **Define Business Logic** in Interactor
2. **Implement Navigation** in Router  
3. **Configure Dependencies** in Builder
4. **Create UI** in ViewController/SwiftUI Views
5. **Wire Communications** through Protocols

### Code Quality Standards
- **Protocol-Oriented Design**: Clear interfaces between components
- **Single Responsibility**: Each RIB handles one business concern
- **Dependency Injection**: Testable and modular architecture
- **Memory Safety**: Proper retain cycle prevention

## 📚 Architecture Resources

### RIBs Framework
- [Official RIBs Documentation](https://github.com/uber/RIBs)
- [RIBs iOS Tutorial](https://github.com/uber/RIBs/wiki)
- [Business Logic Architecture](https://eng.uber.com/new-rider-app/)

### Firebase Integration
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase Performance](https://firebase.google.com/docs/perf-mon)

## 🤝 Contributing

### Development Guidelines
1. **Follow RIBs Patterns**: Maintain proper Router-Interactor-Builder structure
2. **Role-Based Design**: Implement features within appropriate business scopes
3. **Memory Management**: Use weak self and proper task cancellation
4. **Security First**: Never hardcode credentials or sensitive data
5. **Test Coverage**: Include unit tests for business logic

### Pull Request Process
1. Create feature branch from `main`
2. Implement changes following architecture guidelines
3. Add appropriate unit tests
4. Update documentation if needed
5. Submit PR with detailed description

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Uber RIBs Team** - For the excellent business logic-driven architecture framework
- **Firebase Team** - For the comprehensive backend-as-a-service platform
- **Swift Community** - For modern iOS development patterns and best practices

---

**WallyHub** - Empowering educational photo sharing through modern iOS architecture 📱✨