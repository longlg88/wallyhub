import RIBs

protocol BoardSettingsDependency: Dependency {
    var boardService: BoardService { get }
}

final class BoardSettingsComponent: Component<BoardSettingsDependency> {
    var boardService: BoardService { dependency.boardService }
}

protocol BoardSettingsBuildable: Buildable {
    func build(withListener listener: BoardSettingsListener, boardId: String) -> BoardSettingsRouting
}

final class BoardSettingsBuilder: Builder<BoardSettingsDependency>, BoardSettingsBuildable {
    override init(dependency: BoardSettingsDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: BoardSettingsListener, boardId: String) -> BoardSettingsRouting {
        let component = BoardSettingsComponent(dependency: dependency)
        let viewController = BoardSettingsViewController()
        let interactor = BoardSettingsInteractor(
            presenter: viewController, 
            boardId: boardId,
            boardService: component.boardService
        )
        interactor.listener = listener
        
        return BoardSettingsRouter(interactor: interactor, viewController: viewController)
    }
}
