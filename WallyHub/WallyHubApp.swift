import SwiftUI
import RIBs
import FirebaseCore
import FirebaseRemoteConfig

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    // AppComponent에 접근하기 위한 참조
    var appComponent: AppComponent?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Configure Firebase with wallydb database
        print("🔥 Firebase 초기화")
        FirebaseApp.configure()
        
        print("✅ 앱 초기화 완료")
        return true
    }
    
    func configureRemoteConfig(with appComponent: AppComponent) {
        self.appComponent = appComponent
        
        // Remote Config 초기화 (백그라운드에서)
        Task {
            await loadRemoteConfiguration()
        }
    }
    
    private func loadRemoteConfiguration() async {
        guard let appComponent = self.appComponent else {
            print("❌ AppComponent가 설정되지 않음")
            return
        }
        
        print("🔄 Remote Config 로드 시작")
        let remoteConfigService = appComponent.remoteConfigService
        
        do {
            try await remoteConfigService.loadConfiguration()
            
            // EnvironmentLoader에 Remote Config Service 설정
            EnvironmentLoader.configure(with: remoteConfigService)
            
            print("✅ Remote Config 로드 완료")
        } catch {
            print("⚠️ Remote Config 로드 실패, 캐시된 값 사용: \(error)")
            
            // 실패해도 EnvironmentLoader 설정 (캐시된 값 사용)
            EnvironmentLoader.configure(with: remoteConfigService)
        }
    }
}

// MARK: - Main App

@main
struct WallyHubApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let appComponent: AppComponent
    private let rootBuilder: RootBuilder
    
    init() {
        // Initialize app-level dependencies
        self.appComponent = AppComponent()
        self.rootBuilder = RootBuilder(dependency: appComponent)
        
        // Configure Remote Config in AppDelegate
        delegate.configureRemoteConfig(with: appComponent)
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(rootBuilder: rootBuilder)
                .preferredColorScheme(.light)
        }
    }
}

// MARK: - Root View Bridge

struct RootView: UIViewControllerRepresentable {
    let rootBuilder: RootBuilder
    private let launchRouter: RootRouting
    
    init(rootBuilder: RootBuilder) {
        self.rootBuilder = rootBuilder
        self.launchRouter = rootBuilder.build()
        // Activate the RIB to start the app flow
        self.launchRouter.interactable.activate()
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        print("🚀 RootView.makeUIViewController() - RIB 활성화됨")
        return launchRouter.viewControllable.uiviewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // RIBs manage their own state and UI updates through interactors
        // SwiftUI-RIBs bridge doesn't need manual updates
    }
}

// MARK: - Coordinator (Optional for Complex App State)

final class AppStateCoordinator: ObservableObject {
    @Published var isLaunching = true
    @Published var currentUserRole: UserRole?
    
    private let appComponent: AppComponent
    
    init(appComponent: AppComponent) {
        self.appComponent = appComponent
        observeAuthenticationState()
    }
    
    private func observeAuthenticationState() {
        // Monitor authentication state changes
        // This can be enhanced with Combine/RxSwift integration
    }
}

// MARK: - App Component (Dependency Container)

final class AppComponent: RootDependency {
    
    // MARK: - Shared Services (Singleton Pattern)
    
    lazy var remoteConfigService: RemoteConfigService = {
        return FirebaseRemoteConfigService()
    }()
    
    lazy var authenticationService: AuthenticationService = {
        let service = FirebaseAuthenticationService(remoteConfigService: remoteConfigService)
        // Configure for wallydb database
        return service
    }()
    
    lazy var boardService: BoardService = {
        let service = FirebaseBoardService()
        // Configure for wallydb database
        return service
    }()
    
    lazy var studentService: StudentService = {
        let service = FirebaseStudentService()
        // Configure for wallydb database
        return service
    }()
    
    lazy var photoService: PhotoService = {
        let service = FirebasePhotoService()
        // Configure for wallydb database
        return service
    }()
    
    lazy var photoViewTrackingService: PhotoViewTrackingService = {
        let service = FirebasePhotoViewTrackingService()
        // Configure for wallydb database
        return service
    }()
    
    // MARK: - Configuration Management
    
    lazy var configurationManager: ConfigurationManager = {
        return ConfigurationManager.shared
    }()
    
    // MARK: - Service Factory
    
    lazy var serviceFactory: ServiceFactory = {
        return ServiceFactory.shared
    }()
}