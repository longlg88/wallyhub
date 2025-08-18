import RIBs
import SwiftUI
import UIKit

final class RootViewController: UIViewController, RootPresentable, RootViewControllable {

    weak var listener: RootPresentableListener?
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Add any initial UI setup here
        // For now, we'll just show a loading state until auth flow starts
        let loadingView = UIHostingController(rootView: LoadingView())
        addChild(loadingView)
        view.addSubview(loadingView.view)
        loadingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        loadingView.didMove(toParent: self)
        currentViewController = loadingView
    }

    // MARK: - RootViewControllable

    func present(viewController: ViewControllable) {
        let uiViewController = viewController.uiviewController
        
        // Remove current view controller
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Add new view controller
        addChild(uiViewController)
        view.addSubview(uiViewController.view)
        uiViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            uiViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            uiViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            uiViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            uiViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        uiViewController.didMove(toParent: self)
        currentViewController = uiViewController
    }

    func dismiss() {
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
            currentViewController = nil
        }
    }
}

// MARK: - SwiftUI Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.fill.on.rectangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("WallyHub")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Loading...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .padding()
    }
}