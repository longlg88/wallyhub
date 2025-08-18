import RIBs

// MARK: - Navigation Protocols

protocol BoardSettingsRouting: ViewableRouting {}

protocol BoardSettingsViewControllable: ViewControllable {
    func setBoardService(_ boardService: BoardService, boardId: String)
}

final class BoardSettingsRouter: ViewableRouter<BoardSettingsInteractable, BoardSettingsViewControllable>, BoardSettingsRouting {
    override init(interactor: BoardSettingsInteractable, viewController: BoardSettingsViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}