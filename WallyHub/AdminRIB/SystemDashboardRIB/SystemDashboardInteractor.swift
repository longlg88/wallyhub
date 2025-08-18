import RIBs
import Foundation
import SwiftUI

// MARK: - Business Logic Protocols

protocol SystemDashboardListener: AnyObject {
    func systemDashboardDidComplete()
    func systemDashboardDidRequestAllBoardsManagement()
    func systemDashboardDidRequestUserManagement()
}

protocol SystemDashboardPresentableListener: AnyObject {
    func viewDidLoad()
    func didTapClose()
    func didTapRefresh()
    func didTapExportData()
    func didTapSystemSettings()
}

protocol SystemDashboardInteractable: Interactable {
    var router: SystemDashboardRouting? { get set }
    var listener: SystemDashboardListener? { get set }
}

protocol SystemDashboardPresentable: Presentable {
    var listener: SystemDashboardPresentableListener? { get set }
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
    func updateMetrics(_ metrics: SystemDashboardMetrics)
}

struct SystemDashboardMetrics {
    let totalUsers: Int
    let totalTeachers: Int
    let totalStudents: Int
    let totalBoards: Int
    let activeBoards: Int
    let totalPhotos: Int
    let photosToday: Int
    let lastDataSync: String
    let databaseSize: String
    let dailyActiveUsers: Int
    let weeklyActiveUsers: Int
    let monthlyActiveUsers: Int
    let serverCpuUsage: Double
    let serverMemoryUsage: Double
    let serverDiskUsage: Double
    let recentActivities: [SystemActivity]
}

struct SystemActivity {
    let id: String
    let type: ActivityType
    let description: String
    let timestamp: Date
    let userInfo: String?
    
    enum ActivityType {
        case userLogin
        case boardCreated
        case photoUploaded
        case systemMaintenance
        case errorOccurred
        case studentRegistered
        case teacherSignUp
        
        var icon: String {
            switch self {
            case .userLogin: return "person.circle"
            case .boardCreated: return "plus.rectangle"
            case .photoUploaded: return "photo"
            case .systemMaintenance: return "gear"
            case .errorOccurred: return "exclamationmark.triangle"
            case .studentRegistered: return "person.badge.plus"
            case .teacherSignUp: return "person.badge.shield.checkmark"
            }
        }
        
        var color: Color {
            switch self {
            case .userLogin: return .green
            case .boardCreated: return .blue
            case .photoUploaded: return .orange
            case .systemMaintenance: return .gray
            case .errorOccurred: return .red
            case .studentRegistered: return .mint
            case .teacherSignUp: return .purple
            }
        }
    }
}

final class SystemDashboardInteractor: PresentableInteractor<SystemDashboardPresentable>, SystemDashboardInteractable, SystemDashboardPresentableListener {
    weak var router: SystemDashboardRouting?
    weak var listener: SystemDashboardListener?
    
    private let boardService: BoardService
    private let studentService: StudentService
    private let authenticationService: AuthenticationService
    private let photoService: PhotoService
    
    // 비동기 작업 추적용
    private var loadingTask: Task<Void, Never>?

    init(presenter: SystemDashboardPresentable,
         boardService: BoardService,
         studentService: StudentService,
         authenticationService: AuthenticationService,
         photoService: PhotoService) {
        self.boardService = boardService
        self.studentService = studentService
        self.authenticationService = authenticationService
        self.photoService = photoService
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    deinit {
        print("🗑️ SystemDashboardInteractor deinit - 메모리 해제")
        loadingTask?.cancel()
    }
    
    override func willResignActive() {
        super.willResignActive()
        print("🔄 SystemDashboardInteractor willResignActive - 리소스 정리")
        // Firebase listeners나 기타 구독 정리
        loadingTask?.cancel()
        loadingTask = nil
        
        // RIBs 참조 정리
        router = nil
        listener = nil
    }
    
    func viewDidLoad() {
        loadSystemMetrics()
    }
    
    func didTapClose() {
        listener?.systemDashboardDidComplete()
    }
    
    func didTapRefresh() {
        loadSystemMetrics()
    }
    
    private func loadSystemMetrics() {
        presenter.showLoading()
        
        // 기존 작업이 있으면 취소
        loadingTask?.cancel()
        
        loadingTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                // 병렬로 모든 데이터 로드
                async let boardsData = loadBoardsData()
                async let studentsData = loadStudentsData()
                async let photosData = loadPhotosData()
                
                let (boards, students, photos) = await (
                    try boardsData,
                    try studentsData, 
                    try photosData
                )
                
                // 교사 수 계산 (각 게시판의 고유한 adminId 개수)
                let teacherCount = calculateTeacherCount(boards)
                
                // 시스템 메트릭 계산
                let metrics = SystemDashboardMetrics(
                    totalUsers: students.count + teacherCount, // 학생 + 교사
                    totalTeachers: teacherCount,
                    totalStudents: students.count,
                    totalBoards: boards.count,
                    activeBoards: boards.filter { $0.isActive }.count,
                    totalPhotos: photos.count,
                    photosToday: calculatePhotosToday(photos),
                    lastDataSync: calculateLastDataSync(),
                    databaseSize: calculateDatabaseSize(boards: boards, students: students, photos: photos),
                    dailyActiveUsers: calculateDailyActiveUsers(students),
                    weeklyActiveUsers: calculateWeeklyActiveUsers(students),
                    monthlyActiveUsers: calculateMonthlyActiveUsers(students),
                    serverCpuUsage: calculateFirebaseActivity(boards: boards, students: students), 
                    serverMemoryUsage: calculateDataDistribution(boards: boards, photos: photos),
                    serverDiskUsage: calculateStorageUsage(photos: photos),
                    recentActivities: await generateRecentActivities(boards: boards, photos: photos)
                )
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.updateMetrics(metrics)
                }
                
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showError(error.localizedDescription)
                }
            }
        }
    }
    
    private func loadBoardsData() async throws -> [Board] {
        return try await boardService.getAllBoards()
    }
    
    private func loadStudentsData() async throws -> [Student] {
        // 모든 학생 데이터를 가져오기
        return try await studentService.getAllStudents()
    }
    
    private func loadPhotosData() async throws -> [Photo] {
        return try await photoService.getAllPhotos()
    }
    
    private func calculatePhotosToday(_ photos: [Photo]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return photos.filter { Calendar.current.isDate($0.uploadedAt, inSameDayAs: today) }.count
    }
    
    private func calculateTeacherCount(_ boards: [Board]) -> Int {
        // 고유한 adminId들을 Set으로 추출하여 교사 수 계산
        let uniqueAdminIds = Set(boards.map { $0.adminId })
        return uniqueAdminIds.count
    }
    
    private func calculateFirebaseActivity(boards: [Board], students: [Student]) -> Double {
        // Firebase 활성도 = (활성 게시판 수 / 전체 게시판 수) * 100
        guard !boards.isEmpty else { return 0.0 }
        let activeBoards = boards.filter { $0.isActive }.count
        return Double(activeBoards) / Double(boards.count) * 100.0
    }
    
    private func calculateDataDistribution(boards: [Board], photos: [Photo]) -> Double {
        // 데이터 분산도 = 평균 게시판당 사진 수 대비 현재 분산 비율
        guard !boards.isEmpty else { return 0.0 }
        
        // 각 게시판별 사진 수 계산
        let photosPerBoard = Dictionary(grouping: photos) { $0.boardId }
        let photoCounts = boards.map { board in
            photosPerBoard[board.id]?.count ?? 0
        }
        
        guard !photoCounts.isEmpty else { return 0.0 }
        
        let averagePhotos = Double(photos.count) / Double(boards.count)
        let variance = photoCounts.map { count in
            pow(Double(count) - averagePhotos, 2)
        }.reduce(0, +) / Double(photoCounts.count)
        
        // 분산을 0-100% 범위로 정규화
        return min(sqrt(variance) / averagePhotos * 100.0, 100.0)
    }
    
    private func calculateStorageUsage(photos: [Photo]) -> Double {
        // 스토리지 사용률 추정 = (사진 수 / 예상 최대 사진 수) * 100
        let maxExpectedPhotos = 10000.0 // 예상 최대 사진 수
        return min(Double(photos.count) / maxExpectedPhotos * 100.0, 100.0)
    }
    
    private func calculateDatabaseSize(boards: [Board], students: [Student], photos: [Photo]) -> String {
        // Firebase Firestore 문서 크기 추정
        let avgBoardSize = 2.0 // KB per board document  
        let avgStudentSize = 1.5 // KB per student document
        let avgPhotoSize = 1.0 // KB per photo document (메타데이터만, 실제 이미지는 Storage)
        
        let totalSizeKB = Double(boards.count) * avgBoardSize +
                         Double(students.count) * avgStudentSize + 
                         Double(photos.count) * avgPhotoSize
        
        // 적절한 단위로 변환
        if totalSizeKB < 1024 {
            return String(format: "%.1f KB", totalSizeKB)
        } else if totalSizeKB < 1024 * 1024 {
            return String(format: "%.1f MB", totalSizeKB / 1024)
        } else {
            return String(format: "%.1f GB", totalSizeKB / (1024 * 1024))
        }
    }
    
    private func calculateLastDataSync() -> String {
        // 현재 시간을 마지막 데이터 동기화 시간으로 표시
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: Date())
    }
    
    private func calculateDailyActiveUsers(_ students: [Student]) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        return students.filter { Calendar.current.isDate($0.joinedAt, inSameDayAs: today) }.count
    }
    
    private func calculateWeeklyActiveUsers(_ students: [Student]) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
        return students.filter { $0.joinedAt >= weekAgo }.count
    }
    
    private func calculateMonthlyActiveUsers(_ students: [Student]) -> Int {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        return students.filter { $0.joinedAt >= monthAgo }.count
    }
    
    private func generateRecentActivities(boards: [Board], photos: [Photo]) async -> [SystemActivity] {
        var activities: [SystemActivity] = []
        
        // 1. 최근 생성된 보드들
        let recentBoards = boards.sorted { $0.createdAt > $1.createdAt }.prefix(3)
        for board in recentBoards {
            activities.append(SystemActivity(
                id: "board_\(board.id)",
                type: .boardCreated,
                description: "새 게시판 '\(board.name)' 이(가) 생성되었습니다",
                timestamp: board.createdAt,
                userInfo: board.adminId
            ))
        }
        
        // 2. 최근 업로드된 사진들
        let recentPhotos = photos.sorted { $0.uploadedAt > $1.uploadedAt }.prefix(5)
        for photo in recentPhotos {
            activities.append(SystemActivity(
                id: "photo_\(photo.id)",
                type: .photoUploaded,
                description: "새 사진이 업로드되었습니다",
                timestamp: photo.uploadedAt,
                userInfo: photo.studentId
            ))
        }
        
        // 3. 인증 활동 통합
        do {
            let authActivities = try await authenticationService.getRecentAuthActivities()
            for authActivity in authActivities.prefix(5) {
                let activityType: SystemActivity.ActivityType
                switch authActivity.type {
                case .userSignUp, .teacherLogin, .adminLogin:
                    activityType = .teacherSignUp
                case .studentLogin:
                    activityType = .userLogin
                default:
                    activityType = .userLogin
                }
                
                activities.append(SystemActivity(
                    id: "auth_\(authActivity.id)",
                    type: activityType,
                    description: authActivity.description,
                    timestamp: authActivity.timestamp,
                    userInfo: authActivity.username
                ))
            }
        } catch {
            print("⚠️ 인증 활동 로드 실패: \(error)")
            // 오류 활동으로 추가
            activities.append(SystemActivity(
                id: "error_auth_\(UUID().uuidString)",
                type: .errorOccurred,
                description: "인증 활동 로드 중 오류 발생",
                timestamp: Date(),
                userInfo: nil
            ))
        }
        
        // 4. 학생 활동 통합
        do {
            let studentActivities = try await studentService.getRecentStudentActivities()
            for studentActivity in studentActivities.prefix(5) {
                let activityType: SystemActivity.ActivityType
                switch studentActivity.type {
                case .studentRegistered, .studentJoinedBoard:
                    activityType = .studentRegistered
                case .studentLogin:
                    activityType = .userLogin
                case .photoUploaded:
                    activityType = .photoUploaded
                }
                
                activities.append(SystemActivity(
                    id: "student_\(studentActivity.id)",
                    type: activityType,
                    description: studentActivity.description,
                    timestamp: studentActivity.timestamp,
                    userInfo: studentActivity.studentName
                ))
            }
        } catch {
            print("⚠️ 학생 활동 로드 실패: \(error)")
            // 오류 활동으로 추가
            activities.append(SystemActivity(
                id: "error_student_\(UUID().uuidString)",
                type: .errorOccurred,
                description: "학생 활동 로드 중 오류 발생",
                timestamp: Date(),
                userInfo: nil
            ))
        }
        
        // 5. 시간순 정렬하여 최신 15개 활동 반환
        return activities.sorted { $0.timestamp > $1.timestamp }.prefix(15).map { $0 }
    }
    
    func didTapExportData() {
        // Export system data
        // TODO: Implement data export functionality
    }
    
    func didTapSystemSettings() {
        // Navigate to system settings
        // TODO: Implement system settings navigation
    }
}