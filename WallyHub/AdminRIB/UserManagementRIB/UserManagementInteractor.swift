import RIBs
import Foundation

// MARK: - Business Logic Protocols

protocol UserManagementListener: AnyObject {
    func userManagementDidComplete()
}

protocol UserManagementPresentableListener: AnyObject {
    func viewDidLoad()
    func didTapClose()
    func didTapRefresh()
    func didTapCreateTeacher()
    func didTapTeacher(_ teacher: Teacher)
    func didTapStudent(_ student: Student)
    func didTapTeacherDetails(_ teacher: Teacher)
    func didTapStudentDetails(_ student: Student)
    func didTapDeleteTeacher(_ teacher: Teacher)
    func didTapDeleteStudent(_ student: Student)
}

protocol UserManagementInteractable: Interactable {
    var router: UserManagementRouting? { get set }
    var listener: UserManagementListener? { get set }
}

protocol UserManagementPresentable: Presentable {
    var listener: UserManagementPresentableListener? { get set }
    func showTeachers(_ teachers: [Teacher])
    func showStudents(_ students: [Student])
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
}

final class UserManagementInteractor: PresentableInteractor<UserManagementPresentable>, UserManagementInteractable, UserManagementPresentableListener {
    weak var router: UserManagementRouting?
    weak var listener: UserManagementListener?
    
    private let authenticationService: AuthenticationService
    private let studentService: StudentService
    private let boardService: BoardService

    init(presenter: UserManagementPresentable, 
         authenticationService: AuthenticationService,
         studentService: StudentService,
         boardService: BoardService) {
        self.authenticationService = authenticationService
        self.studentService = studentService
        self.boardService = boardService
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    func viewDidLoad() {
        loadUserData()
    }
    
    private func loadUserData() {
        presenter.showLoading()
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // 모든 사용자 데이터 로드
                let allUsers = try await self.authenticationService.getAllUsers()
                let allStudents = try await self.studentService.getAllStudents()
                
                // 교사/관리자 분류 (role이 administrator 또는 teacher인 사용자)
                var teachers: [Teacher] = []
                
                for user in allUsers {
                    // Admin은 전체 사용자에서 제외 (혼란 방지)
                    guard user.role == .teacher else { continue }
                    
                    // 실제 게시판 수 계산
                    let realBoardCount: Int
                    do {
                        let userBoards = try await self.boardService.getAdminBoards(adminId: user.id)
                        realBoardCount = userBoards.count
                        print("👤 \(user.username): 실제 게시판 \(realBoardCount)개")
                    } catch {
                        print("❌ \(user.username) 게시판 수 조회 실패: \(error)")
                        realBoardCount = 0
                    }
                    
                    // User를 Teacher로 변환 (실제 게시판 수 포함)
                    let teacher = Teacher(
                        id: user.id,
                        name: user.username,
                        email: user.email ?? "",
                        boardId: "",
                        createdAt: Date(),
                        realBoardCount: realBoardCount
                    )
                    teachers.append(teacher)
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showTeachers(teachers)
                    self.presenter.showStudents(allStudents)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showError("사용자 데이터를 불러오는데 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didTapClose() {
        listener?.userManagementDidComplete()
    }
    
    func didTapRefresh() {
        loadUserData()
    }
    
    func didTapCreateTeacher() {
        // Navigate to teacher creation
        // TODO: Implement teacher creation navigation
    }
    
    func didTapTeacher(_ teacher: Teacher) {
        // Handle teacher selection
        // TODO: Implement teacher selection logic
    }
    
    func didTapStudent(_ student: Student) {
        // Handle student selection
        // TODO: Implement student selection logic
    }
    
    func didTapTeacherDetails(_ teacher: Teacher) {
        // Show teacher details
        // TODO: Implement teacher details navigation
    }
    
    func didTapStudentDetails(_ student: Student) {
        // Show student details
        // TODO: Implement student details navigation
    }
    
    func didTapDeleteTeacher(_ teacher: Teacher) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // TODO: AuthenticationService에 deleteUser 메서드 추가 필요
                // try await self.authenticationService.deleteUser(teacher.id)
                
                await MainActor.run { [weak self] in
                    // 삭제 후 데이터 새로고침
                    self?.loadUserData()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.presenter.showError("교사 삭제에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didTapDeleteStudent(_ student: Student) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.studentService.deleteStudent(id: student.id)
                
                await MainActor.run { [weak self] in
                    // 삭제 후 데이터 새로고침
                    self?.loadUserData()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.presenter.showError("학생 삭제에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
}