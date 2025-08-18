import RIBs
import SwiftUI
import UIKit

final class AuthViewController: UIViewController, AuthPresentable, AuthViewControllable {

    weak var listener: AuthPresentableListener?
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    // MARK: - AuthViewControllable

    func presentRoleSelection(viewController: ViewControllable) {
        let roleSelectionViewController = viewController.uiviewController
        presentView(roleSelectionViewController)
    }
    
    func presentLogin(viewController: ViewControllable) {
        let loginViewController = viewController.uiviewController
        presentView(loginViewController)
    }
    
    func presentStudentLogin(viewController: ViewControllable) {
        let studentLoginViewController = viewController.uiviewController
        presentView(studentLoginViewController)
    }

    func dismiss() {
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
            currentViewController = nil
        }
    }
    
    private func presentView(_ viewController: UIViewController) {
        // Remove current view controller
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Add new view controller
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        viewController.didMove(toParent: self)
        currentViewController = viewController
    }
}

// MARK: - Placeholder Views (to be implemented by child RIBs)

struct RoleSelectionView: View {
    var body: some View {
        VStack {
            Text("Role Selection")
                .font(.title)
            Text("Choose your role")
                .font(.subheadline)
            // Placeholder - will be replaced by RoleSelectionRIB
        }
        .padding()
    }
}

struct LoginView: View {
    var body: some View {
        VStack {
            Text("Teacher Login")
                .font(.title)
            Text("Login with your credentials")
                .font(.subheadline)
            // Placeholder - will be replaced by LoginRIB
        }
        .padding()
    }
}

struct StudentLoginView: View {
    var body: some View {
        VStack {
            Text("Student Login")
                .font(.title)
            Text("Join with QR code or enter details")
                .font(.subheadline)
            // Placeholder - will be replaced by StudentLoginRIB
        }
        .padding()
    }
}