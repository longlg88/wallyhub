import RIBs
import RxSwift
import Foundation

// MARK: - Business Logic Protocols

protocol BoardCreationPresentable: Presentable {
    var listener: BoardCreationPresentableListener? { get set }
    func showLoading()
    func hideLoading()
    func showCreationSuccess(board: Board)
    func showCreationError(_ error: Error)
}

protocol BoardCreationListener: AnyObject {
    func boardCreationDidComplete(board: Board)
    func boardCreationDidCancel()
}

final class BoardCreationInteractor: PresentableInteractor<BoardCreationPresentable>, BoardCreationInteractable, BoardCreationPresentableListener {

    weak var router: BoardCreationRouting?
    weak var listener: BoardCreationListener?
    
    private let boardService: BoardService
    private let authenticationService: AuthenticationService

    init(
        presenter: BoardCreationPresentable,
        boardService: BoardService,
        authenticationService: AuthenticationService
    ) {
        self.boardService = boardService
        self.authenticationService = authenticationService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - BoardCreationPresentableListener
    
    func didTapCreateBoard(name: String, description: String) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        presenter.showLoading()
        
        // Get current user info
        guard let currentUser = authenticationService.getCurrentUser() else {
            presenter.hideLoading()
            presenter.showCreationError(WallyError.invalidInput)
            return
        }
        
        // Create board using BoardService
        Task { @MainActor in
            do {
                let settings = BoardSettings()
                let board = try await boardService.createBoard(
                    title: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    adminId: currentUser.id,
                    teacherId: currentUser.id,  // 교사가 생성하므로 teacherId도 현재 사용자 ID로 설정
                    settings: settings
                )
                
                print("✅ 게시판 생성 성공: \(board.title) (ID: \(board.id))")
                
                presenter.hideLoading()
                presenter.showCreationSuccess(board: board)
                
                // Complete after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.listener?.boardCreationDidComplete(board: board)
                }
                
            } catch {
                print("❌ 게시판 생성 실패: \(error)")
                presenter.hideLoading()
                presenter.showCreationError(error)
            }
        }
    }
    
    func didTapCancel() {
        listener?.boardCreationDidCancel()
    }
    
    // MARK: - Private Methods
    
    private func generateQRCode(for boardId: String) -> String {
        // In a real implementation, this would generate a proper QR code
        return "wally://join/\(boardId)"
    }
}

// MARK: - Protocols

protocol BoardCreationInteractable: Interactable {
    var router: BoardCreationRouting? { get set }
    var listener: BoardCreationListener? { get set }
}

protocol BoardCreationPresentableListener: AnyObject {
    func didTapCreateBoard(name: String, description: String)
    func didTapCancel()
}