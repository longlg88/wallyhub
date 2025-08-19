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
        
        // 인증 상태를 안전하게 확인하고 네비게이션
        Task { @MainActor in
            await checkAuthenticationAndNavigate()
        }
    }
    
    @MainActor
    private func checkAuthenticationAndNavigate() async {
        // Firebase Auth 상태가 안정화될 때까지 짧은 딜레이
        try? await Task.sleep(for: .milliseconds(100))
        
        let isLoggedIn = authenticationService.isLoggedIn()
        let currentUser = authenticationService.getCurrentUser()
        
        print("🔍 RootInteractor 인증 상태 확인:")
        print("   isLoggedIn: \(isLoggedIn)")
        print("   currentUser: \(currentUser?.username ?? "없음")")
        
        if isLoggedIn, let user = currentUser {
            print("✅ 인증된 사용자 있음 - 역할별 화면으로 이동: \(user.role.displayName)")
            routeToRoleBased()
        } else {
            print("🔓 인증되지 않은 상태 - Auth 화면으로 이동")
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
        print("🎯 RootInteractor: authDidComplete 받음 - role: \(userRole.displayName)")
        
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
            print("🎯 RootInteractor: Teacher으로 라우팅 시작")
            router?.routeToTeacher()
            print("✅ RootInteractor: Teacher 라우팅 완료")
        case .administrator:
            print("🎯 RootInteractor: Admin으로 라우팅 시작")
            router?.routeToAdmin()
            print("✅ RootInteractor: Admin 라우팅 완료")
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
        print("🚪 교사 로그아웃 요청 받음")
        Task { @MainActor in
            do {
                print("🔄 AuthenticationService.logout() 호출")
                try await authenticationService.logout()
                print("✅ 로그아웃 완료 - Auth 화면으로 이동")
                router?.routeToAuth()
            } catch {
                print("❌ 로그아웃 실패: \(error) - 강제로 Auth 화면 이동")
                router?.routeToAuth()
            }
        }
    }
    
    func teacherDidCompleteFlow() {
        // Handle teacher completion if needed
    }
}

extension RootInteractor: AdminListener {
    func adminDidRequestSignOut() {
        print("🚪 관리자 로그아웃 요청 받음")
        Task { @MainActor in
            do {
                print("🔄 AuthenticationService.logout() 호출")
                try await authenticationService.logout()
                print("✅ 로그아웃 완료 - Auth 화면으로 이동")
                router?.routeToAuth()
            } catch {
                print("❌ 로그아웃 실패: \(error) - 강제로 Auth 화면 이동")
                router?.routeToAuth()
            }
        }
    }
    
    func adminDidCompleteFlow() {
        // Handle admin completion if needed
    }
}

