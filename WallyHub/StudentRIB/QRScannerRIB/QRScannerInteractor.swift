import RIBs
import RxSwift
import AVFoundation

// MARK: - Business Logic Protocols

protocol QRScannerPresentable: Presentable {
    var listener: QRScannerPresentableListener? { get set }
    func showScanResult(boardId: String, boardName: String)
    func showError(message: String)
}

protocol QRScannerListener: AnyObject {
    func qrScannerDidScanBoard(boardId: String)
    func qrScannerDidCancel()
}

final class QRScannerInteractor: PresentableInteractor<QRScannerPresentable>, QRScannerInteractable, QRScannerPresentableListener {

    weak var router: QRScannerRouting?
    weak var listener: QRScannerListener?
    
    private let boardService: BoardService
    private let disposeBag = DisposeBag()
    private var currentTask: Task<Void, Never>?

    init(
        presenter: QRScannerPresentable,
        boardService: BoardService
    ) {
        self.boardService = boardService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
        print("🗑️ QRScannerInteractor: willResignActive - 리소스 정리")
        
        // 실행 중인 Task 취소
        currentTask?.cancel()
        currentTask = nil
    }
    
    deinit {
        print("🗑️ QRScannerInteractor: deinit 호출됨")
    }
    
    // MARK: - QRScannerPresentableListener
    
    func didScanQRCode(content: String) {
        // QR 코드에서 보드 ID 추출
        guard let boardId = extractBoardId(from: content) else {
            presenter.showError(message: "잘못된 QR 코드입니다.")
            return
        }
        
        // 이전 Task 취소
        currentTask?.cancel()
        
        // 보드 정보 확인
        currentTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let board = try await self.boardService.getBoard(id: boardId)
                guard !Task.isCancelled else { return }
                
                await MainActor.run { [weak self] in
                    self?.presenter.showScanResult(boardId: boardId, boardName: board.title)
                }
            } catch {
                guard !Task.isCancelled else { return }
                
                await MainActor.run { [weak self] in
                    self?.presenter.showError(message: "보드를 찾을 수 없습니다.")
                }
            }
        }
    }
    
    func didTapJoinBoard(boardId: String) {
        listener?.qrScannerDidScanBoard(boardId: boardId)
    }
    
    func didTapCancel() {
        listener?.qrScannerDidCancel()
    }
    
    // MARK: - Private Methods
    
    private func extractBoardId(from qrContent: String) -> String? {
        // QR 코드 형식: "wallyhub://board/{boardId}" 또는 단순히 boardId
        if qrContent.hasPrefix("wallyhub://board/") {
            return String(qrContent.dropFirst("wallyhub://board/".count))
        } else if qrContent.count == 20 { // boardId는 20자리로 가정
            return qrContent
        }
        return nil
    }
}

// MARK: - Protocols

protocol QRScannerInteractable: Interactable {
    var router: QRScannerRouting? { get set }
    var listener: QRScannerListener? { get set }
}

protocol QRScannerPresentableListener: AnyObject {
    func didScanQRCode(content: String)
    func didTapJoinBoard(boardId: String)
    func didTapCancel()
}