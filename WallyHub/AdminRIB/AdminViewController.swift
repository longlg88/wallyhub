import RIBs
import SwiftUI
import UIKit

final class AdminViewController: UIViewController, AdminPresentable, AdminViewControllable {

    weak var listener: AdminPresentableListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("👑 AdminViewController: viewDidLoad() 호출됨")
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("👁️ AdminViewController: viewWillAppear() 호출됨")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("✅ AdminViewController: viewDidAppear() 호출됨 - 관리자 대시보드 표시")
    }
    
    private func setupUI() {
        print("🔧 AdminViewController: setupUI() 시작")
        let adminView = AdminViewContent(
            onSystemDashboardTapped: { [weak self] in
                self?.listener?.didTapSystemDashboard()
            },
            onAllBoardsManagementTapped: { [weak self] in
                self?.listener?.didTapAllBoardsManagement()
            },
            onUserManagementTapped: { [weak self] in
                self?.listener?.didTapUserManagement()
            },
            onSignOutTapped: { [weak self] in
                self?.listener?.didTapSignOut()
            }
        )
        
        let hostingController = UIHostingController(rootView: adminView)
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
    
    // MARK: - AdminViewControllable
    
    private var currentPresentedViewController: UIViewController?
    
    func present(viewController: ViewControllable) {
        // 기존에 presented된 ViewController가 있으면 먼저 정리
        if let currentPresented = currentPresentedViewController {
            currentPresented.dismiss(animated: false) { [weak self] in
                self?.currentPresentedViewController = nil
            }
        }
        
        let childViewController = viewController.uiviewController
        let nav = UINavigationController(rootViewController: childViewController)
        
        // Modal presentation style 설정
        nav.modalPresentationStyle = .fullScreen
        
        currentPresentedViewController = nav
        
        // Main queue에서 present 수행
        DispatchQueue.main.async { [weak self] in
            self?.present(nav, animated: true)
        }
    }
    
    func dismiss() {
        guard let currentPresented = currentPresentedViewController else {
            return
        }
        
        // Main queue에서 dismiss 수행
        DispatchQueue.main.async { [weak self] in
            currentPresented.dismiss(animated: true) {
                self?.currentPresentedViewController = nil
            }
        }
    }
}

// MARK: - SwiftUI Content

struct AdminViewContent: View {
    let onSystemDashboardTapped: () -> Void
    let onAllBoardsManagementTapped: () -> Void
    let onUserManagementTapped: () -> Void
    let onSignOutTapped: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Modern Admin Header with Crown
                    VStack(spacing: 20) {
                        // Crown Profile with Gradient
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("관리자님, 환영합니다!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("전체 시스템을 모니터링하고\n관리하여 안정적인 서비스를 제공하세요")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.top, 20)
                    
                    
                    // Main Admin Functions
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.2.fill")
                                .foregroundColor(.red)
                                .font(.headline)
                            Text("관리 기능")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        VStack(spacing: 16) {
                            // System Dashboard
                            Button(action: onSystemDashboardTapped) {
                                AdminModernActionCard(
                                    icon: "chart.bar.xaxis",
                                    title: "시스템 대시보드",
                                    subtitle: "실시간 시스템 상태 및 성능 모니터링",
                                    colors: [.red.opacity(0.8), .orange.opacity(0.8)]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // All Boards Management
                            Button(action: onAllBoardsManagementTapped) {
                                AdminModernActionCard(
                                    icon: "list.clipboard.fill",
                                    title: "전체 게시판 관리",
                                    subtitle: "모든 게시판 조회, 설정 및 관리",
                                    colors: [.green.opacity(0.8), .mint.opacity(0.8)]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // User Management
                            Button(action: onUserManagementTapped) {
                                AdminModernActionCard(
                                    icon: "person.2.badge.gearshape",
                                    title: "사용자 관리",
                                    subtitle: "교사 및 학생 계정 생성, 수정, 삭제",
                                    colors: [.orange.opacity(0.8), .yellow.opacity(0.8)]
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .overlay(
                // Floating Sign Out Button
                VStack {
                    Spacer()
                    
                    Button(action: onSignOutTapped) {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                                .font(.title2)
                            Text("로그아웃")
                                .font(.headline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 34)
                }
            )
        }
    }
}


// MARK: - Modern Admin UI Components

struct AdminModernActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let colors: [Color]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(
                    colors: colors.map { $0.opacity(0.2) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ), lineWidth: 1)
        )
    }
}


