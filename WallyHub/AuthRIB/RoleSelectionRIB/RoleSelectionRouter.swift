import RIBs

// MARK: - Navigation Protocols

protocol RoleSelectionRouting: ViewableRouting {
    // Add routing methods if needed
}

protocol RoleSelectionViewControllable: ViewControllable {
    // Router가 View에 접근할 때 필요한 메서드만
}

final class RoleSelectionRouter: ViewableRouter<RoleSelectionInteractable, RoleSelectionViewControllable>, RoleSelectionRouting {

    override init(interactor: RoleSelectionInteractable, viewController: RoleSelectionViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}