import RIBs

// MARK: - Navigation Protocols

protocol PhotoModerationRouting: ViewableRouting {}

protocol PhotoModerationViewControllable: ViewControllable {}

final class PhotoModerationRouter: ViewableRouter<PhotoModerationInteractable, PhotoModerationViewControllable>, PhotoModerationRouting {
    override init(interactor: PhotoModerationInteractable, viewController: PhotoModerationViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}