import RIBs
import SwiftUI

// MARK: - Navigation Protocols

protocol AdminRouting: ViewableRouting {
    func routeToSystemDashboard()
    func routeToAllBoardsManagement() 
    func routeToUserManagement()
    func dismissSystemDashboard()
    func dismissAllBoardsManagement()
    func dismissUserManagement()
    func dismissChild()
}

protocol AdminViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss()
}

final class AdminRouter: ViewableRouter<AdminInteractable, AdminViewControllable>, AdminRouting {
    
    private let systemDashboardBuilder: SystemDashboardBuildable
    private let allBoardsManagementBuilder: AllBoardsManagementBuildable
    private let userManagementBuilder: UserManagementBuildable
    
    private var systemDashboardRouter: SystemDashboardRouting?
    private var allBoardsManagementRouter: AllBoardsManagementRouting?
    private var userManagementRouter: UserManagementRouting?
    
    init(
        interactor: AdminInteractable,
        viewController: AdminViewControllable,
        systemDashboardBuilder: SystemDashboardBuildable,
        allBoardsManagementBuilder: AllBoardsManagementBuildable,
        userManagementBuilder: UserManagementBuildable
    ) {
        self.systemDashboardBuilder = systemDashboardBuilder
        self.allBoardsManagementBuilder = allBoardsManagementBuilder
        self.userManagementBuilder = userManagementBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    func routeToSystemDashboard() {
        dismissCurrentChild()
        
        guard systemDashboardRouter == nil else { return }
        
        let router = systemDashboardBuilder.build(withListener: interactor)
        systemDashboardRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissSystemDashboard() {
        if let router = systemDashboardRouter {
            detachChild(router)
            systemDashboardRouter = nil
            viewController.dismiss()
        }
    }
    
    func routeToAllBoardsManagement() {
        dismissCurrentChild()
        
        guard allBoardsManagementRouter == nil else { return }
        
        let router = allBoardsManagementBuilder.build(withListener: interactor)
        allBoardsManagementRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissAllBoardsManagement() {
        if let router = allBoardsManagementRouter {
            detachChild(router)
            allBoardsManagementRouter = nil
            viewController.dismiss()
        }
    }
    
    func routeToUserManagement() {
        dismissCurrentChild()
        
        guard userManagementRouter == nil else { return }
        
        let router = userManagementBuilder.build(withListener: interactor)
        userManagementRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissUserManagement() {
        if let router = userManagementRouter {
            detachChild(router)
            userManagementRouter = nil
            viewController.dismiss()
        }
    }
    
    func dismissChild() {
        dismissCurrentChild()
    }
    
    private func dismissCurrentChild() {
        if let router = systemDashboardRouter {
            detachChild(router)
            systemDashboardRouter = nil
            viewController.dismiss()
        } else if let router = allBoardsManagementRouter {
            detachChild(router)
            allBoardsManagementRouter = nil
            viewController.dismiss()
        } else if let router = userManagementRouter {
            detachChild(router)
            userManagementRouter = nil
            viewController.dismiss()
        }
    }
}

