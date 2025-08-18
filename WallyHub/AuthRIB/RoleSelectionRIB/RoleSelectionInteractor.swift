import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol RoleSelectionPresentableListener: AnyObject {
    func didSelectTeacherRole()
    func didSelectStudentRole()
}

protocol RoleSelectionListener: AnyObject {
    func roleSelectionDidSelectTeacher()
    func roleSelectionDidSelectStudent()
}

protocol RoleSelectionInteractable: Interactable {
    var router: RoleSelectionRouting? { get set }
    var listener: RoleSelectionListener? { get set }
}

protocol RoleSelectionPresentable: Presentable {
    var listener: RoleSelectionPresentableListener? { get set }
}

final class RoleSelectionInteractor: PresentableInteractor<RoleSelectionPresentable>, RoleSelectionInteractable, RoleSelectionPresentableListener {

    weak var router: RoleSelectionRouting?
    weak var listener: RoleSelectionListener?

    override init(presenter: RoleSelectionPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - RoleSelectionPresentableListener
    
    func didSelectTeacherRole() {
        print("📤 RoleSelectionInteractor: Teacher 선택을 AuthInteractor로 전달")
        listener?.roleSelectionDidSelectTeacher()
    }
    
    func didSelectStudentRole() {
        print("📤 RoleSelectionInteractor: Student 선택을 AuthInteractor로 전달")
        listener?.roleSelectionDidSelectStudent()
    }
}

