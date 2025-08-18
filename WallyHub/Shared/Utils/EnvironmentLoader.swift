import Foundation

// MARK: - Environment Variables Loader (Remote Config Based)

public class EnvironmentLoader {
    private static var remoteConfigService: RemoteConfigService?
    
    /// Remote Config Service를 설정합니다
    public static func configure(with remoteConfigService: RemoteConfigService) {
        self.remoteConfigService = remoteConfigService
        print("🔧 EnvironmentLoader: Remote Config Service 설정 완료")
    }
    
    /// 환경변수 값을 가져옵니다 (Remote Config 우선, 시스템 환경변수 fallback)
    public static func getValue(for key: String) -> String? {
        // 1. 시스템 환경변수에서 먼저 확인
        if let systemValue = ProcessInfo.processInfo.environment[key] {
            print("📱 시스템 환경변수에서 \(key) 값 발견: \(systemValue)")
            return systemValue
        }
        
        // 2. Remote Config에서 확인
        guard let remoteConfig = remoteConfigService else {
            print("⚠️ Remote Config Service가 설정되지 않았습니다. configure(with:)를 먼저 호출하세요")
            return nil
        }
        
        // 알려진 Remote Config 키들 매핑
        switch key {
        case "ADMIN_EMAIL":
            let value = remoteConfig.getAdminEmail()
            return value.isEmpty ? nil : value
        case "TEACHER_EMAIL", "TEST_TEACHER_EMAIL":
            let value = remoteConfig.getTeacherEmail()
            return value.isEmpty ? nil : value
        case "ALLOWED_DOMAIN":
            let value = remoteConfig.getAllowedDomain()
            return value.isEmpty ? nil : value
        case "CONFIG_VERSION":
            let value = remoteConfig.getConfigVersion()
            return value.isEmpty ? nil : value
        default:
            print("⚠️ 알 수 없는 환경변수 키: \(key)")
            return nil
        }
    }
    
    /// 특정 키에 대한 환경변수를 설정합니다 (테스트용 - 시스템 환경변수만)
    @available(*, deprecated, message: "테스트 목적으로만 사용하세요. 실제 값은 Firebase Remote Config에서 관리됩니다.")
    public static func setValue(_ value: String, for key: String) {
        print("⚠️ setValue는 deprecated 되었습니다. Firebase Remote Config를 사용하세요.")
    }
    
    /// 현재 설정된 모든 환경변수를 출력합니다 (디버그용)
    public static func printLoadedVariables() {
        print("🔍 현재 환경변수 상태:")
        
        // 시스템 환경변수
        print("📱 시스템 환경변수:")
        let relevantKeys = ["ADMIN_EMAIL", "TEACHER_EMAIL", "TEST_TEACHER_EMAIL", "ALLOWED_DOMAIN", "CONFIG_VERSION"]
        for key in relevantKeys {
            if let value = ProcessInfo.processInfo.environment[key] {
                print("  \(key) = \(value)")
            }
        }
        
        // Remote Config 값들
        print("🔥 Remote Config 값들:")
        guard let remoteConfig = remoteConfigService else {
            print("  Remote Config Service가 설정되지 않음")
            return
        }
        
        print("  ADMIN_EMAIL = \(remoteConfig.getAdminEmail())")
        print("  TEST_TEACHER_EMAIL = \(remoteConfig.getTeacherEmail())")
        print("  ALLOWED_DOMAIN = \(remoteConfig.getAllowedDomain())")
        print("  CONFIG_VERSION = \(remoteConfig.getConfigVersion())")
        print("  Configuration Loaded = \(remoteConfig.isConfigurationLoaded)")
    }
    
    // MARK: - Deprecated Methods (Legacy .env support)
    
    @available(*, deprecated, message: "더 이상 .env 파일을 사용하지 않습니다. Firebase Remote Config를 사용하세요.")
    public static func loadEnvironmentVariables() {
        print("⚠️ loadEnvironmentVariables()는 deprecated 되었습니다. Remote Config를 사용하세요.")
    }
    
    @available(*, deprecated, message: "더 이상 .env 파일을 사용하지 않습니다. Firebase Remote Config를 사용하세요.")
    public static func clearEnvironment() {
        print("⚠️ clearEnvironment()는 deprecated 되었습니다. Remote Config를 사용하세요.")
    }
}

// MARK: - ProcessInfo Extension

extension ProcessInfo {
    /// Remote Config를 포함한 환경변수 값을 가져옵니다
    public func environmentValue(for key: String) -> String? {
        // 1. 시스템 환경변수에서 먼저 확인
        if let systemValue = environment[key] {
            return systemValue
        }
        
        // 2. Remote Config에서 확인
        return EnvironmentLoader.getValue(for: key)
    }
    
    /// .env 파일을 포함한 환경변수 값을 가져옵니다 (Deprecated)
    @available(*, deprecated, message: "environmentValue(for:)를 사용하세요. Remote Config 기반으로 변경되었습니다.")
    public func legacyEnvironmentValue(for key: String) -> String? {
        print("⚠️ legacyEnvironmentValue는 deprecated 되었습니다. environmentValue(for:)를 사용하세요.")
        return environmentValue(for: key)
    }
}