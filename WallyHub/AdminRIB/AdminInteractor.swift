import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol AdminPresentable: Presentable {
    var listener: AdminPresentableListener? { get set }
}

protocol AdminListener: AnyObject {
    func adminDidRequestSignOut()
    func adminDidCompleteFlow()
}

final class AdminInteractor: PresentableInteractor<AdminPresentable>, AdminInteractable, AdminPresentableListener {

    weak var router: AdminRouting?
    weak var listener: AdminListener?

    override init(presenter: AdminPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        print("👑 AdminInteractor.didBecomeActive() - 관리자 대시보드 표시")
        // 관리자 메인 대시보드를 먼저 표시
        // 사용자가 버튼을 눌렀을 때만 자식 RIB들로 이동
    }

    override func willResignActive() {
        super.willResignActive()
        // AdminRIB이 deactivate될 때 모든 child RIB들을 정리
        router?.dismissChild()
    }
    
    // MARK: - AdminPresentableListener
    
    func didTapSystemDashboard() {
        router?.routeToSystemDashboard()
    }
    
    func didTapAllBoardsManagement() {
        router?.routeToAllBoardsManagement()
    }
    
    func didTapUserManagement() {
        router?.routeToUserManagement()
    }
    
    func didTapSignOut() {
        listener?.adminDidRequestSignOut()
    }
}

// MARK: - Child RIB Listeners

extension AdminInteractor: SystemDashboardListener {
    func systemDashboardDidComplete() {
        print("🔄 AdminInteractor: SystemDashboard 완료 - 메인으로 돌아가기")
        router?.dismissSystemDashboard()
    }
    
    func systemDashboardDidRequestAllBoardsManagement() {
        router?.dismissSystemDashboard()
        router?.routeToAllBoardsManagement()
    }
    
    func systemDashboardDidRequestUserManagement() {
        router?.dismissSystemDashboard()
        router?.routeToUserManagement()
    }
}

extension AdminInteractor: AllBoardsManagementListener {
    func allBoardsManagementDidComplete() {
        print("🔄 AdminInteractor: AllBoardsManagement 완료 - 메인으로 돌아가기")
        router?.dismissAllBoardsManagement()
    }
}

extension AdminInteractor: UserManagementListener {
    func userManagementDidComplete() {
        print("🔄 AdminInteractor: UserManagement 완료 - 메인으로 돌아가기")
        router?.dismissUserManagement()
    }
}

// MARK: - Protocols

protocol AdminInteractable: Interactable, SystemDashboardListener, AllBoardsManagementListener, UserManagementListener {
    var router: AdminRouting? { get set }
    var listener: AdminListener? { get set }
}

protocol AdminPresentableListener: AnyObject {
    func didTapSystemDashboard()
    func didTapAllBoardsManagement()
    func didTapUserManagement()
    func didTapSignOut()
}
