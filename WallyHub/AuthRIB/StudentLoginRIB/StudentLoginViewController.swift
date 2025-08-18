import RIBs
import SwiftUI
import UIKit

final class StudentLoginViewController: UIViewController, StudentLoginPresentable, StudentLoginViewControllable {

    weak var listener: StudentLoginPresentableListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let studentLoginView = StudentLoginViewContent(
            onLoginTapped: { [weak self] name, studentId, password in
                print("🎯 StudentLogin: 로그인 버튼 클릭 - Name: \(name), StudentID: \(studentId)")
                self?.listener?.didTapLogin(name: name, studentId: studentId, password: password)
            },
            onQRCodeTapped: { [weak self] in
                print("🎯 StudentLogin: QR 스캔 버튼 클릭")
                self?.listener?.didTapQRScan()
            },
            onBackTapped: { [weak self] in
                print("🎯 StudentLogin: 뒤로가기 버튼 클릭")
                self?.listener?.didTapBackButton()
            }
        )
        
        let hostingController = UIHostingController(rootView: studentLoginView)
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
    
    // MARK: - StudentLoginPresentable
    
    func showLoginError(_ message: String) {
        let alert = UIAlertController(title: "로그인 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - StudentLoginViewControllable
    
    func present(viewController: ViewControllable) {
        let viewControllerToPresent = viewController.uiviewController
        viewControllerToPresent.modalPresentationStyle = .fullScreen
        
        // 현재 presented된 view controller가 있다면 그 위에 present
        var topViewController: UIViewController = self
        while let presentedVC = topViewController.presentedViewController {
            topViewController = presentedVC
        }
        
        topViewController.present(viewControllerToPresent, animated: true)
    }
    
    func dismiss(viewController: ViewControllable) {
        let vcToDismiss = viewController.uiviewController
        
        // 현재 presented된 view controller인지 확인하고 dismiss
        if vcToDismiss.presentingViewController != nil {
            vcToDismiss.dismiss(animated: true)
        }
    }
    
    func dismiss(viewController: ViewControllable, completion: @escaping () -> Void) {
        let vcToDismiss = viewController.uiviewController
        
        // 현재 presented된 view controller인지 확인하고 dismiss
        if vcToDismiss.presentingViewController != nil {
            vcToDismiss.dismiss(animated: true, completion: completion)
        } else {
            completion()
        }
    }
}

// MARK: - SwiftUI Content

struct StudentLoginViewContent: View {
    let onLoginTapped: (String, String, String) -> Void
    let onQRCodeTapped: () -> Void
    let onBackTapped: () -> Void
    
    @State private var name = ""
    @State private var studentId = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    StudentHeaderView(geometry: geometry)
                    formSection
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 24) {
            BackButton.studentLogin { onBackTapped() }
            
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
        .offset(y: -32)
    }
    
    // MARK: - Login Form
    private var loginForm: some View {
        VStack(spacing: 20) {
            // 학생 로그인 입력 필드
            StudentInputFields(
                name: $name,
                studentId: $studentId,
                password: $password,
                isPasswordVisible: $isPasswordVisible
            )
            
            StudentMessageView(
                errorMessage: errorMessage,
                successMessage: successMessage
            )
            
            // 로그인 버튼
            Button(action: {
                handleFormSubmission()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    }
                    Text("로그인")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    isFormValid && !isLoading
                        ? Color.blue
                        : Color.gray.opacity(0.6)
                )
                .cornerRadius(12)
            }
            .disabled(!isFormValid || isLoading)
            
            // QR 코드 스캔 구분선 및 버튼
            qrCodeScanSection
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    // MARK: - QR Code Scan Section
    private var qrCodeScanSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack { Divider() }
                Text("또는")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                VStack { Divider() }
            }
            .padding(.top, 8)
            
            qrCodeScanButton
        }
    }
    
    // MARK: - QR Code Scan Button
    private var qrCodeScanButton: some View {
        Button(action: onQRCodeTapped) {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                
                Text("QR 코드로 게시판 참여")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(isLoading ? 0.95 : 1.0)
            .opacity(isLoading ? 0.7 : 1.0)
        }
        .disabled(isLoading)
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !name.isEmpty && !studentId.isEmpty && !password.isEmpty && password.count >= 6
    }
    
    // MARK: - Actions
    private func handleFormSubmission() {
        onLoginTapped(name, studentId, password)
    }
}

// MARK: - Student Header Component
struct StudentHeaderView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                logoIcon
                titleSection
            }
        }
        .frame(height: geometry.size.height * 0.35)
        .frame(maxWidth: .infinity)
        .background(gradientBackground)
    }
    
    // MARK: - Components
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
            
            Image(systemName: "studentdesk")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 8) {
            Text("Student Portal")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("학생 전용 로그인")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("이름과 학번으로 간편하게 로그인하세요")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private var gradientBackground: some View {
        LinearGradient(
            colors: [.purple, .pink, .orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Student Input Fields Component
struct StudentInputFields: View {
    @Binding var name: String
    @Binding var studentId: String
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            nameField
            studentIdField
            passwordField
        }
    }
    
    // MARK: - Components
    private var nameField: some View {
        StudentTextField(
            title: "Name",
            placeholder: "이름을 입력하세요",
            text: $name,
            icon: "person.fill"
        )
    }
    
    private var studentIdField: some View {
        StudentTextField(
            title: "Student ID",
            placeholder: "학번을 입력하세요",
            text: $studentId,
            icon: "number"
        )
    }
    
    private var passwordField: some View {
        StudentPasswordField(
            title: "Password",
            placeholder: "비밀번호를 입력하세요",
            text: $password,
            isVisible: $isPasswordVisible
        )
    }
}

// MARK: - Student Text Field Component
struct StudentTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleLabel
            textFieldContainer
        }
    }
    
    // MARK: - Components
    private var titleLabel: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
    }
    
    private var textFieldContainer: some View {
        HStack(spacing: 12) {
            iconView
            textField
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(borderOverlay)
    }
    
    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.purple.opacity(0.7))
            .frame(width: 20)
    }
    
    private var textField: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 16, weight: .medium))
            .autocapitalization(shouldCapitalize ? .words : .none)
            .disableAutocorrection(false)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Computed Properties
    private var shouldCapitalize: Bool {
        icon == "person.fill"
    }
}

// MARK: - Student Password Field Component
struct StudentPasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            titleLabel
            passwordFieldContainer
        }
    }
    
    // MARK: - Components
    private var titleLabel: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
    }
    
    private var passwordFieldContainer: some View {
        HStack(spacing: 12) {
            iconView
            passwordField
            visibilityToggle
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(borderOverlay)
    }
    
    private var iconView: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.purple.opacity(0.7))
            .frame(width: 20)
    }
    
    private var passwordField: some View {
        Group {
            if isVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
        }
        .font(.system(size: 16, weight: .medium))
        .autocapitalization(.none)
        .disableAutocorrection(true)
    }
    
    private var visibilityToggle: some View {
        Button(action: { isVisible.toggle() }) {
            Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.purple.opacity(0.7))
        }
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Student Message View Component
struct StudentMessageView: View {
    let errorMessage: String?
    let successMessage: String?
    
    var body: some View {
        VStack(spacing: 12) {
            if let errorMessage = errorMessage {
                errorMessageView(errorMessage)
            }
            
            if let successMessage = successMessage {
                successMessageView(successMessage)
            }
        }
    }
    
    // MARK: - Components
    private func errorMessageView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
    }
    
    private func successMessageView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.green)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
    }
}

// MARK: - Back Button Component
struct BackButton {
    static func studentLogin(action: @escaping () -> Void) -> some View {
        HStack {
            Button(action: action) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                    Text("뒤로")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.purple)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
}