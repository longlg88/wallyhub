import Foundation

public struct Student: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var studentId: String
    public let boardId: String
    public let joinedAt: Date
    public let passwordHash: String?  // 해시된 비밀번호 (옵셔널)
    public let createdAt: Date
    
    public init(id: String = UUID().uuidString, name: String, studentId: String, boardId: String, joinedAt: Date = Date(), passwordHash: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.studentId = studentId
        self.boardId = boardId
        self.joinedAt = joinedAt
        self.passwordHash = passwordHash
        self.createdAt = createdAt
    }
}

// MARK: - Validation
extension Student {
    /// 학생 데이터의 유효성을 검증합니다
    func validate() throws {
        try validateName()
        try validateStudentId()
        try validateBoardId()
        try validateId()
    }
    
    /// 이름 유효성 검증
    private func validateName() throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let validations = [
            ValidationUtils.validateNotEmpty(name, error: .invalidStudentName),
            ValidationUtils.validateLength(name, min: 1, max: 50, error: .invalidStudentName),
            ValidationUtils.validatePattern(trimmedName, pattern: "^[가-힣a-zA-Z\\s]+$", error: .invalidStudentName)
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 학번 유효성 검증
    private func validateStudentId() throws {
        let validations = [
            ValidationUtils.validateNotEmpty(studentId, error: .invalidStudentId),
            ValidationUtils.validateLength(studentId, min: 1, max: 128, error: .invalidStudentId),
            ValidationUtils.validatePattern(studentId, pattern: "^[a-zA-Z0-9._-]+$", error: .invalidStudentId)
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 게시판 ID 유효성 검증
    private func validateBoardId() throws {
        // boardId는 빈 문자열도 허용 (아직 게시판에 참여하지 않은 학생)
        // 특별한 검증 없이 통과
    }
    
    /// ID 유효성 검증
    private func validateId() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 새로운 학생 등록 시 유효성 검증
    static func validateForRegistration(name: String, studentId: String, boardId: String) throws {
        let tempStudent = Student(name: name, studentId: studentId, boardId: boardId)
        try tempStudent.validate()
    }
    
    /// 학생 정보 업데이트 시 유효성 검증
    func validateForUpdate(newName: String, newStudentId: String) throws {
        var updatedStudent = self
        updatedStudent.name = newName
        updatedStudent.studentId = newStudentId
        try updatedStudent.validate()
    }
}

// MARK: - Real-time Data Properties
extension Student {
    /// 학생이 업로드한 사진 수 (Firebase에서 실시간 조회)
    /// - Parameter completion: 사진 개수를 비동기로 반환하는 클로저
    public func getPhotoCount() async -> Int {
        // StudentService를 통해 실제 Firebase 데이터 조회
        do {
            let photos = try await ServiceFactory.shared.studentService.getStudentPhotos(
                boardId: self.boardId,
                studentId: self.id  // UUID 형식의 document ID 사용
            )
            return photos.count
        } catch {
            print("❌ Student.getPhotoCount 오류: \(error)")
            return 0
        }
    }
    
    /// 학생의 마지막 활동 날짜 (Firebase에서 실시간 조회)
    /// - Returns: 가장 최근 사진 업로드 날짜, 없으면 가입일 반환
    public func getLastActivityDate() async -> Date {
        do {
            let photos = try await ServiceFactory.shared.studentService.getStudentPhotos(
                boardId: self.boardId,
                studentId: self.id  // UUID 형식의 document ID 사용
            )
            
            // 가장 최근 사진의 업로드 날짜 반환
            if let mostRecentPhoto = photos.max(by: { $0.uploadedAt < $1.uploadedAt }) {
                return mostRecentPhoto.uploadedAt
            } else {
                // 사진이 없으면 가입일 반환
                return self.joinedAt
            }
        } catch {
            print("❌ Student.getLastActivityDate 오류: \(error)")
            return self.joinedAt
        }
    }
    
    /// 동기적 접근을 위한 임시 속성 (UI에서 바로 사용 가능)
    /// 실제로는 비동기 메서드를 호출하여 업데이트해야 함
    public var photoCount: Int {
        return 0 // 기본값, UI에서 Task로 실제 값을 로드해야 함
    }
    
    /// 동기적 접근을 위한 임시 속성 (UI에서 바로 사용 가능) 
    /// 실제로는 비동기 메서드를 호출하여 업데이트해야 함
    public var lastActivityDate: Date {
        return joinedAt // 기본값, UI에서 Task로 실제 값을 로드해야 함
    }
}