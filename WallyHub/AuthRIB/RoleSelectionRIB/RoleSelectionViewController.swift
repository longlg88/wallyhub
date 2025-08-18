import RIBs
import SwiftUI
import UIKit

final class RoleSelectionViewController: UIViewController, RoleSelectionPresentable, RoleSelectionViewControllable {

    weak var listener: RoleSelectionPresentableListener?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let roleSelectionView = RoleSelectionViewContent(
            onTeacherTapped: { [weak self] in
                print("🎯 RoleSelection: Teacher 역할 선택됨")
                self?.listener?.didSelectTeacherRole()
            },
            onStudentTapped: { [weak self] in
                print("🎯 RoleSelection: Student 역할 선택됨")
                self?.listener?.didSelectStudentRole()
            }
        )
        
        let hostingController = UIHostingController(rootView: roleSelectionView)
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

// MARK: - SwiftUI Content

struct RoleSelectionViewContent: View {
    let onTeacherTapped: () -> Void
    let onStudentTapped: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    RoleSelectionHeaderView(geometry: geometry)
                    RoleSelectionCardsView(
                        onTeacherTapped: onTeacherTapped,
                        onStudentTapped: onStudentTapped
                    )
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
    }
    
    
    
}

// MARK: - Header Component
struct RoleSelectionHeaderView: View {
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                logoSection
                titleSection
            }
        }
        .frame(height: geometry.size.height * 0.45)
        .frame(maxWidth: .infinity)
        .background(gradientBackground)
    }
    
    // MARK: - Components
    private var logoSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
            
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 42, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Wally")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Digital Art Wall")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text("교육용 협업 플랫폼")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
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

// MARK: - Cards Component
struct RoleSelectionCardsView: View {
    let onTeacherTapped: () -> Void
    let onStudentTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                teacherCard
                studentCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 32)
            
            Spacer(minLength: 50)
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
    
    // MARK: - Components
    private var teacherCard: some View {
        RoleCard(
            title: "Teacher / Admin",
            subtitle: "교사 · 관리자",
            description: "게시판을 생성하고 학생 활동을 관리하세요",
            icon: "graduationcap.fill",
            gradient: [.blue, .purple],
            features: [],
            action: onTeacherTapped
        )
    }
    
    private var studentCard: some View {
        RoleCard(
            title: "Student",
            subtitle: "학생",
            description: "게시판에 참여하고 창작 활동을 공유하세요",
            icon: "studentdesk",
            gradient: [.purple, .pink],
            features: [],
            action: onStudentTapped
        )
    }
}
