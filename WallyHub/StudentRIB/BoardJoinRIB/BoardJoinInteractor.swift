import RIBs
import RxSwift
import Foundation

// MARK: - Business Logic Protocols

protocol BoardJoinPresentable: Presentable {
    var listener: BoardJoinPresentableListener? { get set }
    func showBoardInfo(board: Board)
    func showJoinSuccess()
    func showError(message: String)
    func showLoading(_ show: Bool)
}

protocol BoardJoinListener: AnyObject {
    func boardJoinDidComplete(boardId: String)
    func boardJoinDidCancel()
}

final class BoardJoinInteractor: PresentableInteractor<BoardJoinPresentable>, BoardJoinInteractable, BoardJoinPresentableListener {

    weak var router: BoardJoinRouting?
    weak var listener: BoardJoinListener?
    
    private let studentService: StudentService
    private let boardService: BoardService
    private let boardId: String
    private let disposeBag = DisposeBag()
    
    private var currentBoard: Board?

    init(
        presenter: BoardJoinPresentable,
        studentService: StudentService,
        boardService: BoardService,
        boardId: String
    ) {
        self.studentService = studentService
        self.boardService = boardService
        self.boardId = boardId
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        loadBoardInfo()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - Private Methods
    
    private func loadBoardInfo() {
        presenter.showLoading(true)
        
        Task {
            do {
                let board = try await boardService.getBoard(id: boardId)
                await MainActor.run {
                    self.presenter.showLoading(false)
                    self.currentBoard = board
                    self.presenter.showBoardInfo(board: board)
                }
            } catch {
                await MainActor.run {
                    self.presenter.showLoading(false)
                    self.presenter.showError(message: "보드 정보를 불러올 수 없습니다.")
                }
            }
        }
    }
    
    // MARK: - BoardJoinPresentableListener
    
    func didEnterStudentInfo(name: String, studentId: String, password: String) {
        guard currentBoard != nil else { return }
        
        presenter.showLoading(true)
        
        Task {
            do {
                _ = try await studentService.joinBoardWithPassword(
                    name: name,
                    studentId: studentId,
                    password: password,
                    boardId: boardId
                )
                
                await MainActor.run {
                    self.presenter.showLoading(false)
                    self.presenter.showJoinSuccess()
                }
                
                // 2초 후 완료 처리
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                await MainActor.run {
                    self.listener?.boardJoinDidComplete(boardId: self.boardId)
                }
                
            } catch {
                await MainActor.run {
                    self.presenter.showLoading(false)
                    self.presenter.showError(message: "게시판 참여에 실패했습니다.")
                }
            }
        }
    }
    
    func didTapCancel() {
        listener?.boardJoinDidCancel()
    }
}

// MARK: - Protocols

protocol BoardJoinInteractable: Interactable {
    var router: BoardJoinRouting? { get set }
    var listener: BoardJoinListener? { get set }
}

protocol BoardJoinPresentableListener: AnyObject {
    func didEnterStudentInfo(name: String, studentId: String, password: String)
    func didTapCancel()
}
