import RIBs

protocol AuthDependency: Dependency {
    var authenticationService: AuthenticationService { get }
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var photoService: PhotoService { get }
}

final class AuthComponent: Component<AuthDependency>, RoleSelectionDependency, LoginDependency, StudentLoginDependency {
    
    var authenticationService: AuthenticationService {
        return dependency.authenticationService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var photoService: PhotoService {
        return dependency.photoService
    }
}

// MARK: - Builder

protocol AuthBuildable: Buildable {
    func build(withListener listener: AuthListener) -> AuthRouting
}

final class AuthBuilder: Builder<AuthDependency>, AuthBuildable {

    override init(dependency: AuthDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: AuthListener) -> AuthRouting {
        let component = AuthComponent(dependency: dependency)
        let viewController = AuthViewController()
        let interactor = AuthInteractor(
            presenter: viewController,
            authenticationService: component.authenticationService
        )
        interactor.listener = listener
        
        let roleSelectionBuilder = RoleSelectionBuilder(dependency: component)
        let loginBuilder = LoginBuilder(dependency: component)
        let studentLoginBuilder = StudentLoginBuilder(dependency: component)
        
        return AuthRouter(
            interactor: interactor,
            viewController: viewController,
            roleSelectionBuilder: roleSelectionBuilder,
            loginBuilder: loginBuilder,
            studentLoginBuilder: studentLoginBuilder
        )
    }
}