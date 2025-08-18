import RIBs
import SwiftUI
import UIKit

final class StudentViewController: UIViewController, StudentPresentable, StudentViewControllable {

    weak var listener: StudentPresentableListener?
    private var currentStudent: Student?
    private var hostingController: UIHostingController<StudentViewContent>?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🎓 StudentViewController: viewDidLoad() 호출됨")
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👁️ StudentViewController: viewWillAppear() 호출됨")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ StudentViewController: viewDidAppear() 호출됨")
    }
    
    func updateStudentInfo(student: Student) {
        print("📱 StudentViewController: 학생 정보 업데이트 - Name: \(student.name)")
        self.currentStudent = student
        updateUI()
    }
    
    private func setupUI() {
        print("🔧 StudentViewController: setupUI() 시작")
        updateUI()
        print("✅ StudentViewController: setupUI() 완료")
    }
    
    private func updateUI() {
        print("🎨 StudentViewController: updateUI() 시작 - Student: \(currentStudent?.name ?? "nil")")
        
        // Remove existing hosting controller
        if let existingController = hostingController {
            print("🗑️ StudentViewController: 기존 호스팅 컨트롤러 제거")
            existingController.willMove(toParent: nil)
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
        }
        
        let studentView = StudentViewContent(
            studentName: currentStudent?.name ?? "학생",
            onQRScanTapped: { [weak self] in
                self?.listener?.didTapQRScanButton()
            },
            onMyBoardsTapped: { [weak self] in
                self?.listener?.didTapMyBoardsButton()
            },
            onSignOutTapped: { [weak self] in
                self?.listener?.didTapSignOutButton()
            }
        )
        
        self.hostingController = UIHostingController(rootView: studentView)
        addChild(hostingController!)
        view.addSubview(hostingController!.view)
        
        hostingController!.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController!.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hostingController!.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController!.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController!.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        hostingController!.didMove(toParent: self)
    }
    
    // MARK: - StudentViewControllable
    
    func presentQRScanner(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismissQRScanner() {
        dismiss(animated: true)
    }
    
    func presentBoardJoin(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismissBoardJoin() {
        dismiss(animated: true)
    }
    
    func presentPhotoUpload(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismissPhotoUpload() {
        dismiss(animated: true)
    }
    
    func presentMyPhotos(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismissMyPhotos() {
        dismiss(animated: true)
    }
    
    func presentMyParticipations(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismissMyParticipations() {
        dismiss(animated: true)
    }
}

// MARK: - SwiftUI Content

struct StudentViewContent: View {
    let studentName: String
    let onQRScanTapped: () -> Void
    let onMyBoardsTapped: () -> Void
    let onSignOutTapped: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color.blue.opacity(0.05),
                    Color.purple.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Hero Header Section
                    VStack(spacing: 24) {
                        // Animated Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.8),
                                            Color.purple.opacity(0.6),
                                            Color.pink.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                                .shadow(color: .purple.opacity(0.3), radius: 20, x: 0, y: 10)
                                .scaleEffect(isAnimating ? 1.05 : 1.0)
                                .animation(
                                    Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                            
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 45, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 40)
                        
                        // Welcome Text
                        VStack(spacing: 8) {
                            Text("안녕하세요 \(studentName) 학생!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            
                            Text("WallyHub에 오신걸 환영합니다")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .opacity(0.8)
                        }
                    }
                    
                    // Action Cards
                    VStack(spacing: 20) {
                        // QR Scan Card
                        ModernActionCard(
                            title: "QR 코드 스캔",
                            subtitle: "새로운 게시판에 참여하기",
                            icon: "qrcode.viewfinder",
                            gradientColors: [.blue, .cyan, .indigo],
                            action: onQRScanTapped,
                            style: .student
                        )
                        
                        // My Boards Card
                        ModernActionCard(
                            title: "참여 중인 게시판",
                            subtitle: "내가 참여한 게시판 목록 보기",
                            icon: "rectangle.stack.person.crop.fill",
                            gradientColors: [.green, .mint, .teal],
                            action: onMyBoardsTapped,
                            style: .student
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 60)
                    
                    // Modern Sign Out Button
                    Button(action: onSignOutTapped) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.system(size: 20, weight: .medium))
                            
                            Text("로그아웃")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
