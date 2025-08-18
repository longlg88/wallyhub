import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol AuthPresentable: Presentable {
    var listener: AuthPresentableListener? { get set }
}

protocol AuthListener: AnyObject {
    func authDidComplete(userRole: UserRole, student: Student?)
}

protocol AuthInteractable: Interactable, RoleSelectionListener, LoginListener, StudentLoginListener {
    var router: AuthRouting? { get set }
    var listener: AuthListener? { get set }
}

final class AuthInteractor: PresentableInteractor<AuthPresentable>, AuthInteractable, AuthPresentableListener {

    weak var router: AuthRouting?
    weak var listener: AuthListener?
    
    private let authenticationService: AuthenticationService

    init(
        presenter: AuthPresentable,
        authenticationService: AuthenticationService
    ) {
        self.authenticationService = authenticationService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        router?.routeToRoleSelection()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - RoleSelectionListener
    
    func roleSelectionDidSelectTeacher() {
        print("🔄 AuthInteractor: Teacher 선택 수신, LoginRIB으로 라우팅")
        router?.routeToLogin()
    }
    
    func roleSelectionDidSelectStudent() {
        print("🔄 AuthInteractor: Student 선택 수신, StudentLoginRIB으로 라우팅")
        router?.routeToStudentLogin()
    }
    
    // MARK: - LoginListener
    
    func loginDidComplete(user: User) {
        // Teacher/Admin login completed with user information
        listener?.authDidComplete(userRole: user.role, student: nil)
    }
    
    func loginDidRequestBack() {
        router?.routeToRoleSelection()
    }
    
    // MARK: - StudentLoginListener
    
    func studentLoginDidComplete(student: Student) {
        print("🔄 AuthInteractor: 학생 로그인 완료 수신 - Name: \(student.name), ID: \(student.studentId)")
        // Student 객체를 RootRIB으로 전달
        listener?.authDidComplete(userRole: .student, student: student)
    }
    
    func studentLoginDidRequestBack() {
        router?.routeToRoleSelection()
    }
}


protocol AuthPresentableListener: AnyObject {
    // Add presenter to interactor communication if needed
}