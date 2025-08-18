import RIBs

protocol SystemDashboardViewControllable: ViewControllable {
}

protocol SystemDashboardRouting: ViewableRouting {
}

final class SystemDashboardRouter: ViewableRouter<SystemDashboardInteractable, SystemDashboardViewControllable>, SystemDashboardRouting {

    override init(interactor: SystemDashboardInteractable, viewController: SystemDashboardViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}