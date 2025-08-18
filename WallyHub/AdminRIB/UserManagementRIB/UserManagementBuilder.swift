import RIBs

protocol UserManagementDependency: Dependency {
    var authenticationService: AuthenticationService { get }
    var studentService: StudentService { get }
    var boardService: BoardService { get }
}

final class UserManagementComponent: Component<UserManagementDependency> {
    var authenticationService: AuthenticationService { dependency.authenticationService }
    var studentService: StudentService { dependency.studentService }
    var boardService: BoardService { dependency.boardService }
}

protocol UserManagementBuildable: Buildable {
    func build(withListener listener: UserManagementListener) -> UserManagementRouting
}

final class UserManagementBuilder: Builder<UserManagementDependency>, UserManagementBuildable {
    override init(dependency: UserManagementDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: UserManagementListener) -> UserManagementRouting {
        let component = UserManagementComponent(dependency: dependency)
        let viewController = UserManagementViewController()
        let interactor = UserManagementInteractor(
            presenter: viewController,
            authenticationService: component.authenticationService,
            studentService: component.studentService,
            boardService: component.boardService
        )
        interactor.listener = listener
        
        return UserManagementRouter(interactor: interactor, viewController: viewController)
    }
}
