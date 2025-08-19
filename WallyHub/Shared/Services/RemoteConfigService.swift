import Foundation
import FirebaseRemoteConfig
import FirebaseCore

// MARK: - Timeout Functions
func withTimeout<T>(
    seconds: TimeInterval,
    operation: @escaping () async throws -> T
) async throws -> T {
    return try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        
        group.addTask {
            try await Task.sleep(for: .seconds(seconds))
            throw TimeoutError()
        }
        
        guard let result = try await group.next() else {
            throw TimeoutError()
        }
        
        group.cancelAll()
        return result
    }
}

struct TimeoutError: Error, LocalizedError {
    var errorDescription: String? {
        return "작업이 시간 초과되었습니다."
    }
}
import Combine

// MARK: - Remote Config Keys

public struct RemoteConfigKeys {
    static let adminEmail = "admin_email"
    static let teacherEmail = "test_teacher_email"
    static let allowedDomain = "allowed_domain"
    static let configVersion = "config_version"
}

// MARK: - Remote Config Service Protocol

public protocol RemoteConfigService {
    func loadConfiguration() async throws
    func forceRefresh() async throws
    func getAdminEmail() -> String
    func getTeacherEmail() -> String
    func getAllowedDomain() -> String
    var isConfigurationLoaded: Bool { get }
    func getConfigVersion() -> String
}

// MARK: - Firebase Remote Config Service

public class FirebaseRemoteConfigService: RemoteConfigService, ObservableObject {
    @Published public private(set) var isConfigurationLoaded = false
    @Published public private(set) var lastUpdateTime: Date?
    
    private let remoteConfig: RemoteConfig
    private let userDefaults = UserDefaults.standard
    
    // Cache keys for UserDefaults
    private struct CacheKeys {
        static let adminEmail = "cached_admin_email"
        static let teacherEmail = "cached_test_teacher_email"
        static let allowedDomain = "cached_allowed_domain"
        static let configVersion = "cached_config_version"
        static let lastFetchTime = "remote_config_last_fetch_time"
    }
    
    // Default values (fallback)
    private struct DefaultValues {
        static let adminEmail = ""
        static let teacherEmail = ""
        static let allowedDomain = "korea.kr"
        static let configVersion = "v1.0.0"
    }
    
    public init() {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            fatalError("Firebase must be configured before initializing RemoteConfigService")
        }
        
        self.remoteConfig = RemoteConfig.remoteConfig()
        setupRemoteConfig()
        loadCachedConfiguration()
    }
    
    // MARK: - Public Methods
    
    /// 캐시를 무시하고 강제로 Firebase에서 새로운 Remote Config를 가져옵니다
    public func forceRefresh() async throws {
        print("🔄 Remote Config 강제 새로고침 시작")
        
        do {
            // 캐시 시간 초기화하여 강제로 새로 가져오기
            userDefaults.removeObject(forKey: CacheKeys.lastFetchTime)
            
            // Remote Config에서 최신 설정 가져오기 (5초 타임아웃)
            let status = try await withTimeout(seconds: 5) {
                return try await self.remoteConfig.fetch(withExpirationDuration: 60)
            }
            print("📡 Remote Config 강제 패치 상태: \(status)")
            
            let activated = try await remoteConfig.activate()
            print("🔄 Remote Config 강제 활성화: \(activated)")
            
            // 값들 확인 및 출력
            let adminEmail = remoteConfig.configValue(forKey: RemoteConfigKeys.adminEmail).stringValue ?? ""
            let teacherEmail = remoteConfig.configValue(forKey: RemoteConfigKeys.teacherEmail).stringValue ?? ""
            let domain = remoteConfig.configValue(forKey: RemoteConfigKeys.allowedDomain).stringValue ?? ""
            let version = remoteConfig.configValue(forKey: RemoteConfigKeys.configVersion).stringValue ?? ""
            
            print("📋 새로 가져온 Remote Config 값들:")
            print("   admin_email: '\(adminEmail)'")
            print("   test_teacher_email: '\(teacherEmail)'")
            print("   allowed_domain: '\(domain)'")
            print("   config_version: '\(version)'")
            
            // 성공하면 캐시에 저장
            cacheCurrentConfiguration()
            
            await MainActor.run {
                self.isConfigurationLoaded = true
                self.lastUpdateTime = Date()
            }
            
            userDefaults.set(Date(), forKey: CacheKeys.lastFetchTime)
            print("✅ Remote Config 강제 새로고침 완료")
            
        } catch {
            print("❌ Remote Config 강제 새로고침 실패: \(error)")
            throw error
        }
    }
    
    public func loadConfiguration() async throws {
        print("🔄 Remote Config 로드 시작")
        
        do {
            // 캐시된 설정이 최근(12시간 이내)이고 값이 유효한 경우에만 바로 반환
            if let lastFetch = userDefaults.object(forKey: CacheKeys.lastFetchTime) as? Date,
               Date().timeIntervalSince(lastFetch) < 12 * 60 * 60,
               isConfigurationLoaded {
                
                // 캐시된 값이 유효한지 확인
                let adminEmail = remoteConfig.configValue(forKey: RemoteConfigKeys.adminEmail).stringValue ?? ""
                let teacherEmail = remoteConfig.configValue(forKey: RemoteConfigKeys.teacherEmail).stringValue ?? ""
                
                if !adminEmail.isEmpty || !teacherEmail.isEmpty {
                    print("✅ 캐시된 Remote Config 사용 (12시간 이내) - 유효한 값 존재")
                    return
                } else {
                    print("⚠️ 캐시된 Remote Config가 비어있음 - 강제 새로고침")
                }
            }
            
            // Remote Config에서 최신 설정 가져오기 (5초 타임아웃)
            let status = try await withTimeout(seconds: 5) {
                return try await self.remoteConfig.fetch(withExpirationDuration: 60)
            }
            print("📡 Remote Config 패치 상태: \(status)")
            
            let activated = try await remoteConfig.activate()
            print("🔄 Remote Config 활성화: \(activated)")
            
            // 성공하면 캐시에 저장
            cacheCurrentConfiguration()
            
            await MainActor.run {
                self.isConfigurationLoaded = true
                self.lastUpdateTime = Date()
            }
            
            userDefaults.set(Date(), forKey: CacheKeys.lastFetchTime)
            print("✅ Remote Config 로드 완료")
            
        } catch {
            print("❌ Remote Config 로드 실패: \(error)")
            
            // 캐시된 설정이 있으면 그것을 사용
            if hasCachedConfiguration() {
                print("📂 캐시된 설정 사용")
                await MainActor.run {
                    self.isConfigurationLoaded = true
                }
            } else {
                print("❌ 캐시된 설정도 없음 - 기본값 사용")
                throw WallyError.configurationError
            }
        }
    }
    
    public func getAdminEmail() -> String {
        print("🔍 getAdminEmail() 호출 - isConfigurationLoaded: \(isConfigurationLoaded)")
        
        if isConfigurationLoaded {
            let value = remoteConfig.configValue(forKey: RemoteConfigKeys.adminEmail).stringValue ?? ""
            print("🔍 Remote Config admin_email 값: '\(value)'")
            if !value.isEmpty {
                return value
            }
        }
        
        // Fallback to cached value
        let cachedValue = userDefaults.string(forKey: CacheKeys.adminEmail) ?? DefaultValues.adminEmail
        print("🔍 캐시된 admin_email 값: '\(cachedValue)'")
        return cachedValue
    }
    
    public func getTeacherEmail() -> String {
        print("🔍 getTeacherEmail() 호출 - isConfigurationLoaded: \(isConfigurationLoaded)")
        
        if isConfigurationLoaded {
            let value = remoteConfig.configValue(forKey: RemoteConfigKeys.teacherEmail).stringValue ?? ""
            print("🔍 Remote Config test_teacher_email 값: '\(value)'")
            if !value.isEmpty {
                return value
            }
        }
        
        // Fallback to cached value
        let cachedValue = userDefaults.string(forKey: CacheKeys.teacherEmail) ?? DefaultValues.teacherEmail
        print("🔍 캐시된 test_teacher_email 값: '\(cachedValue)'")
        return cachedValue
    }
    
    public func getAllowedDomain() -> String {
        if isConfigurationLoaded {
            let value = remoteConfig.configValue(forKey: RemoteConfigKeys.allowedDomain).stringValue ?? ""
            if !value.isEmpty {
                return value
            }
        }
        
        // Fallback to cached value
        let cachedValue = userDefaults.string(forKey: CacheKeys.allowedDomain) ?? DefaultValues.allowedDomain
        return cachedValue
    }
    
    public func getConfigVersion() -> String {
        if isConfigurationLoaded {
            let value = remoteConfig.configValue(forKey: RemoteConfigKeys.configVersion).stringValue ?? ""
            if !value.isEmpty {
                return value
            }
        }
        
        // Fallback to cached value
        let cachedValue = userDefaults.string(forKey: CacheKeys.configVersion) ?? DefaultValues.configVersion
        return cachedValue
    }
    
    // MARK: - Private Methods
    
    private func setupRemoteConfig() {
        // 기본값 설정
        let defaultValues: [String: NSObject] = [
            RemoteConfigKeys.adminEmail: DefaultValues.adminEmail as NSString,
            RemoteConfigKeys.teacherEmail: DefaultValues.teacherEmail as NSString,
            RemoteConfigKeys.allowedDomain: DefaultValues.allowedDomain as NSString,
            RemoteConfigKeys.configVersion: DefaultValues.configVersion as NSString
        ]
        
        remoteConfig.setDefaults(defaultValues)
        
        // Remote Config 설정
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 12 * 60 * 60 // 12시간
        remoteConfig.configSettings = settings
        
        print("🔧 Remote Config 설정 완료")
    }
    
    private func loadCachedConfiguration() {
        // 캐시된 설정이 있으면 로드
        if hasCachedConfiguration() {
            isConfigurationLoaded = true
            if let lastFetch = userDefaults.object(forKey: CacheKeys.lastFetchTime) as? Date {
                lastUpdateTime = lastFetch
            }
            print("📂 캐시된 Remote Config 로드됨")
        }
    }
    
    private func cacheCurrentConfiguration() {
        userDefaults.set(getAdminEmail(), forKey: CacheKeys.adminEmail)
        userDefaults.set(getTeacherEmail(), forKey: CacheKeys.teacherEmail)
        userDefaults.set(getAllowedDomain(), forKey: CacheKeys.allowedDomain)
        userDefaults.set(getConfigVersion(), forKey: CacheKeys.configVersion)
        print("💾 Remote Config 캐시 저장 완료")
    }
    
    private func hasCachedConfiguration() -> Bool {
        return userDefaults.string(forKey: CacheKeys.allowedDomain) != nil
    }
}

// MARK: - Remote Config Service Extensions

extension FirebaseRemoteConfigService {
    /// 모든 Remote Config 값을 출력 (디버깅용)
    public func printAllConfigurations() {
        print("📋 현재 Remote Config 값들:")
        print("  - Admin Email: \(getAdminEmail())")
        print("  - Teacher Email: \(getTeacherEmail())")
        print("  - Allowed Domain: \(getAllowedDomain())")
        print("  - Config Version: \(getConfigVersion())")
        print("  - Configuration Loaded: \(isConfigurationLoaded)")
        print("  - Last Update: \(lastUpdateTime?.description ?? "없음")")
    }
    
    /// 캐시 클리어
    public func clearCache() {
        userDefaults.removeObject(forKey: CacheKeys.adminEmail)
        userDefaults.removeObject(forKey: CacheKeys.teacherEmail)
        userDefaults.removeObject(forKey: CacheKeys.allowedDomain)
        userDefaults.removeObject(forKey: CacheKeys.configVersion)
        userDefaults.removeObject(forKey: CacheKeys.lastFetchTime)
        
        isConfigurationLoaded = false
        lastUpdateTime = nil
        
        print("🗑️ Remote Config 캐시 클리어됨")
    }
    
}