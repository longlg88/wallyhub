# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Structure

This repository contains the WallyHub project, a complete iOS application built using Uber's RIBs (Router-Interactor-Builder) architecture framework with **role-based business scope design** for educational photo sharing.

### WallyHub - iOS RIBs Role-Based Architecture Project

**Migration Sources**: 
- `../art_wall/WallyApp` (Swift Package - Business logic, models, services)
- `../art_wall/WallyiOSApp` (iOS App - UI, ViewModels, feature modules)

**Current Architecture**: Role-based RIBs framework for business logic-driven modular development  
**Purpose**: Modern iOS app for photo sharing in educational environments with clear user role separation

## Project Status & Implementation

### ✅ Completed Implementation

#### Core Architecture
- **RIBs Framework Integration**: Complete implementation with official Uber RIBs iOS framework
- **Role-Based Design**: Top-level RIBs organized by user roles (Student/Teacher/Admin)
- **Firebase Integration**: Full integration with "wallydb" database and real-time data sync
- **Memory Management**: Proper cleanup and leak prevention for all RIBs

#### Implemented RIBs Structure
```
WallyHub/
├── RootRIB/                        # App entry point
├── AuthRIB/                        # Authentication flow
│   ├── LoginRIB/                   # Teacher/Admin login
│   ├── RoleSelectionRIB/           # User role selection
│   └── StudentLoginRIB/            # Student direct access
├── AdminRIB/                       # 👑 ADMIN BUSINESS SCOPE
│   ├── AdminViewController.swift   # Black background admin dashboard
│   ├── AdminInteractor.swift      # Admin business logic coordination
│   ├── AdminRouter.swift          # Admin child RIB navigation
│   ├── SystemDashboardRIB/        # Real-time system monitoring
│   │   ├── SystemDashboardInteractor.swift  # Firebase metrics calculation
│   │   ├── SystemDashboardViewController.swift # Performance charts & stats
│   │   └── [Builder, Router]
│   ├── AllBoardsManagementRIB/     # Complete board management
│   │   ├── AllBoardsManagementInteractor.swift # Board CRUD operations
│   │   ├── AllBoardsManagementViewController.swift # Board list with filters
│   │   └── [Builder, Router]
│   └── UserManagementRIB/          # User account management
├── Shared/                         # Shared business components
│   ├── Services/                   # Firebase service implementations
│   │   ├── BoardService.swift      # Real board operations
│   │   ├── StudentService.swift    # Student data management
│   │   ├── PhotoService.swift      # Photo upload/retrieval
│   │   └── AuthenticationService.swift # User authentication
│   ├── Models/                     # Data models
│   └── Components/                 # Reusable UI components
│       ├── ModernLoadingView.swift # Loading states
│       └── ModernErrorView.swift   # Error handling
```

#### Key Features Implemented

**Admin Dashboard:**
- ✅ **Black Background Theme**: Enhanced dark mode for admin interface
- ✅ **System Dashboard**: Real-time Firebase metrics and performance monitoring
- ✅ **Board Management**: Complete CRUD operations with search and filtering
- ✅ **Memory Leak Prevention**: Proper RIBs lifecycle management

**Data Integration:**
- ✅ **Real Firebase Data**: No mock data - all connected to live Firebase
- ✅ **System Metrics**: Teacher count, board statistics, photo analytics
- ✅ **Performance Monitoring**: Firebase activity, data distribution, storage usage
- ✅ **Error Handling**: Comprehensive error states and user feedback

**Memory & Performance:**
- ✅ **RIBs LeakDetector Compliance**: All memory leaks resolved
- ✅ **Swift 6 Concurrency**: Proper async/await patterns with weak self
- ✅ **Task Management**: Cancellable tasks with lifecycle management
- ✅ **UI Performance**: Safe frame calculations and constraint handling

## WallyHub Architecture Guidelines

### Deep Analysis Requirement
- **CRITICAL: When any WallyHub related question, bug report, or log analysis is received, IMMEDIATELY perform comprehensive analysis of ALL Swift files in the WallyHub directory**
- **NEVER attempt to answer WallyHub questions based on partial knowledge**
- **ALWAYS use Task tool with general-purpose agent to thoroughly analyze the entire Swift codebase before providing solutions**
- **Must understand complete data flow: how data is stored, retrieved, and processed across all services, repositories**
- **Pay special attention to data consistency between storage patterns and query patterns**

### Firebase Configuration
- **ALWAYS use "wallydb" as the Firebase database name**
- **NEVER use default database - always specify wallydb**
- Configure all Firestore references to use wallydb database
- Database reference format: `Firestore.firestore(database: "wallydb")`
- **NEVER create temporary workarounds or simplified queries**
- **ALWAYS wait for proper Firebase indexes to be created**
- **NEVER suggest "임시 해결책" or temporary solutions for Firebase issues**

### Architecture Philosophy
- **NEVER use temporary solutions or simple fixes**
- **NEVER resort to "임시방편", "간단한 방법", or "임시적으로"**
- **ALWAYS find and fix root causes, not symptoms**
- **ALWAYS maintain proper role-based modular architecture**
- **NEVER suggest temporary workarounds like adding code to existing files**
- **ALWAYS ensure proper project structure and file organization**

## RIBs Framework Protocol Guidelines

RIBs 프레임워크에서 protocols 정의 위치는 명확한 규칙이 있습니다. 각 파일의 역할에 따라 어디에 protocol을 정의해야 하는지에 대한 가이드라인입니다.

### RIBs Protocol 정의 위치 가이드

#### 1. Builder.swift - Dependency & Component Protocols

```swift
// AdminBuilder.swift
import RIBs

// 👍 이 RIB이 필요로 하는 외부 의존성
protocol AdminDependency: Dependency {
    var boardService: BoardService { get }
    var studentService: StudentService { get }
}

// 👍 이 RIB이 제공하는 의존성 (자식 RIB들을 위해)
final class AdminComponent: Component<AdminDependency> {
    var boardService: BoardService {
        return dependency.boardService
    }
}

// 👍 Builder 자체의 interface
protocol AdminBuildable: Buildable {
    func build(withListener listener: AdminListener?) -> AdminRouting
}
```

#### 2. Interactor.swift - Business Logic Protocols

```swift
// AdminInteractor.swift
import RIBs

// 👍 View → Interactor 통신
protocol AdminPresentableListener: AnyObject {
    func didTapSystemDashboard()
    func didTapAllBoardsManagement()
}

// 👍 Parent RIB이 구현해야 하는 listener
protocol AdminListener: AnyObject {
    func adminDidRequestSignOut()
}

// 👍 Interactor의 라우팅 권한 정의
protocol AdminInteractable: Interactable {
    var router: AdminRouting? { get set }
    var listener: AdminListener? { get set }
}
```

#### 3. Router.swift - Navigation Protocols만

```swift
// AdminRouter.swift
import RIBs

// 👍 Router의 navigation interface만 정의
protocol AdminRouting: ViewableRouting {
    func routeToSystemDashboard()
    func routeToAllBoardsManagement()
    func dismissChild()
}
```

#### 4. ViewController.swift - View Protocols

```swift
// AdminViewController.swift
import RIBs

// 👍 Interactor → View 통신
protocol AdminPresentable: Presentable {
    var listener: AdminPresentableListener? { get set }
}

// 👍 Router → View 통신 (navigation을 위한)
protocol AdminViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss()
}
```

### 핵심 원칙

1. **Business Logic Protocols** → `Interactor.swift`
2. **Dependency Protocols** → `Builder.swift` 
3. **Navigation Protocols** → `Router.swift`
4. **View Protocols** → `ViewController.swift`
5. **각 protocol은 한 곳에만 정의**

## Security Requirements
- **🚨 NEVER hardcode ANY information in source code**
- **❌ NO hardcoded emails, API keys, passwords, credentials, URLs, or ANY data values**
- **❌ NO hardcoded production data, test data, or ANY literal values in fallback/default scenarios**
- **❌ NO hardcoded information in print/log statements**
- **❌ NO hardcoded configuration values, endpoints, or ANY fixed data**
- **✅ ALWAYS use environment variables (.env files) or Xcode configuration for ALL data**
- **✅ ALWAYS fail gracefully when configuration is missing - NEVER use ANY hardcoded defaults**
- **✅ ALWAYS validate configuration files exist before proceeding**
- **✅ ALL data must come from external configuration sources**

## Code Quality Standards
- **ALWAYS use RIBs framework (https://github.com/uber/ribs-ios)**
- **Role-based architecture**: All functionality organized by user roles
- **RIBs Builder Pattern**: Always use `AdminListener?` (Optional) for listener parameter types, but keep `withListener` parameter label
- Modern Swift patterns: Protocol-oriented programming, async/await
- SwiftUI for UI layer with UIHostingController integration
- Firebase integration: Preserve "wallydb" database and existing indexes
- Real-time updates: Integrate Firestore listeners into RIB lifecycle management
- No code duplication: Single source of truth for business logic in role-specific Interactors

## Memory Management & Performance
- **Swift 6 Concurrency**: Always use `[weak self]` in Task and async contexts
- **RIBs Lifecycle**: Proper cleanup in `willResignActive()` and `deinit`
- **Task Cancellation**: Track and cancel running tasks to prevent memory leaks
- **Frame Safety**: Use `max()`, `min()`, `isFinite` for SwiftUI calculations
- **UI Performance**: Efficient LazyVGrid and ScrollView implementations

## What NOT to do
- ❌ Never break role boundaries (Student logic in Admin RIB, etc.)
- ❌ Never share business logic between role RIBs directly
- ❌ Never use placeholder/dummy implementations
- ❌ Never sacrifice role-based architecture for quick fixes
- ❌ **NEVER create or use Mock implementations** (MockPhotoService, MockRepository, etc.)
- ❌ **NEVER use mock:// URLs or dummy data** - always integrate with real Firebase
- ❌ **NEVER bypass real permission requests** - use actual iOS Photo Library access
- ❌ **NEVER use "더 간단한 해결책" (simpler solutions)** - always find and fix root causes properly
- ❌ **NEVER copy files between role RIBs** - solve access issues through shared services

## Build and Development
```bash
# Navigate to WallyHub
cd WallyHub

# Build for simulator  
# Use proper Xcode build system that respects role-based module structure
```

**IMPORTANT BUILD POLICY**:
- **NEVER attempt to build the project unless explicitly requested by the user**
- User handles all build operations and testing
- Focus on role-based code implementation and architecture only
- Wait for user's explicit build request before using any build tools

## Firestore Index Management
- **Current Indexes Location**: `WallyHub/firestore.indexes.json`
- **ALWAYS use wallydb database for all Firestore operations**
- **ALWAYS reuse existing indexes - NEVER create new indexes unless absolutely necessary**
- **Check current indexes**: `firebase firestore:indexes --database wallydb`
- **Deploy indexes**: `firebase deploy --only firestore:indexes`

#### Current Firestore Indexes (wallydb):
```json
{
  "indexes": [
    {
      "collectionGroup": "boards",
      "fields": [
        { "fieldPath": "adminId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "photos", 
      "fields": [
        { "fieldPath": "boardId", "order": "ASCENDING" },
        { "fieldPath": "studentId", "order": "ASCENDING" },
        { "fieldPath": "uploadedAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "students",
      "fields": [
        { "fieldPath": "boardId", "order": "ASCENDING" },
        { "fieldPath": "joinedAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

## Communication Guidelines
- **ALWAYS ask for clarification when requests are ambiguous or unclear**
- If a request could be interpreted multiple ways, confirm the intended scope before proceeding
- When implementing features, always confirm which user role(s) the feature belongs to
- **NEVER assume or guess the user's intent** - always confirm when in doubt
- For role-specific features, always implement within the appropriate role RIB

## Development Commands

```bash
# Navigate to WallyHub
cd WallyHub

# Firebase Operations
firebase firestore:indexes --database wallydb          # View indexes
firebase deploy --only firestore:indexes              # Deploy indexes
firebase use wally-b635c                              # Set project

# Git Operations (when requested)
git status                                            # Check status
git add .                                            # Stage changes
git commit -m "message"                              # Commit changes
```

## Recent Achievements

### ✅ Successfully Completed
1. **Memory Management**: Eliminated all RIBs LeakDetector errors
2. **Firebase Integration**: Real data loading in SystemDashboard and AllBoardsManagement
3. **UI Polish**: Black admin theme with proper text contrast
4. **Performance**: Swift 6 compliant concurrency patterns
5. **Architecture**: Clean role-based RIBs structure

### 🎯 Current Focus Areas
- **User Experience**: Seamless navigation between admin functions
- **Data Consistency**: Reliable Firebase operations with proper error handling
- **Code Quality**: Maintainable RIBs patterns following best practices
- **Performance**: Efficient memory usage and responsive UI

This project demonstrates a complete, production-ready iOS application built with modern Swift patterns, Firebase integration, and scalable RIBs architecture.