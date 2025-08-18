import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol RootPresentableListener: AnyObject {
    // Add presenter to interactor communication if needed
}

protocol RootListener: AnyObject {
    // Add root level listeners if needed
}

protocol RootInteractable: Interactable, AuthListener, StudentListener, TeacherListener, AdminListener {
    var router: RootRouting? { get set }
    var listener: RootListener? { get set }
}

protocol RootPresentable: Presentable {
    var listener: RootPresentableListener? { get set }
}

final class RootInteractor: PresentableInteractor<RootPresentable>, RootInteractable, RootPresentableListener {

    weak var router: RootRouting?
    weak var listener: RootListener?
    
    private let authenticationService: AuthenticationService

    init(
        presenter: RootPresentable,
        authenticationService: AuthenticationService
    ) {
        self.authenticationService = authenticationService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        // Check if user is already authenticated
        let isLoggedIn = authenticationService.isLoggedIn()
        print("🔍 RootInteractor.didBecomeActive - isLoggedIn: \(isLoggedIn)")
        
        if isLoggedIn {
            print("✅ User is logged in, routing to role-based screen")
            routeToRoleBased()
        } else {
            print("🔓 User is not logged in, routing to auth screen")
            router?.routeToAuth()
        }
    }
    
    private func routeToRoleBased() {
        guard let currentUser = authenticationService.getCurrentUser() else {
            router?.routeToAuth()
            return
        }
        
        switch currentUser.role {
        case .student:
            router?.routeToStudent()
        case .teacher:
            router?.routeToTeacher()
        case .administrator:
            router?.routeToAdmin()
        }
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - AuthListener
    
    func authDidComplete(userRole: UserRole, student: Student?) {
        switch userRole {
        case .student:
            if let student = student {
                print("🎯 RootInteractor: Student 정보와 함께 StudentRIB으로 라우팅 - Name: \(student.name)")
                router?.routeToStudent(student: student)
            } else {
                print("⚠️ RootInteractor: Student 정보가 없어서 기본 StudentRIB으로 라우팅")
                router?.routeToStudent()
            }
        case .teacher:
            router?.routeToTeacher() 
        case .administrator:
            router?.routeToAdmin()
        }
    }
}

// MARK: - Role-based RIB Listeners

extension RootInteractor: StudentListener {
    func studentDidRequestSignOut() {
        router?.routeToAuth()
    }
    
    func studentDidCompleteFlow() {
        // Handle student completion if needed
    }
}

extension RootInteractor: TeacherListener {
    func teacherDidRequestSignOut() {
        router?.routeToAuth()
    }
    
    func teacherDidCompleteFlow() {
        // Handle teacher completion if needed
    }
}

extension RootInteractor: AdminListener {
    func adminDidRequestSignOut() {
        router?.routeToAuth()
    }
    
    func adminDidCompleteFlow() {
        // Handle admin completion if needed
    }
}

