import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol LoginPresentableListener: AnyObject {
    func didTapLoginButton(email: String, password: String)
    func didTapSignUpButton(username: String, email: String, password: String)
    func didTapBackButton()
}

protocol LoginListener: AnyObject {
    func loginDidComplete(user: User)
    func loginDidRequestBack()
}

protocol LoginInteractable: Interactable {
    var router: LoginRouting? { get set }
    var listener: LoginListener? { get set }
}

protocol LoginPresentable: Presentable {
    var listener: LoginPresentableListener? { get set }
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
}

final class LoginInteractor: PresentableInteractor<LoginPresentable>, LoginInteractable, LoginPresentableListener {

    weak var router: LoginRouting?
    weak var listener: LoginListener?
    
    private let authenticationService: AuthenticationService
    private var loginTask: Task<Void, Never>?

    init(
        presenter: LoginPresentable,
        authenticationService: AuthenticationService
    ) {
        self.authenticationService = authenticationService
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    deinit {
        print("🗑️ LoginInteractor deinit - 메모리 해제")
        loginTask?.cancel()
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
        print("🔄 LoginInteractor willResignActive - 리소스 정리")
        loginTask?.cancel()
        loginTask = nil
        
        // RIBs 참조 정리
        router = nil
        listener = nil
    }
    
    // MARK: - LoginPresentableListener
    
    func didTapLoginButton(email: String, password: String) {
        presenter.showLoading()
        
        // 기존 task가 있으면 취소
        loginTask?.cancel()
        
        loginTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let user = try await self.authenticationService.login(username: email, password: password)
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.listener?.loginDidComplete(user: user)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func didTapSignUpButton(username: String, email: String, password: String) {
        presenter.showLoading()
        
        // 기존 task가 있으면 취소
        loginTask?.cancel()
        
        loginTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                let user = try await self.authenticationService.signUp(username: username, email: email, password: password)
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.listener?.loginDidComplete(user: user)
                }
            } catch {
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.presenter.hideLoading()
                    self.presenter.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func didTapBackButton() {
        listener?.loginDidRequestBack()
    }
}