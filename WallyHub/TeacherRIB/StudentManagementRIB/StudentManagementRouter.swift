import RIBs

// MARK: - Navigation Protocols

protocol StudentManagementRouting: ViewableRouting {}

protocol StudentManagementViewControllable: ViewControllable {}

final class StudentManagementRouter: ViewableRouter<StudentManagementInteractable, StudentManagementViewControllable>, StudentManagementRouting {
    
    override init(interactor: StudentManagementInteractable, viewController: StudentManagementViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}