import RIBs
import SwiftUI

// MARK: - Navigation Protocols

protocol AuthViewControllable: ViewControllable {
    func presentRoleSelection(viewController: ViewControllable)
    func presentLogin(viewController: ViewControllable)
    func presentStudentLogin(viewController: ViewControllable)
    func dismiss()
}

final class AuthRouter: ViewableRouter<AuthInteractable, AuthViewControllable>, AuthRouting {
    
    private let roleSelectionBuilder: RoleSelectionBuildable
    private let loginBuilder: LoginBuildable
    private let studentLoginBuilder: StudentLoginBuildable
    
    private var currentChild: ViewableRouting?
    
    init(
        interactor: AuthInteractable,
        viewController: AuthViewControllable,
        roleSelectionBuilder: RoleSelectionBuildable,
        loginBuilder: LoginBuildable,
        studentLoginBuilder: StudentLoginBuildable
    ) {
        self.roleSelectionBuilder = roleSelectionBuilder
        self.loginBuilder = loginBuilder
        self.studentLoginBuilder = studentLoginBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    override func didLoad() {
        super.didLoad()
        // Initial routing will be handled by AuthInteractor.didBecomeActive()
    }
    
    func routeToRoleSelection() {
        print("🧭 AuthRouter: RoleSelectionRIB으로 라우팅")
        cleanupCurrentChild()
        
        let roleSelectionRouter = roleSelectionBuilder.build(withListener: interactor)
        currentChild = roleSelectionRouter
        attachChild(roleSelectionRouter)
        viewController.presentRoleSelection(viewController: roleSelectionRouter.viewControllable)
        print("✅ AuthRouter: RoleSelectionRIB 라우팅 완료")
    }
    
    func routeToLogin() {
        print("🧭 AuthRouter: LoginRIB으로 라우팅")
        cleanupCurrentChild()
        
        let loginRouter = loginBuilder.build(withListener: interactor)
        currentChild = loginRouter
        attachChild(loginRouter)
        viewController.presentLogin(viewController: loginRouter.viewControllable)
        print("✅ AuthRouter: LoginRIB 라우팅 완료")
    }
    
    func routeToStudentLogin() {
        print("🧭 AuthRouter: StudentLoginRIB으로 라우팅")
        cleanupCurrentChild()
        
        let studentLoginRouter = studentLoginBuilder.build(withListener: interactor)
        currentChild = studentLoginRouter
        attachChild(studentLoginRouter)
        viewController.presentStudentLogin(viewController: studentLoginRouter.viewControllable)
        print("✅ AuthRouter: StudentLoginRIB 라우팅 완료")
    }
    
    private func cleanupCurrentChild() {
        if let currentChild = currentChild {
            detachChild(currentChild)
            self.currentChild = nil
        }
    }
}

// MARK: - Protocols

protocol AuthRouting: ViewableRouting {
    func routeToRoleSelection()
    func routeToLogin()
    func routeToStudentLogin()
}

// MARK: - Child Listeners