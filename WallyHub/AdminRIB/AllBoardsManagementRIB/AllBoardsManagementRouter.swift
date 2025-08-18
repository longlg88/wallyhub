import RIBs

// MARK: - Navigation Protocols

protocol AllBoardsManagementRouting: ViewableRouting {}

protocol AllBoardsManagementViewControllable: ViewControllable {}

final class AllBoardsManagementRouter: ViewableRouter<AllBoardsManagementInteractable, AllBoardsManagementViewControllable>, AllBoardsManagementRouting {
    override init(interactor: AllBoardsManagementInteractable, viewController: AllBoardsManagementViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}