import RIBs

protocol LoginDependency: Dependency {
    var authenticationService: AuthenticationService { get }
}

final class LoginComponent: Component<LoginDependency> {
    var authenticationService: AuthenticationService {
        return dependency.authenticationService
    }
}

// MARK: - Builder

protocol LoginBuildable: Buildable {
    func build(withListener listener: LoginListener) -> LoginRouting
}

final class LoginBuilder: Builder<LoginDependency>, LoginBuildable {

    override init(dependency: LoginDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: LoginListener) -> LoginRouting {
        let component = LoginComponent(dependency: dependency)
        let viewController = LoginViewController()
        let interactor = LoginInteractor(
            presenter: viewController,
            authenticationService: component.authenticationService
        )
        interactor.listener = listener
        
        return LoginRouter(interactor: interactor, viewController: viewController)
    }
}