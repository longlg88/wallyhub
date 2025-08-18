import Foundation

// MARK: - Remote Config 디버깅 도우미

public struct RemoteConfigDebugHelper {
    
    /// Remote Config 상태를 자세히 출력
    public static func printConfigStatus(service: RemoteConfigService) {
        print("\n" + String(repeating: "=", count: 50))
        print("📊 REMOTE CONFIG DEBUG STATUS")
        print(String(repeating: "=", count: 50))
        
        print("🔄 Configuration Loaded: \(service.isConfigurationLoaded)")
        print("📧 Admin Email: '\(service.getAdminEmail())'")
        print("👨‍🏫 Teacher Email: '\(service.getTeacherEmail())'")
        print("🌐 Allowed Domain: '\(service.getAllowedDomain())'")
        print("📝 Config Version: '\(service.getConfigVersion())'")
        
        // 값들이 비어있는지 확인
        let adminEmpty = service.getAdminEmail().isEmpty
        let teacherEmpty = service.getTeacherEmail().isEmpty
        let domainEmpty = service.getAllowedDomain().isEmpty
        
        print("\n📋 VALUE CHECK:")
        print("  - Admin Email Empty: \(adminEmpty ? "❌" : "✅")")
        print("  - Teacher Email Empty: \(teacherEmpty ? "❌" : "✅")")
        print("  - Domain Empty: \(domainEmpty ? "❌" : "✅")")
        
        if adminEmpty && teacherEmpty {
            print("\n⚠️ WARNING: 모든 이메일이 비어있습니다!")
            print("   Firebase Console에서 Remote Config를 설정했는지 확인하세요.")
        }
        
        print(String(repeating: "=", count: 50) + "\n")
    }
    
    /// 이메일 검증 테스트
    public static func testEmailValidation(service: RemoteConfigService, testEmails: [String]) {
        print("\n" + String(repeating: "=", count: 50))
        print("🧪 EMAIL VALIDATION TEST")
        print(String(repeating: "=", count: 50))
        
        let adminEmail = service.getAdminEmail().lowercased()
        let teacherEmail = service.getTeacherEmail().lowercased()
        let allowedDomain = service.getAllowedDomain().lowercased()
        
        print("📋 허용된 설정:")
        print("  - Admin: \(adminEmail)")
        print("  - Teacher: \(teacherEmail)")
        print("  - Domain: @\(allowedDomain)")
        
        print("\n🧪 테스트 결과:")
        
        for email in testEmails {
            let lowerEmail = email.lowercased()
            let isAllowed = lowerEmail == adminEmail || 
                           lowerEmail == teacherEmail || 
                           lowerEmail.hasSuffix("@\(allowedDomain)")
            
            let status = isAllowed ? "✅ 허용" : "❌ 차단"
            print("  - \(email): \(status)")
        }
        
        print(String(repeating: "=", count: 50) + "\n")
    }
    
    /// 캐시 상태 확인
    public static func printCacheStatus() {
        print("\n" + String(repeating: "=", count: 50))
        print("💾 CACHE STATUS")
        print(String(repeating: "=", count: 50))
        
        let userDefaults = UserDefaults.standard
        let cacheKeys = [
            "cached_admin_email",
            "cached_test_teacher_email", 
            "cached_allowed_domain",
            "cached_config_version",
            "remote_config_last_fetch_time"
        ]
        
        for key in cacheKeys {
            if let value = userDefaults.object(forKey: key) {
                if key == "remote_config_last_fetch_time" {
                    if let date = value as? Date {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        formatter.timeStyle = .medium
                        print("  - \(key): \(formatter.string(from: date))")
                    }
                } else {
                    print("  - \(key): \(value)")
                }
            } else {
                print("  - \(key): (없음)")
            }
        }
        
        print(String(repeating: "=", count: 50) + "\n")
    }
    
    /// 종합 진단
    public static func runFullDiagnosis(service: RemoteConfigService) {
        print("\n🔍 REMOTE CONFIG 종합 진단 시작\n")
        
        // 1. 기본 상태 확인
        printConfigStatus(service: service)
        
        // 2. 캐시 상태 확인
        printCacheStatus()
        
        // 3. 이메일 검증 테스트
        let testEmails = [
            service.getAdminEmail(),
            service.getTeacherEmail(),
            "test@korea.kr",
            "invalid@gmail.com",
            "another@korea.kr"
        ].filter { !$0.isEmpty }
        
        if !testEmails.isEmpty {
            testEmailValidation(service: service, testEmails: testEmails)
        }
        
        // 4. 권장사항
        print("💡 권장사항:")
        if !service.isConfigurationLoaded {
            print("  - Remote Config 로드를 시도하세요")
        }
        if service.getAdminEmail().isEmpty || service.getTeacherEmail().isEmpty {
            print("  - Firebase Console에서 Remote Config 값들을 설정하세요")
        }
        print("  - 네트워크 연결 상태를 확인하세요")
        print("  - Firebase 프로젝트 설정을 확인하세요\n")
    }
}

// MARK: - 확장 함수들

extension RemoteConfigService {
    /// 디버그 정보 출력
    public func printDebugInfo() {
        RemoteConfigDebugHelper.printConfigStatus(service: self)
    }
    
    /// 이메일 검증 테스트
    public func testEmailValidation(emails: [String]) {
        RemoteConfigDebugHelper.testEmailValidation(service: self, testEmails: emails)
    }
    
    /// 종합 진단 실행
    public func runDiagnosis() {
        RemoteConfigDebugHelper.runFullDiagnosis(service: self)
    }
}