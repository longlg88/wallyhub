import RIBs
import SwiftUI
import UIKit

// MARK: - View Protocols

protocol MyParticipationsPresentable: Presentable {
    var listener: MyParticipationsPresentableListener? { get set }
    func showLoading()
    func hideLoading()
    func showEmptyState()
    func showParticipations(_ participations: [StudentParticipation])
    func showError(_ message: String)
}

protocol MyParticipationsViewControllable: ViewControllable {
    // Router가 View에 접근할 때 필요한 메서드만
}

final class MyParticipationsViewController: UIViewController, 
                                           MyParticipationsPresentable, 
                                           MyParticipationsViewControllable {
    
    weak var listener: MyParticipationsPresentableListener?
    private var hostingController: UIHostingController<MyParticipationsView>?
    private var participations: [StudentParticipation] = []
    private var loadingState: ParticipationLoadingState = .idle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listener?.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("🔄 MyParticipationsViewController viewDidDisappear")
    }
    
    deinit {
        print("🗑️ MyParticipationsViewController deinit - 메모리 해제")
        cleanupHostingController()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let participationsView = MyParticipationsView(
            participations: participations,
            loadingState: loadingState,
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onParticipationTapped: { [weak self] participation in
                self?.listener?.didSelectParticipation(participation)
            }
        )
        
        let hostingController = UIHostingController(rootView: participationsView)
        self.hostingController = hostingController
        
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
    
    private func updateView() {
        guard let hostingController = hostingController else { return }
        
        let participationsView = MyParticipationsView(
            participations: participations,
            loadingState: loadingState,
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onParticipationTapped: { [weak self] participation in
                self?.listener?.didSelectParticipation(participation)
            }
        )
        
        hostingController.rootView = participationsView
    }
    
    private func cleanupHostingController() {
        guard let hostingController = hostingController else { return }
        
        print("🧹 MyParticipationsViewController - UIHostingController 정리 시작")
        
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        
        self.hostingController = nil
        
        print("✅ MyParticipationsViewController - UIHostingController 정리 완료")
    }
    
    // MARK: - MyParticipationsPresentable
    
    func showLoading() {
        self.loadingState = .loading
        updateView()
    }
    
    func hideLoading() {
        self.loadingState = .loaded
        updateView()
    }
    
    func showEmptyState() {
        self.participations = []
        self.loadingState = .loaded
        updateView()
    }
    
    func showParticipations(_ participations: [StudentParticipation]) {
        self.participations = participations
        self.loadingState = .loaded
        updateView()
    }
    
    func showError(_ message: String) {
        self.loadingState = .error(message)
        updateView()
    }
}

// MARK: - SwiftUI View

struct MyParticipationsView: View {
    let participations: [StudentParticipation]
    let loadingState: ParticipationLoadingState
    let onClose: () -> Void
    let onRefresh: () -> Void
    let onParticipationTapped: (StudentParticipation) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // 배경
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    participationsContent
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .overlay(
                // 커스텀 헤더
                VStack {
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("참여 중인 게시판")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: onRefresh) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                                .frame(width: 32, height: 32)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            )
        }
    }
    
    @ViewBuilder
    private var participationsContent: some View {
        switch loadingState {
        case .idle:
            EmptyView()
            
        case .loading:
            ParticipationsLoadingView()
            
        case .loaded:
            if participations.isEmpty {
                ParticipationsEmptyView()
            } else {
                ParticipationsList(
                    participations: participations,
                    onParticipationTapped: onParticipationTapped
                )
            }
            
        case .error(let message):
            ParticipationsErrorView(
                message: message,
                retryAction: onRefresh
            )
        }
    }
}

// MARK: - Supporting Views

enum ParticipationLoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

struct ParticipationsLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("참여 게시판을 불러오는 중...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

struct ParticipationsEmptyView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "rectangle.stack.person.crop")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                Text("참여 중인 게시판이 없어요")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("QR 코드를 스캔해서\n새로운 게시판에 참여해보세요!")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        .padding(.top, 80)
    }
}

struct ParticipationsErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 12) {
                Text("오류가 발생했습니다")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            Button(action: retryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                    Text("다시 시도")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        .padding(.top, 80)
    }
}

struct ParticipationsList: View {
    let participations: [StudentParticipation]
    let onParticipationTapped: (StudentParticipation) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(participations) { participation in
                    ParticipationCard(
                        participation: participation,
                        onTapped: {
                            onParticipationTapped(participation)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 80)
            .padding(.bottom, 40)
        }
    }
}

struct ParticipationCard: View {
    let participation: StudentParticipation
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 0) {
                cardHeader
                divider
                cardFooter
            }
        }
        .buttonStyle(.plain)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        .overlay(borderOverlay)
    }
    
    private var cardHeader: some View {
        HStack(spacing: 16) {
            boardIcon
            boardInfo
            Spacer()
            dateInfo
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var boardIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
            
            Image(systemName: "rectangle.stack.person.crop.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var boardInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(participation.boardTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            HStack(spacing: 12) {
                photoCount
                activeStatus
            }
        }
    }
    
    private var photoCount: some View {
        HStack(spacing: 4) {
            Image(systemName: "photo.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.green)
            Text("\(participation.photoCount)개")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var activeStatus: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(participation.isActive ? Color.green : Color.gray)
                .frame(width: 6, height: 6)
            Text(participation.isActive ? "활성" : "비활성")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(participation.isActive ? .green : .gray)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background((participation.isActive ? Color.green : Color.gray).opacity(0.1))
        .cornerRadius(8)
    }
    
    private var dateInfo: some View {
        VStack(spacing: 8) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(formatDate(participation.joinedAt))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.08))
            .frame(height: 1)
    }
    
    private var cardFooter: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text("참여일: \(formatSimpleDate(participation.joinedAt))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("게시판 보기")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [.green.opacity(0.2), .mint.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
    
    private func formatSimpleDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일"
        return formatter.string(from: date)
    }
}