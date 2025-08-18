import Foundation

// MARK: - Photo View Tracking Models

/// 사진 조회 기록을 추적하는 모델
public struct PhotoViewRecord: Identifiable, Codable {
    public let id: String
    public let photoId: String
    public let teacherId: String
    public let boardId: String
    public let viewedAt: Date
    public let sessionDuration: TimeInterval?
    public let deviceInfo: String?
    
    public init(
        id: String = UUID().uuidString,
        photoId: String,
        teacherId: String,
        boardId: String,
        viewedAt: Date = Date(),
        sessionDuration: TimeInterval? = nil,
        deviceInfo: String? = nil
    ) {
        self.id = id
        self.photoId = photoId
        self.teacherId = teacherId
        self.boardId = boardId
        self.viewedAt = viewedAt
        self.sessionDuration = sessionDuration
        self.deviceInfo = deviceInfo
    }
}

/// 사진의 전체 조회 상태 정보
public struct PhotoViewStatus: Codable {
    public let photoId: String
    public let totalViews: Int
    public let uniqueViewers: Int
    public let lastViewedAt: Date?
    public let lastViewedBy: String?
    public let isViewed: Bool
    public let viewRecords: [PhotoViewRecord]
    
    public init(
        photoId: String,
        totalViews: Int = 0,
        uniqueViewers: Int = 0,
        lastViewedAt: Date? = nil,
        lastViewedBy: String? = nil,
        isViewed: Bool = false,
        viewRecords: [PhotoViewRecord] = []
    ) {
        self.photoId = photoId
        self.totalViews = totalViews
        self.uniqueViewers = uniqueViewers
        self.lastViewedAt = lastViewedAt
        self.lastViewedBy = lastViewedBy
        self.isViewed = isViewed
        self.viewRecords = viewRecords
    }
}

/// 교사별 사진 조회 통계
public struct TeacherViewStats: Codable {
    public let teacherId: String
    public let totalPhotosViewed: Int
    public let todayPhotosViewed: Int
    public let averageViewTime: TimeInterval
    public let lastActiveDate: Date?
    public let boardsActivity: [String: Int] // boardId -> viewCount
    
    public init(
        teacherId: String,
        totalPhotosViewed: Int = 0,
        todayPhotosViewed: Int = 0,
        averageViewTime: TimeInterval = 0,
        lastActiveDate: Date? = nil,
        boardsActivity: [String: Int] = [:]
    ) {
        self.teacherId = teacherId
        self.totalPhotosViewed = totalPhotosViewed
        self.todayPhotosViewed = todayPhotosViewed
        self.averageViewTime = averageViewTime
        self.lastActiveDate = lastActiveDate
        self.boardsActivity = boardsActivity
    }
}

/// UI에서 사용할 사진 표시 상태
public enum PhotoDisplayStatus {
    case unviewed           // 미확인 - 파란색 표시
    case viewed             // 확인됨 - 회색 처리
    
    public var displayColor: String {
        switch self {
        case .unviewed: return "blue"
        case .viewed: return "gray"
        }
    }
    
    public var iconName: String {
        switch self {
        case .unviewed: return "circle.fill"
        case .viewed: return "checkmark.circle.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .unviewed: return "미확인"
        case .viewed: return "확인"
        }
    }
}

// MARK: - Extensions for Photo Integration

extension Photo {
    /// 현재 사진의 표시 상태를 계산 (조회 기록 기반)
    public func displayStatus(with viewStatus: PhotoViewStatus?) -> PhotoDisplayStatus {
        guard let viewStatus = viewStatus else {
            return .unviewed
        }
        
        return viewStatus.isViewed ? .viewed : .unviewed
    }
    
    /// 조회 상태 요약 텍스트
    public func viewSummaryText(with viewStatus: PhotoViewStatus?) -> String {
        guard let viewStatus = viewStatus else {
            return "미확인"
        }
        
        if !viewStatus.isViewed {
            return "미확인"
        }
        
        guard let lastViewed = viewStatus.lastViewedAt else {
            return "확인"
        }
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "\(formatter.string(from: lastViewed))에 확인"
    }
}

// MARK: - Validation Extensions

extension PhotoViewRecord {
    /// 조회 기록의 유효성 검증
    func validate() throws {
        guard !photoId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        guard !teacherId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        // 세션 시간이 비정상적으로 길면 오류
        if let duration = sessionDuration, duration > 3600 { // 1시간 초과
            throw WallyError.invalidInput
        }
    }
}