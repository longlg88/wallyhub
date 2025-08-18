import RIBs
import SwiftUI
import UIKit

final class LoginViewController: UIViewController, LoginPresentable, LoginViewControllable {

    weak var listener: LoginPresentableListener?
    
    private var hostingController: UIHostingController<LoginViewContent>?
    private var loginView: LoginViewContent?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - LoginPresentable
    
    func showLoading() {
        // TODO: Implement loading state in SwiftUI view
        print("🔄 Login loading...")
    }
    
    func hideLoading() {
        // TODO: Implement hide loading state in SwiftUI view
        print("✅ Login loading finished")
    }
    
    func showError(_ message: String) {
        let alert = UIAlertController(title: "Login Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupUI() {
        let loginView = LoginViewContent(
            onLoginTapped: { [weak self] email, password in
                self?.listener?.didTapLoginButton(email: email, password: password)
            },
            onSignUpTapped: { [weak self] username, email, password in
                self?.listener?.didTapSignUpButton(username: username, email: email, password: password)
            },
            onBackTapped: { [weak self] in
                self?.listener?.didTapBackButton()
            }
        )
        
        let hostingController = UIHostingController(rootView: loginView)
        self.hostingController = hostingController
        self.loginView = loginView
        
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
}

// MARK: - SwiftUI Content (Art Wall Design)

struct LoginViewContent: View {
    let onLoginTapped: (String, String) -> Void
    let onSignUpTapped: (String, String, String) -> Void
    let onBackTapped: () -> Void
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpMode = false
    @State private var username = ""
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header with art_wall design
                    LoginHeaderView(geometry: geometry)
                    
                    // Form Section with art_wall design
                    formSection
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            // Back Button
            HStack {
                Button(action: onBackTapped) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            
            // Mode Selector
            LoginModeSelector(
                isSignUpMode: $isSignUpMode,
                onModeChange: { }
            )
            
            // Login Form
            loginForm
        }
        .background(Color(.systemBackground))
        .clipShape(
            .rect(
                topLeadingRadius: 32,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 32
            )
        )
        .offset(y: 10)
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Input Fields
            VStack(spacing: 20) {
                if isSignUpMode {
                    LoginTextField(
                        title: "Username",
                        placeholder: "사용자명을 입력하세요",
                        text: $username,
                        icon: "person.fill"
                    )
                }
                
                LoginTextField(
                    title: "Email",
                    placeholder: isSignUpMode ? "이메일을 입력하세요" : "이메일 또는 사용자명을 입력하세요",
                    text: $email,
                    icon: "envelope.fill"
                )
                
                LoginTextField(
                    title: "Password",
                    placeholder: "비밀번호를 입력하세요",
                    text: $password,
                    icon: "lock.fill",
                    isSecure: true
                )
            }
            
            // Action Button
            Button(action: {
                if isSignUpMode {
                    onSignUpTapped(username, email, password)
                } else {
                    onLoginTapped(email, password)
                }
            }) {
                Text(isSignUpMode ? "Sign Up" : "Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .disabled(email.isEmpty || password.isEmpty || (isSignUpMode && username.isEmpty))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
}

// MARK: - Art Wall Components

struct LoginHeaderView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                logoIcon
                titleSection
            }
        }
        .frame(height: geometry.size.height * 0.45)
        .frame(maxWidth: .infinity)
        .background(gradientBackground)
        .padding(.top, 20)
    }
    
    private var logoIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
            
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("WallyHub")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Digital Art Wall")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            Text("교사와 학생을 위한 디지털 아트 플랫폼")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct LoginModeSelector: View {
    @Binding var isSignUpMode: Bool
    let onModeChange: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            loginButton
            signUpButton
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private var loginButton: some View {
        Button(action: {
            isSignUpMode = false
            onModeChange()
        }) {
            Text("Login")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(!isSignUpMode ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(!isSignUpMode ? AnyView(Color.blue.cornerRadius(16)) : AnyView(Color.clear))
        }
    }
    
    private var signUpButton: some View {
        Button(action: {
            isSignUpMode = true
            onModeChange()
        }) {
            Text("Sign Up")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isSignUpMode ? .white : .black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSignUpMode ? AnyView(Color.blue.cornerRadius(16)) : AnyView(Color.clear))
        }
    }
}

struct LoginTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                        .keyboardType(title == "Email" ? .emailAddress : .default)
                        .autocapitalization(.none)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}