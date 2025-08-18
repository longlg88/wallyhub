import Foundation

public struct Photo: Identifiable, Codable {
    public let id: String
    public let title: String
    public let studentId: String
    public let boardId: String
    public let imageUrl: String?
    public let uploadedAt: Date
    public var isVisible: Bool
    
    public init(id: String = UUID().uuidString, title: String = "", studentId: String, boardId: String, imageUrl: String? = nil, uploadedAt: Date = Date(), isVisible: Bool = true) {
        self.id = id
        self.title = title
        self.studentId = studentId
        self.boardId = boardId
        self.imageUrl = imageUrl
        self.uploadedAt = uploadedAt
        self.isVisible = isVisible
    }
}

// MARK: - Validation
extension Photo {
    /// 사진 데이터의 유효성을 검증합니다
    func validate() throws {
        try validateStudentId()
        try validateBoardId()
        try validateImageUrl()
        try validateId()
    }
    
    /// 학생 ID 유효성 검증
    private func validateStudentId() throws {
        guard !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 게시판 ID 유효성 검증
    private func validateBoardId() throws {
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 이미지 URL 유효성 검증
    private func validateImageUrl() throws {
        // imageUrl이 nil인 경우는 유효한 상태로 간주 (업로드 전 상태)
        guard let imageUrl = imageUrl else {
            return
        }
        
        // 기본 검증
        guard !imageUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidImageUrl
        }
        
        // URL 형식 검증
        guard URL(string: imageUrl) != nil else {
            throw WallyError.invalidImageUrl
        }
        
        // 이미지 URL인지 확인 (확장자 기반)
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic", "heif"]
        let lowercaseUrl = imageUrl.lowercased()
        let hasValidExtension = imageExtensions.contains { lowercaseUrl.hasSuffix(".\($0)") }
        
        // Firebase Storage URL 패턴도 허용
        let isFirebaseUrl = imageUrl.contains("firebasestorage.googleapis.com") || imageUrl.contains("storage.googleapis.com")
        
        guard hasValidExtension || isFirebaseUrl else {
            throw WallyError.invalidImageUrl
        }
    }
    
    /// ID 유효성 검증
    private func validateId() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 새로운 사진 업로드 시 유효성 검증
    static func validateForUpload(studentId: String, boardId: String, imageUrl: String?) throws {
        let tempPhoto = Photo(studentId: studentId, boardId: boardId, imageUrl: imageUrl)
        try tempPhoto.validate()
    }
    
    /// 사진 가시성 업데이트 시 유효성 검증
    func validateForVisibilityUpdate() throws {
        try validate()
    }
}