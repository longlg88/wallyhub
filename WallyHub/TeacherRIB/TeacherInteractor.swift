import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol TeacherPresentable: Presentable {
    var listener: TeacherPresentableListener? { get set }
}

protocol TeacherListener: AnyObject {
    func teacherDidRequestSignOut()
    func teacherDidCompleteFlow()
}

final class TeacherInteractor: PresentableInteractor<TeacherPresentable>, TeacherInteractable, TeacherPresentableListener {

    weak var router: TeacherRouting?
    weak var listener: TeacherListener?
    private let authenticationService: AuthenticationService
    private let boardService: BoardService

    init(presenter: TeacherPresentable, authenticationService: AuthenticationService, boardService: BoardService) {
        self.authenticationService = authenticationService
        self.boardService = boardService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        loadCurrentUser()
    }
    
    private func loadCurrentUser() {
        Task { @MainActor in
            if let currentUser = authenticationService.getCurrentUser(),
               let viewController = presenter as? TeacherViewController {
                viewController.setBoardService(boardService)
                viewController.updateUser(currentUser)
            }
        }
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - TeacherPresentableListener
    
    func didTapCreateBoard() {
        router?.routeToBoardCreation()
    }
    
    func didTapManageStudents(boardId: String) {
        router?.routeToStudentManagement(boardId: boardId)
    }
    
    func didTapModeratePhotos(boardId: String) {
        router?.routeToPhotoModeration(boardId: boardId)
    }
    
    func didTapBoardSettings(boardId: String) {
        router?.routeToBoardSettings(boardId: boardId)
    }
    
    func didTapSignOut() {
        listener?.teacherDidRequestSignOut()
    }
    
    func didTapDeleteBoard(boardId: String) {
        Task { @MainActor in
            do {
                try await boardService.deleteBoard(boardId: boardId)
                print("✅ 게시판 삭제 완료: \(boardId)")
                refreshBoards()
            } catch {
                print("❌ 게시판 삭제 실패: \(error)")
                // 에러 처리 로직 추가 가능
            }
        }
    }
    
    func didTapShowQRCode(boardId: String) {
        // QR 코드 표시는 UI에서 직접 처리하도록 수정
        // BoardService 호출로 인한 Timestamp 에러 방지
        print("📱 QR 코드 보기 요청: boardId = \(boardId)")
        print("💡 QR 코드는 게시판 카드에서 직접 표시됩니다.")
    }
    
    func didTapRegenerateQRCode(boardId: String) {
        Task { @MainActor in
            do {
                let updatedBoard = try await boardService.regenerateQRCode(for: boardId)
                print("✅ QR 코드 재생성 완료: \(updatedBoard.qrCode)")
                refreshBoards()
            } catch {
                print("❌ QR 코드 재생성 실패: \(error)")
                // 에러 처리 로직 추가 가능
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func refreshBoards() {
        // TeacherViewController에게 새로고침 요청
        if let viewController = presenter as? TeacherViewController {
            Task { @MainActor in
                viewController.refreshBoards()
            }
        }
    }
}

// MARK: - Child RIB Listeners

extension TeacherInteractor: BoardCreationListener {
    func boardCreationDidComplete(board: Board) {
        router?.dismissBoardCreation()
        // 새 보드가 생성되면 대시보드를 업데이트
        refreshBoards()
    }
    
    func boardCreationDidCancel() {
        router?.dismissBoardCreation()
    }
}

extension TeacherInteractor: StudentManagementListener {
    func studentManagementDidComplete() {
        router?.dismissStudentManagement()
    }
    
    func studentManagementDidCancel() {
        router?.dismissStudentManagement()
    }
}

extension TeacherInteractor: PhotoModerationListener {
    func photoModerationDidComplete() {
        router?.dismissPhotoModeration()
    }
    
    func photoModerationDidCancel() {
        router?.dismissPhotoModeration()
    }
}

extension TeacherInteractor: BoardSettingsListener {
    func boardSettingsDidComplete() {
        router?.dismissBoardSettings()
    }
    
    func boardSettingsDidCancel() {
        router?.dismissBoardSettings()
    }
}

// MARK: - Protocols

protocol TeacherInteractable: Interactable, BoardCreationListener, StudentManagementListener, PhotoModerationListener, BoardSettingsListener {
    var router: TeacherRouting? { get set }
    var listener: TeacherListener? { get set }
}

protocol TeacherPresentableListener: AnyObject {
    func didTapCreateBoard()
    func didTapManageStudents(boardId: String)
    func didTapModeratePhotos(boardId: String)
    func didTapBoardSettings(boardId: String)
    func didTapDeleteBoard(boardId: String)
    func didTapShowQRCode(boardId: String)
    func didTapRegenerateQRCode(boardId: String)
    func didTapSignOut()
}