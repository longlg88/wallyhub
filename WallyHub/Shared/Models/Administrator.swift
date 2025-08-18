import Foundation

public struct Administrator: Identifiable, Codable {
    public let id: String
    public let username: String
    public let email: String?
    public var boards: [String] // Board IDs
    
    public init(id: String = UUID().uuidString, username: String, email: String? = nil, boards: [String] = []) {
        self.id = id
        self.username = username
        self.email = email
        self.boards = boards
    }
}

// MARK: - Validation
extension Administrator {
    /// 관리자 데이터의 유효성을 검증합니다
    public func validate() throws {
        try validateUsername()
        try validateEmail()
        try validateId()
    }
    
    /// 사용자명 유효성 검증
    private func validateUsername() throws {
        let validations = [
            ValidationUtils.validateNotEmpty(username, error: .invalidUsername),
            ValidationUtils.validateLength(username, min: 3, max: 50, error: .invalidUsername),
            ValidationUtils.validatePattern(username, pattern: "^[a-zA-Z0-9_]+$", error: .invalidUsername)
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
    
    /// 새로운 관리자 생성 시 유효성 검증
    public static func validateForCreation(username: String, email: String?) throws {
        let tempAdmin = Administrator(username: username, email: email)
        try tempAdmin.validate()
    }
}