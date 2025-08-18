import Foundation

/// 사용자 역할을 정의하는 열거형
public enum UserRole: String, CaseIterable, Codable {
    case administrator = "admin"  // Firestore에서 "admin" 사용
    case teacher = "teacher"
    case student = "student"
    
    /// 역할의 한국어 표시명
    public var displayName: String {
        switch self {
        case .administrator:
            return "관리자"
        case .teacher:
            return "교사"
        case .student:
            return "학생"
        }
    }
    
    /// 역할의 설명
    public var description: String {
        switch self {
        case .administrator:
            return "시스템 전체를 관리하고 모든 게시판에 접근할 수 있습니다"
        case .teacher:
            return "게시판을 생성하고 관리할 수 있습니다"
        case .student:
            return "QR 코드를 통해 게시판에 참여하고 사진을 공유할 수 있습니다"
        }
    }
    
    /// 역할별 권한 확인
    public var canCreateBoards: Bool {
        switch self {
        case .administrator, .teacher:
            return true
        case .student:
            return false
        }
    }
    
    public var canManageAllBoards: Bool {
        switch self {
        case .administrator:
            return true
        case .teacher, .student:
            return false
        }
    }
    
    public var canModerateContent: Bool {
        switch self {
        case .administrator, .teacher:
            return true
        case .student:
            return false
        }
    }
    
    /// 이메일 주소를 기반으로 역할을 자동 판별
    public static func detectRole(from email: String) -> UserRole {
        let lowercaseEmail = email.lowercased()
        
        // 관리자 패턴 검사 (키워드만 사용, 하드코딩된 도메인 제거)
        if lowercaseEmail.contains("admin") || 
           lowercaseEmail.hasPrefix("admin@") ||
           lowercaseEmail.contains("administrator") {
            return .administrator
        }
        
        // 학생 패턴 검사 (키워드만 사용, 하드코딩된 도메인 제거)
        if lowercaseEmail.contains("student") ||
           lowercaseEmail.hasPrefix("std") ||
           lowercaseEmail.contains("std") {
            return .student
        }
        
        // 교사 패턴 검사 (키워드만 사용, 하드코딩된 도메인 제거)
        if lowercaseEmail.contains("teacher") ||
           lowercaseEmail.contains("prof") ||
           lowercaseEmail.contains("instructor") {
            return .teacher
        }
        
        // 기본적으로 교사로 설정 (게시판 생성 가능)
        return .teacher
    }
    
    /// 사용자명을 기반으로 역할을 자동 판별
    public static func detectRole(from username: String, email: String? = nil) -> UserRole {
        let lowercaseUsername = username.lowercased()
        
        // 이메일이 있으면 이메일 기반 판별 우선
        if let email = email {
            return detectRole(from: email)
        }
        
        // 사용자명 패턴 검사
        if lowercaseUsername.contains("admin") ||
           lowercaseUsername == "administrator" ||
           lowercaseUsername.hasPrefix("admin") {
            return .administrator
        }
        
        if lowercaseUsername.contains("teacher") ||
           lowercaseUsername.contains("prof") ||
           lowercaseUsername.contains("instructor") {
            return .teacher
        }
        
        if lowercaseUsername.contains("student") ||
           lowercaseUsername.hasPrefix("std") ||
           lowercaseUsername.contains("std") {
            return .student
        }
        
        // 기본적으로 교사로 설정
        return .teacher
    }
}

/// 사용자 정보를 통합하는 프로토콜
public protocol WallyUser {
    var id: String { get }
    var role: UserRole { get }
    var displayName: String { get }
    var email: String? { get }
}

/// 통합 사용자 구조체
public struct User: WallyUser, Identifiable, Codable, Equatable {
    public let id: String
    public let role: UserRole
    public let username: String
    public let email: String?
    public var boards: [String] // Board IDs (관리자/교사용)
    
    public var displayName: String {
        return username
    }
    
    public init(id: String = UUID().uuidString, 
                role: UserRole, 
                username: String, 
                email: String? = nil, 
                boards: [String] = []) {
        self.id = id
        self.role = role
        self.username = username
        self.email = email
        self.boards = boards
    }
    
    /// Administrator에서 User로 변환
    public init(from administrator: Administrator) {
        self.id = administrator.id
        self.role = UserRole.detectRole(from: administrator.username, email: administrator.email)
        self.username = administrator.username
        self.email = administrator.email
        self.boards = administrator.boards
    }
    
    /// Administrator로 변환
    public func toAdministrator() -> Administrator {
        return Administrator(
            id: id,
            username: username,
            email: email,
            boards: boards
        )
    }
}

// MARK: - Validation
extension User {
    /// 사용자 데이터의 유효성을 검증합니다
    public func validate() throws {
        try validateUsername()
        try validateEmail()
        try validateId()
    }
    
    /// 사용자명 유효성 검증
    private func validateUsername() throws {
        let validations = [
            ValidationUtils.validateNotEmpty(username, error: .invalidUsername),
            ValidationUtils.validateLength(username, min: 1, max: 50, error: .invalidUsername)
            // 한글, 영문, 숫자, 언더스코어 모두 허용하도록 패턴 검증 제거
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 이메일 유효성 검증
    private func validateEmail() throws {
        guard let email = email, !email.isEmpty else {
            return // 이메일은 선택사항
        }
        
        let result = ValidationUtils.validatePattern(email, pattern: "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$", error: .invalidEmail)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// ID 유효성 검증
    private func validateId() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
}