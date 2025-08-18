import RIBs

// MARK: - Business Logic Protocols

protocol BoardSettingsListener: AnyObject {
    func boardSettingsDidComplete()
}

protocol BoardSettingsPresentableListener: AnyObject {
    func didTapClose()
}


protocol BoardSettingsInteractable: Interactable {
    var router: BoardSettingsRouting? { get set }
    var listener: BoardSettingsListener? { get set }
}

protocol BoardSettingsPresentable: Presentable {
    var listener: BoardSettingsPresentableListener? { get set }
}

final class BoardSettingsInteractor: PresentableInteractor<BoardSettingsPresentable>, BoardSettingsInteractable, BoardSettingsPresentableListener {
    weak var router: BoardSettingsRouting?
    weak var listener: BoardSettingsListener?
    private let boardId: String
    private let boardService: BoardService

    init(presenter: BoardSettingsPresentable, boardId: String, boardService: BoardService) {
        self.boardId = boardId
        self.boardService = boardService
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    override func didBecomeActive() {
        super.didBecomeActive()
        
        if let viewController = presenter as? BoardSettingsViewControllable {
            viewController.setBoardService(boardService, boardId: boardId)
        }
    }
    
    func didTapClose() {
        listener?.boardSettingsDidComplete()
    }
}