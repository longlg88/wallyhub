import Foundation

public struct Teacher: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var email: String
    public let boardId: String
    public let createdAt: Date
    public var isActive: Bool
    public var realBoardCount: Int? // 실제 게시판 수 저장
    
    public init(id: String = UUID().uuidString, name: String, email: String, boardId: String, createdAt: Date = Date(), isActive: Bool = true, realBoardCount: Int? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.boardId = boardId
        self.createdAt = createdAt
        self.isActive = isActive
        self.realBoardCount = realBoardCount
    }
}

// MARK: - Validation
extension Teacher {
    /// 교사 데이터의 유효성을 검증합니다
    func validate() throws {
        try validateName()
        try validateEmail()
        try validateBoardId()
        try validateId()
    }
    
    /// 이름 유효성 검증
    private func validateName() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let validations = [
            ValidationUtils.validateNotEmpty(name, error: .invalidTeacherName),
            ValidationUtils.validateLength(name, min: 1, max: 50, error: .invalidTeacherName),
            ValidationUtils.validatePattern(trimmedName, pattern: "^[가-힣a-zA-Z\\s]+$", error: .invalidTeacherName)
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 이메일 유효성 검증
    private func validateEmail() throws {
        let emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let validations = [
            ValidationUtils.validateNotEmpty(email, error: .invalidEmail),
            ValidationUtils.validatePattern(email, pattern: emailPattern, error: .invalidEmail)
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 게시판 ID 유효성 검증
    private func validateBoardId() throws {
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// ID 유효성 검증
    private func validateId() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 새로운 교사 등록 시 유효성 검증
    static func validateForRegistration(name: String, email: String, boardId: String) throws {
        let tempTeacher = Teacher(name: name, email: email, boardId: boardId)
        try tempTeacher.validate()
    }
    
    /// 교사 정보 업데이트 시 유효성 검증
    func validateForUpdate(newName: String, newEmail: String) throws {
        var updatedTeacher = self
        updatedTeacher.name = newName
        updatedTeacher.email = newEmail
        try updatedTeacher.validate()
    }
}

// MARK: - Computed Properties
extension Teacher {
    /// 교사가 관리하는 게시판 수 (실제 Firebase 데이터 우선 사용)
    public var boardCount: Int {
        // 실제 데이터가 있으면 사용, 없으면 0 반환
        return realBoardCount ?? 0
    }
}