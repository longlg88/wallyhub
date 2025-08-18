import RIBs
import SwiftUI
import UIKit

final class SystemDashboardViewController: UIViewController, SystemDashboardPresentable, SystemDashboardViewControllable {
    
    weak var listener: SystemDashboardPresentableListener?
    private var hostingController: UIHostingController<SystemDashboardView>?
    private var systemMetrics: SystemDashboardMetrics = SystemDashboardMetrics(
        totalUsers: 0,
        totalTeachers: 0,
        totalStudents: 0,
        totalBoards: 0,
        activeBoards: 0,
        totalPhotos: 0,
        photosToday: 0,
        lastDataSync: "계산 중...",
        databaseSize: "계산 중...",
        dailyActiveUsers: 0,
        weeklyActiveUsers: 0,
        monthlyActiveUsers: 0,
        serverCpuUsage: 0.0,
        serverMemoryUsage: 0.0,
        serverDiskUsage: 0.0,
        recentActivities: []
    )
    private var isLoading = false
    private var error: String?
    
    deinit {
        print("🗑️ SystemDashboardViewController deinit - 메모리 해제")
        cleanupHostingController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listener?.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("🔄 SystemDashboardViewController viewDidDisappear")
        
        // 즉시 정리 시도
        if isBeingDismissed || isMovingFromParent {
            print("🧹 SystemDashboardViewController - 즉시 정리 시작 (dismiss 또는 pop 중)")
            cleanupHostingController()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("🔄 SystemDashboardViewController viewWillDisappear")
    }
    
    private func cleanupHostingController() {
        guard let hostingController = hostingController else { return }
        
        print("🧹 SystemDashboardViewController - UIHostingController 정리 시작")
        
        // Listener 해제 (RIBs 메모리 누수 방지)
        self.listener = nil
        
        // 부모-자식 관계 정리
        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        
        // 강한 참조 해제
        self.hostingController = nil
        
        print("✅ SystemDashboardViewController - UIHostingController 정리 완료")
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let systemDashboardView = SystemDashboardView(
            metrics: systemMetrics,
            isLoading: isLoading,
            error: error,
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onExportData: { [weak self] in
                self?.listener?.didTapExportData()
            },
            onSystemSettings: { [weak self] in
                self?.listener?.didTapSystemSettings()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        let hostingController = UIHostingController(rootView: systemDashboardView)
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
        
        let systemDashboardView = SystemDashboardView(
            metrics: systemMetrics,
            isLoading: isLoading,
            error: error,
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onExportData: { [weak self] in
                self?.listener?.didTapExportData()
            },
            onSystemSettings: { [weak self] in
                self?.listener?.didTapSystemSettings()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        hostingController.rootView = systemDashboardView
    }
    
    // MARK: - SystemDashboardPresentable
    
    func updateMetrics(_ metrics: SystemDashboardMetrics) {
        self.systemMetrics = metrics
        self.error = nil
        updateView()
    }
    
    func showLoading() {
        self.isLoading = true
        self.error = nil
        updateView()
    }
    
    func hideLoading() {
        self.isLoading = false
        updateView()
    }
    
    func showError(_ message: String) {
        self.isLoading = false
        self.error = message
        updateView()
    }
}

// MARK: - Data Models
// SystemDashboardMetrics와 SystemActivity는 SystemDashboardInteractor.swift에 정의됨

// MARK: - SwiftUI View

struct SystemDashboardView: View {
    let metrics: SystemDashboardMetrics
    let isLoading: Bool
    let error: String?
    let onRefresh: () -> Void
    let onExportData: () -> Void
    let onSystemSettings: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                if isLoading {
                    ModernLoadingView(message: "시스템 정보를 불러오는 중...")
                } else if let error = error {
                    ModernErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error]))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Header Section
                            VStack(spacing: 16) {
                                // Title Header
                                VStack(spacing: 8) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(LinearGradient(
                                                    colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
                                                .frame(width: 32, height: 32)
                                            
                                            Image(systemName: "chart.bar.xaxis")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Text("시스템 대시보드")
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
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
                                    
                                    HStack {
                                        Text("실시간 시스템 상태 및 성능 모니터링")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                            
                            // System Statistics Grid
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                                SystemMetricCard(
                                    icon: "person.3.fill",
                                    title: "전체 사용자",
                                    value: "\(metrics.totalUsers)",
                                    color: .blue
                                )
                                
                                SystemMetricCard(
                                    icon: "person.badge.key.fill",
                                    title: "교사",
                                    value: "\(metrics.totalTeachers)",
                                    color: .purple
                                )
                                
                                SystemMetricCard(
                                    icon: "graduationcap.fill",
                                    title: "학생",
                                    value: "\(metrics.totalStudents)",
                                    color: .green
                                )
                                
                                SystemMetricCard(
                                    icon: "rectangle.stack.fill",
                                    title: "전체 게시판",
                                    value: "\(metrics.totalBoards)",
                                    color: .orange
                                )
                                
                                SystemMetricCard(
                                    icon: "checkmark.rectangle.fill",
                                    title: "활성 게시판",
                                    value: "\(metrics.activeBoards)",
                                    color: .mint
                                )
                                
                                SystemMetricCard(
                                    icon: "photo.fill",
                                    title: "전체 작품",
                                    value: "\(metrics.totalPhotos)",
                                    color: .pink
                                )
                            }
                            .padding(.horizontal, 24)
                            
                            // Performance Metrics
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "speedometer")
                                        .foregroundColor(.red)
                                        .font(.headline)
                                    Text("시스템 성능")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                VStack(spacing: 12) {
                                    SystemPerformanceBar(
                                        title: "Firebase 활성도",
                                        value: metrics.serverCpuUsage,
                                        color: .blue
                                    )
                                    
                                    SystemPerformanceBar(
                                        title: "데이터 분산도",
                                        value: metrics.serverMemoryUsage,
                                        color: .green
                                    )
                                    
                                    SystemPerformanceBar(
                                        title: "스토리지 사용률",
                                        value: metrics.serverDiskUsage,
                                        color: .orange
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // System Info
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.red)
                                        .font(.headline)
                                    Text("시스템 정보")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                                
                                VStack(spacing: 8) {
                                    SystemInfoRow(label: "마지막 데이터 동기화", value: metrics.lastDataSync)
                                    SystemInfoRow(label: "데이터베이스 크기", value: metrics.databaseSize)
                                    SystemInfoRow(label: "일일 활성 사용자", value: "\(metrics.dailyActiveUsers)명")
                                    SystemInfoRow(label: "주간 활성 사용자", value: "\(metrics.weeklyActiveUsers)명")
                                    SystemInfoRow(label: "월간 활성 사용자", value: "\(metrics.monthlyActiveUsers)명")
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            // Recent Activities
                            if !metrics.recentActivities.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(.red)
                                            .font(.headline)
                                        Text("최근 활동")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Spacer()
                                    }
                                    
                                    VStack(spacing: 8) {
                                        ForEach(metrics.recentActivities, id: \.id) { activity in
                                            SystemActivityRow(activity: activity)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                            
                            Spacer(minLength: 100)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        onClose()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("데이터 내보내기", action: onExportData)
                        Button("시스템 설정", action: onSystemSettings)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SystemMetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct SystemPerformanceBar: View {
    let title: String
    let value: Double
    let color: Color
    
    private var clampedPercentage: Double {
        guard value.isFinite && !value.isNaN else { return 0.0 }
        return max(0.0, min(1.0, value / 100.0))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "%.1f%%", value))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * CGFloat(clampedPercentage), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct SystemInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 2)
    }
}

struct SystemActivityRow: View {
    let activity: SystemActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
                .background(activity.type.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(activity.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}