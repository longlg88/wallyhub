import RIBs
import SwiftUI
import UIKit

final class BoardJoinViewController: UIViewController, BoardJoinPresentable, BoardJoinViewControllable {

    weak var listener: BoardJoinPresentableListener?
    
    private var currentBoard: Board?
    private var isLoading: Bool = false
    private var joinSuccess: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let boardJoinView = BoardJoinViewContent(
            board: currentBoard,
            isLoading: isLoading,
            joinSuccess: joinSuccess,
            onJoinTapped: { [weak self] name, studentId, password in
                self?.listener?.didEnterStudentInfo(name: name, studentId: studentId, password: password)
            },
            onCancelTapped: { [weak self] in
                self?.listener?.didTapCancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: boardJoinView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController.didMove(toParent: self)
    }
    
    // MARK: - BoardJoinPresentable
    
    func showBoardInfo(board: Board) {
        currentBoard = board
        setupUI()
    }
    
    func showJoinSuccess() {
        joinSuccess = true
        setupUI()
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    func showLoading(_ show: Bool) {
        isLoading = show
        setupUI()
    }
}

// MARK: - SwiftUI Content

struct BoardJoinViewContent: View {
    let board: Board?
    let isLoading: Bool
    let joinSuccess: Bool
    let onJoinTapped: (String, String, String) -> Void
    let onCancelTapped: () -> Void
    
    @State private var studentName = ""
    @State private var studentId = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var animateSuccess = false
    @State private var showValidationMessage = false
    @State private var validationMessage = ""
    
    var body: some View {
        ZStack {
            // Dynamic background based on state
            backgroundView
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                ScrollView {
                    VStack(spacing: 32) {
                        if joinSuccess {
                            successView
                        } else {
                            contentView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
        }
        .onAppear {
            if joinSuccess {
                animateSuccess = true
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        Group {
            if joinSuccess {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.1),
                        Color.mint.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if let board = board {
                boardBackgroundGradient(for: board.settings.backgroundImage)
            } else {
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.1),
                        Color.cyan.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: onCancelTapped) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("취소")
                }
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(20)
            }
            .disabled(isLoading)
            
            Spacer()
            
            Text(joinSuccess ? "참여 완료" : "게시판 참여")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Balance the header
            Color.clear
                .frame(width: 80, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Success animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateSuccess ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateSuccess)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateSuccess ? 1.0 : 0.3)
                        .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.2), value: animateSuccess)
                }
                
                VStack(spacing: 12) {
                    Text("게시판 참여 완료!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateSuccess)
                    
                    if let board = board {
                        Text("\"\(board.title)\" 게시판에 성공적으로 참여했습니다.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateSuccess ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateSuccess)
                    }
                    
                    Text("곧 사진 업로드 화면으로 이동합니다.")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.8), value: animateSuccess)
                }
            }
        }
        .padding(.vertical, 60)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 32) {
            // Board Information Card
            if let board = board {
                boardInfoCard(board: board)
            }
            
            // Student Information Form
            studentInfoForm
        }
    }
    
    private func boardInfoCard(board: Board) -> some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("참여할 게시판")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                    
                    Text(board.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Board icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            boardBackgroundGradient(for: board.settings.backgroundImage)
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "rectangle.stack.person.crop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            
            if !board.description.isEmpty {
                HStack {
                    Text(board.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Student Info Form
    
    private var studentInfoForm: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                HStack {
                    Text("학생 정보")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text("게시판 참여를 위해 아래 정보를 입력해주세요.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(spacing: 20) {
                // Name Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("이름")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("실명을 입력해주세요", text: $studentName)
                        .textFieldStyle(ModernTextFieldStyle())
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                
                // Student ID Field  
                VStack(alignment: .leading, spacing: 8) {
                    Text("학번")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    TextField("학번을 입력해주세요", text: $studentId)
                        .textFieldStyle(ModernTextFieldStyle())
                        .keyboardType(.asciiCapable)
                        .disableAutocorrection(true)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("비밀번호")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("비밀번호를 입력해주세요", text: $password)
                            } else {
                                SecureField("비밀번호를 입력해주세요", text: $password)
                            }
                        }
                        .textFieldStyle(ModernTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                        }
                        .padding(.trailing, 16)
                    }
                }
                
                // Validation Rules
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue.opacity(0.7))
                        
                        Text("입력 규칙")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue.opacity(0.8))
                        
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ValidationRuleView(text: "이름: 1-50자의 한글 또는 영문", isValid: isValidName)
                        ValidationRuleView(text: "학번: 1-20자의 영문, 숫자, 하이픈", isValid: isValidStudentId)
                        ValidationRuleView(text: "비밀번호: 6자 이상", isValid: isValidPassword)
                    }
                }
                .padding(.top, 8)
            }
            
            // Join Button
            Button(action: {
                if validateInput() {
                    onJoinTapped(studentName.trimmingCharacters(in: .whitespacesAndNewlines), 
                               studentId.trimmingCharacters(in: .whitespacesAndNewlines),
                               password.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }) {
                HStack(spacing: 12) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    
                    Text(isLoading ? "참여 중..." : "게시판 참여하기")
                        .fontWeight(.semibold)
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Group {
                        if isFormValid && !isLoading {
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.gray.opacity(0.6)
                        }
                    }
                )
                .cornerRadius(16)
                .shadow(
                    color: isFormValid && !isLoading ? .blue.opacity(0.3) : .clear,
                    radius: 8, x: 0, y: 4
                )
            }
            .disabled(!isFormValid || isLoading)
            .scaleEffect(isFormValid && !isLoading ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isValidName: Bool {
        let trimmed = studentName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 50
    }
    
    private var isValidStudentId: Bool {
        let trimmed = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = "^[a-zA-Z0-9-]{1,20}$"
        return !trimmed.isEmpty && trimmed.range(of: pattern, options: .regularExpression) != nil
    }
    
    private var isValidPassword: Bool {
        let trimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 6
    }
    
    private var isFormValid: Bool {
        return isValidName && isValidStudentId && isValidPassword
    }
    
    // MARK: - Helper Methods
    
    private func validateInput() -> Bool {
        if !isValidName {
            validationMessage = "올바른 이름을 입력해주세요. (1-50자의 한글 또는 영문)"
            showValidationMessage = true
            return false
        }
        
        if !isValidStudentId {
            validationMessage = "올바른 학번을 입력해주세요. (1-20자의 영문, 숫자, 하이픈)"
            showValidationMessage = true
            return false
        }
        
        if !isValidPassword {
            validationMessage = "올바른 비밀번호를 입력해주세요. (6자 이상)"
            showValidationMessage = true
            return false
        }
        
        return true
    }
    
    private func boardBackgroundGradient(for backgroundImage: BoardSettings.BackgroundImage) -> LinearGradient {
        switch backgroundImage {
        case .pastelBlue:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelGreen:
            return LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelPurple:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelOrange:
            return LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelPink:
            return LinearGradient(colors: [.pink, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelYellow:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Supporting Views

struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            )
            .font(.body)
    }
}

struct ValidationRuleView: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary.opacity(0.6))
            
            Text("• \(text)")
                .font(.caption)
                .foregroundColor(isValid ? .secondary : .secondary.opacity(0.8))
            
            Spacer()
        }
    }
}