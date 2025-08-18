import RIBs

protocol AllBoardsManagementDependency: Dependency {
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var authenticationService: AuthenticationService { get }
}

final class AllBoardsManagementComponent: Component<AllBoardsManagementDependency> {
    var boardService: BoardService { dependency.boardService }
    var studentService: StudentService { dependency.studentService }
    var authenticationService: AuthenticationService { dependency.authenticationService }
}

protocol AllBoardsManagementBuildable: Buildable {
    func build(withListener listener: AllBoardsManagementListener) -> AllBoardsManagementRouting
}

final class AllBoardsManagementBuilder: Builder<AllBoardsManagementDependency>, AllBoardsManagementBuildable {
    override init(dependency: AllBoardsManagementDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: AllBoardsManagementListener) -> AllBoardsManagementRouting {
        let component = AllBoardsManagementComponent(dependency: dependency)
        let viewController = AllBoardsManagementViewController()
        let interactor = AllBoardsManagementInteractor(
            presenter: viewController,
            boardService: component.boardService,
            studentService: component.studentService,
            authenticationService: component.authenticationService
        )
        interactor.listener = listener
        
        return AllBoardsManagementRouter(interactor: interactor, viewController: viewController)
    }
}
