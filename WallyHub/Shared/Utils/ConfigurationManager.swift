import Foundation
import Combine

// MARK: - Configuration Change Notifications
extension Notification.Name {
    static let firebaseConfigurationChanged = Notification.Name("firebaseConfigurationChanged")
    static let configurationReset = Notification.Name("configurationReset")
    static let configurationBackupCreated = Notification.Name("configurationBackupCreated")
    static let configurationRestored = Notification.Name("configurationRestored")
}

// MARK: - Configuration Models
struct AppConfiguration: Codable {
    var firebase: FirebaseConfig
    var development: DevelopmentConfig
    let app: AppInfo
}

struct FirebaseConfig: Codable {
    var enabled: Bool
    var autoInitialize: Bool
}

struct DevelopmentConfig: Codable {
    var showDebugInfo: Bool
}

struct AppInfo: Codable {
    let version: String
    let environment: String
}

// MARK: - Configuration Manager

public class ConfigurationManager: ObservableObject {
    public static let shared = ConfigurationManager()
    
    @Published private(set) var configuration: AppConfiguration
    @Published public private(set) var isFirebaseEnabled: Bool
    @Published private(set) var configurationChangeTimestamp: Date = Date()
    
    private let configFileName = "AppConfig"
    private let configFileExtension = "json"
    private let backupFileName = "AppConfig_backup"
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let defaultConfig = ConfigurationManager.loadDefaultConfiguration()
        self.configuration = defaultConfig
        self.isFirebaseEnabled = defaultConfig.firebase.enabled
        loadConfiguration()
        setupConfigurationMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Firebase 기능 활성화/비활성화
    func toggleFirebase(_ enabled: Bool) {
        let previousState = configuration.firebase.enabled
        var newFirebaseConfig = configuration.firebase
        newFirebaseConfig.enabled = enabled
        var newConfig = configuration
        newConfig.firebase = newFirebaseConfig
        updateConfiguration(newConfig)
        
        if previousState != enabled {
            NotificationCenter.default.post(
                name: .firebaseConfigurationChanged,
                object: self,
                userInfo: ["enabled": enabled, "previousState": previousState]
            )
        }
    }
    
    /// 개발 모드 디버그 정보 표시 토글
    func toggleDebugInfo(_ enabled: Bool) {
        var newDevelopmentConfig = configuration.development
        newDevelopmentConfig.showDebugInfo = enabled
        var newConfig = configuration
        newConfig.development = newDevelopmentConfig
        updateConfiguration(newConfig)
    }
    
    
    /// 설정을 기본값으로 초기화
    func resetToDefaults() {
        let defaultConfig = ConfigurationManager.loadDefaultConfiguration()
        updateConfiguration(defaultConfig)
        
        NotificationCenter.default.post(
            name: .configurationReset,
            object: self,
            userInfo: ["configuration": defaultConfig]
        )
    }
    
    /// 현재 설정을 백업파일로 저장
    func backupConfiguration() -> Bool {
        guard let url = getBackupFileURL(),
              let data = try? JSONEncoder().encode(configuration) else {
            print("❌ Failed to create backup")
            return false
        }
        
        do {
            try data.write(to: url)
            print("✅ Configuration backup created successfully")
            NotificationCenter.default.post(
                name: .configurationBackupCreated,
                object: self,
                userInfo: ["backupPath": url.path]
            )
            return true
        } catch {
            print("❌ Error creating backup: \(error)")
            return false
        }
    }
    
    /// 백업파일에서 설정 복원
    func restoreFromBackup() -> Bool {
        guard let url = getBackupFileURL(),
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let backupConfig = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            print("❌ Failed to restore from backup - backup file not found or corrupted")
            return false
        }
        
        updateConfiguration(backupConfig)
        print("✅ Configuration restored from backup successfully")
        NotificationCenter.default.post(
            name: .configurationRestored,
            object: self,
            userInfo: ["configuration": backupConfig]
        )
        return true
    }
    
    /// 백업 파일 존재 여부 확인
    func hasBackup() -> Bool {
        guard let url = getBackupFileURL() else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
    
    // MARK: - Private Methods
    
    private func loadConfiguration() {
        guard let url = getConfigFileURL(),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            print("⚠️ Failed to load configuration, using defaults")
            return
        }
        
        DispatchQueue.main.async {
            self.configuration = config
            self.isFirebaseEnabled = config.firebase.enabled
        }
    }
    
    private func updateConfiguration(_ newConfig: AppConfiguration) {
        DispatchQueue.main.async {
            self.configuration = newConfig
            self.isFirebaseEnabled = newConfig.firebase.enabled
            self.configurationChangeTimestamp = Date()
        }
        
        saveConfiguration(newConfig)
    }
    
    private func saveConfiguration(_ config: AppConfiguration) {
        guard let url = getConfigFileURL(),
              let data = try? JSONEncoder().encode(config) else {
            print("❌ Failed to save configuration")
            return
        }
        
        do {
            try data.write(to: url)
            print("✅ Configuration saved successfully")
        } catch {
            print("❌ Error saving configuration: \(error)")
        }
    }
    
    private func getConfigFileURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                               in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent("\(configFileName).\(configFileExtension)")
    }
    
    private func getBackupFileURL() -> URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                               in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent("\(backupFileName).\(configFileExtension)")
    }
    
    private func setupConfigurationMonitoring() {
        $configuration
            .dropFirst()
            .sink { [weak self] _ in
                self?.configurationChangeTimestamp = Date()
            }
            .store(in: &cancellables)
    }
    
    private static func loadDefaultConfiguration() -> AppConfiguration {
        // 번들에서 기본 설정 로드
        guard let url = Bundle.main.url(forResource: "AppConfig", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(AppConfiguration.self, from: data) else {
            // 번들에서 로드 실패 시 하드코딩된 기본값 사용
            return AppConfiguration(
                firebase: FirebaseConfig(enabled: false, autoInitialize: false),
                development: DevelopmentConfig(showDebugInfo: false),
                app: AppInfo(version: "1.0.0", environment: "development")
            )
        }
        
        return config
    }
}

// MARK: - Configuration Extensions
extension ConfigurationManager {
    /// 현재 환경이 개발 환경인지 확인
    var isDevelopmentEnvironment: Bool {
        configuration.app.environment == "development"
    }
    
    /// Firebase 자동 초기화 여부
    var shouldAutoInitializeFirebase: Bool {
        configuration.firebase.enabled && configuration.firebase.autoInitialize
    }
    
    /// 디버그 정보 표시 여부
    var shouldShowDebugInfo: Bool {
        configuration.development.showDebugInfo && isDevelopmentEnvironment
    }
    
    
    /// 마지막 설정 변경 시간
    public var lastConfigurationChange: Date {
        configurationChangeTimestamp
    }
    
    /// 설정 변경 감지를 위한 Publisher
    var configurationPublisher: AnyPublisher<AppConfiguration, Never> {
        $configuration.eraseToAnyPublisher()
    }
    
    /// Firebase 상태 변경 감지를 위한 Publisher
    var firebaseStatusPublisher: AnyPublisher<Bool, Never> {
        $isFirebaseEnabled.eraseToAnyPublisher()
    }
}