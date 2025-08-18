import RIBs

// MARK: - Navigation Protocols

protocol UserManagementRouting: ViewableRouting {}

protocol UserManagementViewControllable: ViewControllable {}

final class UserManagementRouter: ViewableRouter<UserManagementInteractable, UserManagementViewControllable>, UserManagementRouting {
    override init(interactor: UserManagementInteractable, viewController: UserManagementViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}