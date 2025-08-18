import RIBs

// MARK: - Business Logic Protocols

protocol AllBoardsManagementListener: AnyObject {
    func allBoardsManagementDidComplete()
}

protocol AllBoardsManagementPresentableListener: AnyObject {
    func viewDidLoad()
    func didTapClose()
    func didTapBoard(_ board: Board)
    func didTapToggleBoardStatus(_ board: Board)
    func didTapDeleteBoard(_ board: Board)
}

protocol AllBoardsManagementInteractable: Interactable {
    var router: AllBoardsManagementRouting? { get set }
    var listener: AllBoardsManagementListener? { get set }
}

protocol AllBoardsManagementPresentable: Presentable {
    var listener: AllBoardsManagementPresentableListener? { get set }
    func showBoards(_ boards: [BoardWithTeacher])
    func showBoardsWithStats(_ boards: [BoardWithStats])
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
}

struct BoardWithTeacher {
    let board: Board
    let teacherName: String
}


final class AllBoardsManagementInteractor: PresentableInteractor<AllBoardsManagementPresentable>, AllBoardsManagementInteractable, AllBoardsManagementPresentableListener {
    weak var router: AllBoardsManagementRouting?
    weak var listener: AllBoardsManagementListener?
    
    private let boardService: BoardService
    private let studentService: StudentService
    private let authenticationService: AuthenticationService

    init(presenter: AllBoardsManagementPresentable, 
         boardService: BoardService,
         studentService: StudentService,
         authenticationService: AuthenticationService) {
        self.boardService = boardService
        self.studentService = studentService
        self.authenticationService = authenticationService
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    func viewDidLoad() {
        loadAllBoards()
    }
    
    private func loadAllBoards() {
        presenter.showLoading()
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let boards = try await self.boardService.getAllBoards()
                
                // 각 게시판의 교사 정보와 통계를 가져와서 BoardWithStats로 변환
                var boardsWithStats: [BoardWithStats] = []
                
                for board in boards {
                    // adminId 또는 teacherId로 교사 정보 조회
                    let teacherUserId = board.teacherId ?? board.adminId
                    let teacherUser = try? await self.authenticationService.getUserById(teacherUserId)
                    let teacherName = teacherUser?.username ?? "알 수 없음"
                    
                    // 실제 학생 수와 사진 수 계산
                    let studentCount = try await self.boardService.calculateStudentCount(for: board.id)
                    let photoCount = try await self.boardService.calculatePhotoCount(for: board.id)
                    
                    let boardWithStats = BoardWithStats(
                        board: board,
                        studentCount: studentCount,
                        photoCount: photoCount,
                        teacherName: teacherName
                    )
                    boardsWithStats.append(boardWithStats)
                }
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showBoardsWithStats(boardsWithStats)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showError("게시판 목록을 불러오는데 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didTapClose() {
        listener?.allBoardsManagementDidComplete()
    }
    
    func didTapBoard(_ board: Board) {
        // Navigate to board details
        // TODO: Implement board details navigation
    }
    
    func didTapToggleBoardStatus(_ board: Board) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // Toggle board status
                var updatedBoard = board
                updatedBoard.isActive.toggle()
                
                try await self.boardService.updateBoard(updatedBoard)
                
                await MainActor.run { [weak self] in
                    // Reload boards to show updated status
                    self?.loadAllBoards()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.presenter.showError("게시판 상태 변경에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func didTapDeleteBoard(_ board: Board) {
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.boardService.deleteBoard(boardId: board.id)
                
                await MainActor.run { [weak self] in
                    // Reload boards to reflect deletion
                    self?.loadAllBoards()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.presenter.showError("게시판 삭제에 실패했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
}