import Foundation
import FirebaseFirestore

public struct Board: Identifiable, Codable {
    public let id: String
    public let title: String
    public let adminId: String
    public let teacherId: String?
    public let qrCode: String
    public var settings: BoardSettings
    public let createdAt: Date
    public var isActive: Bool
    
    // Computed properties for UI display
    public var name: String { title }
    public var description: String { "" } // Default empty, can be extended later
    
    public init(id: String = UUID().uuidString, title: String, adminId: String, teacherId: String? = nil, qrCode: String = UUID().uuidString, settings: BoardSettings = BoardSettings(), createdAt: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.title = title
        self.adminId = adminId
        self.teacherId = teacherId
        self.qrCode = qrCode
        self.settings = settings
        self.createdAt = createdAt
        self.isActive = isActive
    }
    
    // Convenience initializer with name and description for BoardCreation
    public init(id: String = UUID().uuidString, name: String, description: String, adminId: String, teacherId: String? = nil, qrCode: String = UUID().uuidString, settings: BoardSettings = BoardSettings(), createdAt: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.title = name
        self.adminId = adminId
        self.teacherId = teacherId
        self.qrCode = qrCode
        self.settings = settings
        self.createdAt = createdAt
        self.isActive = isActive
    }
}

// MARK: - Board with Statistics
public struct BoardWithStats: Identifiable {
    public let board: Board
    public let studentCount: Int
    public let photoCount: Int
    public let teacherName: String?
    
    public init(board: Board, studentCount: Int, photoCount: Int, teacherName: String? = nil) {
        self.board = board
        self.studentCount = studentCount
        self.photoCount = photoCount
        self.teacherName = teacherName
    }
    
    // Convenience properties
    public var id: String { board.id }
    public var title: String { board.title }
    public var name: String { board.name }
    public var description: String { board.description }
    public var adminId: String { board.adminId }
    public var teacherId: String? { board.teacherId }
    public var qrCode: String { board.qrCode }
    public var settings: BoardSettings { board.settings }
    public var createdAt: Date { board.createdAt }
    public var isActive: Bool { board.isActive }
}

// MARK: - Validation
extension Board {
    /// 게시판 데이터의 유효성을 검증합니다
    func validate() throws {
        try validateTitle()
        try validateAdminId()
        try validateQRCode()
        try validateId()
        try settings.validate()
    }
    
    /// 제목 유효성 검증
    private func validateTitle() throws {
        let validations = [
            ValidationUtils.validateNotEmpty(title, error: .invalidBoardTitle),
            ValidationUtils.validateLength(title, min: 1, max: 100, error: .invalidBoardTitle)
        ]
        
        let result = ValidationUtils.combineValidations(validations)
        if case .invalid(let error) = result {
            throw error
        }
    }
    
    /// 관리자 ID 유효성 검증
    private func validateAdminId() throws {
        guard !adminId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// QR 코드 유효성 검증
    private func validateQRCode() throws {
        guard !qrCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// ID 유효성 검증
    private func validateId() throws {
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
    }
    
    /// 새로운 게시판 생성 시 유효성 검증
    static func validateForCreation(title: String, adminId: String, teacherId: String? = nil, settings: BoardSettings) throws {
        let tempBoard = Board(title: title, adminId: adminId, teacherId: teacherId, settings: settings)
        try tempBoard.validate()
    }
}

public struct BoardSettings: Codable {
    public var backgroundImage: BackgroundImage
    public var theme: Theme
    public var fontFamily: FontFamily
    public var newPostPosition: NewPostPosition
    
    public init(backgroundImage: BackgroundImage = .pastelBlue, theme: Theme = .light, fontFamily: FontFamily = .systemDefault, newPostPosition: NewPostPosition = .topLeft) {
        self.backgroundImage = backgroundImage
        self.theme = theme
        self.fontFamily = fontFamily
        self.newPostPosition = newPostPosition
    }
    
    // MARK: - Nested Enums
    
    public enum BackgroundImage: String, CaseIterable, Codable {
        case pastelPink = "pastelPink"
        case pastelBlue = "pastelBlue"
        case pastelGreen = "pastelGreen"
        case pastelYellow = "pastelYellow"
        case pastelPurple = "pastelPurple"
        case pastelOrange = "pastelOrange"
        
        public var displayName: String {
            switch self {
            case .pastelPink: return "로즈"
            case .pastelBlue: return "스카이"
            case .pastelGreen: return "민트"
            case .pastelYellow: return "레몬"
            case .pastelPurple: return "라벤더"
            case .pastelOrange: return "피치"
            }
        }
    }
    
    public enum Theme: String, CaseIterable, Codable {
        case light = "light"
        case dark = "dark"
        
        public var displayName: String {
            switch self {
            case .light: return "라이트"
            case .dark: return "다크"
            }
        }
    }
    
    public enum FontFamily: String, CaseIterable, Codable {
        case systemDefault = "system"
        case nanumGothic = "nanum"
        case appleSdGothic = "apple"
        
        public var displayName: String {
            switch self {
            case .systemDefault: return "기본"
            case .nanumGothic: return "나눔고딕"
            case .appleSdGothic: return "애플SD고딕"
            }
        }
    }
    
    public enum NewPostPosition: String, CaseIterable, Codable {
        case topLeft = "topLeft"
        case topRight = "topRight"
        case center = "center"
        
        public var displayName: String {
            switch self {
            case .topLeft: return "왼쪽 위"
            case .topRight: return "오른쪽 위"
            case .center: return "가운데"
            }
        }
    }
}

// MARK: - Firestore Serialization
extension Board {
    /// Board를 Firestore에 저장하기 위한 Dictionary로 변환
    func toFirestoreDictionary() -> [String: Any] {
        return [
            "id": id,
            "title": title,
            "adminId": adminId,
            "teacherId": teacherId as Any,
            "qrCode": qrCode,
            "settings": [
                "backgroundImage": settings.backgroundImage.rawValue,
                "theme": settings.theme.rawValue,
                "fontFamily": settings.fontFamily.rawValue,
                "newPostPosition": settings.newPostPosition.rawValue
            ],
            "createdAt": Timestamp(date: createdAt),
            "isActive": isActive
        ]
    }
    
    /// Firestore Dictionary에서 Board 객체로 변환
    static func fromFirestoreDictionary(_ dictionary: [String: Any]) throws -> Board {
        guard let id = dictionary["id"] as? String,
              let title = dictionary["title"] as? String,
              let adminId = dictionary["adminId"] as? String,
              let qrCode = dictionary["qrCode"] as? String,
              let settingsDict = dictionary["settings"] as? [String: Any],
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let isActive = dictionary["isActive"] as? Bool else {
            throw WallyError.dataCorruption
        }
        
        let teacherId = dictionary["teacherId"] as? String
        
        // BoardSettings 파싱
        let backgroundImage = BoardSettings.BackgroundImage(rawValue: settingsDict["backgroundImage"] as? String ?? "pastelBlue") ?? .pastelBlue
        let theme = BoardSettings.Theme(rawValue: settingsDict["theme"] as? String ?? "light") ?? .light
        let fontFamily = BoardSettings.FontFamily(rawValue: settingsDict["fontFamily"] as? String ?? "systemDefault") ?? .systemDefault
        let newPostPosition = BoardSettings.NewPostPosition(rawValue: settingsDict["newPostPosition"] as? String ?? "topLeft") ?? .topLeft
        
        let settings = BoardSettings(
            backgroundImage: backgroundImage,
            theme: theme,
            fontFamily: fontFamily,
            newPostPosition: newPostPosition
        )
        
        return Board(
            id: id,
            title: title,
            adminId: adminId,
            teacherId: teacherId,
            qrCode: qrCode,
            settings: settings,
            createdAt: createdAtTimestamp.dateValue(),
            isActive: isActive
        )
    }
}

// MARK: - BoardSettings Validation
extension BoardSettings {
    /// 게시판 설정의 유효성을 검증합니다
    func validate() throws {
        // 열거형 값들은 자동으로 유효하므로 추가 검증 불필요
        // 필요시 여기에 추가 비즈니스 로직 검증 추가
    }
}

