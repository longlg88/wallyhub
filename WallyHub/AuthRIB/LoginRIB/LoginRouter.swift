import RIBs

// MARK: - Protocols

protocol LoginRouting: ViewableRouting {
    // Add routing methods if needed
}

protocol LoginViewControllable: ViewControllable {
    // Router가 View에 접근할 때 필요한 메서드만
}

final class LoginRouter: ViewableRouter<LoginInteractable, LoginViewControllable>, LoginRouting {

    override init(interactor: LoginInteractable, viewController: LoginViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}