import Foundation
import Combine

// MARK: - ServiceFactory Notifications
extension Notification.Name {
    static let serviceFactoryConfigurationChanged = Notification.Name("serviceFactoryConfigurationChanged")
}

// MARK: - Service Factory

public class ServiceFactory: ObservableObject {
    public static let shared = ServiceFactory()
    
    private let configManager = ConfigurationManager.shared
    
    // 서비스 인스턴스들
    private var _authService: AuthenticationService?
    private var _boardService: BoardService?
    private var _studentService: StudentService?
    private var _photoService: PhotoService?
    private var _remoteConfigService: RemoteConfigService?
    
    private init() {
        setupConfigurationMonitoring()
    }
    
    private func setupConfigurationMonitoring() {
        // Firebase 설정 변경 감지
        configManager.$isFirebaseEnabled
            .dropFirst()
            .sink { [weak self] isEnabled in
                print("🔧 Firebase configuration changed: \(isEnabled)")
                self?.resetServices()
                self?.notifyServiceChange(firebaseEnabled: isEnabled)
            }
            .store(in: &cancellables)
            
        // NotificationCenter를 통한 설정 변경 감지
        NotificationCenter.default
            .publisher(for: .firebaseConfigurationChanged)
            .sink { [weak self] notification in
                if let userInfo = notification.userInfo,
                   let enabled = userInfo["enabled"] as? Bool,
                   let previousState = userInfo["previousState"] as? Bool {
                    print("📢 Firebase configuration notification: \(previousState) → \(enabled)")
                    self?.handleConfigurationChange(enabled: enabled, previousState: previousState)
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Service Providers
    
    public var authService: AuthenticationService {
        if _authService == nil {
            _authService = createAuthService()
        }
        return _authService!
    }
    
    public var boardService: BoardService {
        if _boardService == nil {
            _boardService = createBoardService()
        }
        return _boardService!
    }
    
    public var studentService: StudentService {
        if _studentService == nil {
            _studentService = createStudentService()
        }
        return _studentService!
    }
    
    public var photoService: PhotoService {
        if _photoService == nil {
            _photoService = createPhotoService()
        }
        return _photoService!
    }
    
    // MARK: - Private Factory Methods
    
    private func createAuthService() -> AuthenticationService {
        return FirebaseAuthenticationService(remoteConfigService: remoteConfigService)
    }
    
    private func createBoardService() -> BoardService {
        return FirebaseBoardService()
    }
    
    private func createStudentService() -> StudentService {
        return FirebaseStudentService()
    }
    
    private func createPhotoService() -> PhotoService {
        return FirebasePhotoService()
    }
    
    // MARK: - Service Reset and Configuration Handling
    
    public var remoteConfigService: RemoteConfigService {
        if _remoteConfigService == nil {
            _remoteConfigService = createRemoteConfigService()
        }
        return _remoteConfigService!
    }
    
    private func createRemoteConfigService() -> RemoteConfigService {
        return FirebaseRemoteConfigService()
    }
    
    private func resetServices() {
        _authService = nil
        _boardService = nil
        _studentService = nil
        _photoService = nil
        _remoteConfigService = nil
        
        print("🔄 Services reset due to configuration change")
        print("📱 Firebase enabled: \(configManager.isFirebaseEnabled)")
    }
    
    private func handleConfigurationChange(enabled: Bool, previousState: Bool) {
        if enabled != previousState {
            print("🔄 Firebase 서비스 상태 변경: \(enabled ? "활성화" : "비활성화")")
            
            if enabled && !previousState {
                print("🚀 Firebase 서비스로 전환")
            } else if !enabled && previousState {
                print("⚠️ Firebase 서비스 비활성화")
            }
        }
    }
    
    private func notifyServiceChange(firebaseEnabled: Bool) {
        NotificationCenter.default.post(
            name: .serviceFactoryConfigurationChanged,
            object: self,
            userInfo: [
                "firebaseEnabled": firebaseEnabled,
                "serviceType": "Firebase",
                "timestamp": Date()
            ]
        )
    }
}

// MARK: - Service Factory Extensions
extension ServiceFactory {
    /// 현재 사용 중인 서비스 타입 정보
    public var serviceInfo: String {
        return "Using Firebase services"
    }
    
    /// 서비스 상태 디버그 정보
    public var debugInfo: [String: Any] {
        return [
            "firebase_enabled": configManager.isFirebaseEnabled,
            "auth_service": String(describing: type(of: authService)),
            "board_service": String(describing: type(of: boardService)),
            "student_service": String(describing: type(of: studentService)),
            "photo_service": String(describing: type(of: photoService)),
            "last_config_change": configManager.lastConfigurationChange
        ]
    }
    
    /// 강제로 서비스를 다시 초기화 (디버깅/테스팅 용도)
    public func forceServiceReset() {
        print("🔧 Force resetting all services...")
        resetServices()
        notifyServiceChange(firebaseEnabled: configManager.isFirebaseEnabled)
    }
    
    /// 현재 활성화된 서비스들의 타입을 문자열로 반환
    public var activeServiceTypes: [String: String] {
        return [
            "AuthService": String(describing: type(of: authService)),
            "BoardService": String(describing: type(of: boardService)),
            "StudentService": String(describing: type(of: studentService)),
            "PhotoService": String(describing: type(of: photoService))
        ]
    }
}