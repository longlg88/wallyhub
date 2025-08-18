import RIBs

protocol BoardCreationDependency: Dependency {
    var boardService: BoardService { get }
    var authenticationService: AuthenticationService { get }
}

final class BoardCreationComponent: Component<BoardCreationDependency> {
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    var authenticationService: AuthenticationService {
        return dependency.authenticationService
    }
}

// MARK: - Builder

protocol BoardCreationBuildable: Buildable {
    func build(withListener listener: BoardCreationListener) -> BoardCreationRouting
}

final class BoardCreationBuilder: Builder<BoardCreationDependency>, BoardCreationBuildable {

    override init(dependency: BoardCreationDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: BoardCreationListener) -> BoardCreationRouting {
        let component = BoardCreationComponent(dependency: dependency)
        let viewController = BoardCreationViewController()
        let interactor = BoardCreationInteractor(
            presenter: viewController,
            boardService: component.boardService,
            authenticationService: component.authenticationService
        )
        interactor.listener = listener
        
        return BoardCreationRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
}