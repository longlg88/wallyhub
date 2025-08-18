import RIBs
import SwiftUI
import UIKit

final class AllBoardsManagementViewController: UIViewController, AllBoardsManagementPresentable, AllBoardsManagementViewControllable {
    
    weak var listener: AllBoardsManagementPresentableListener?
    private var hostingController: UIHostingController<AllBoardsManagementView>?
    private var boardsWithTeacher: [BoardWithTeacher] = []
    private var boardsWithStats: [BoardWithStats] = []
    private var isLoading = false
    private var error: String?
    private var searchText = ""
    private var selectedFilter: BoardFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listener?.viewDidLoad()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let allBoardsView = AllBoardsManagementView(
            boardsWithTeacher: boardsWithTeacher,
            boardsWithStats: boardsWithStats,
            isLoading: isLoading,
            error: error,
            searchText: searchText,
            selectedFilter: selectedFilter,
            onSearchTextChanged: { [weak self] text in
                self?.searchText = text
                self?.updateView()
            },
            onFilterChanged: { [weak self] filter in
                self?.selectedFilter = filter
                self?.updateView()
            },
            onBoardTapped: { [weak self] board in
                self?.listener?.didTapBoard(board)
            },
            onToggleBoardStatus: { [weak self] board in
                self?.listener?.didTapToggleBoardStatus(board)
            },
            onDeleteBoard: { [weak self] board in
                self?.listener?.didTapDeleteBoard(board)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        let hostingController = UIHostingController(rootView: allBoardsView)
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
        
        let allBoardsView = AllBoardsManagementView(
            boardsWithTeacher: boardsWithTeacher,
            boardsWithStats: boardsWithStats,
            isLoading: isLoading,
            error: error,
            searchText: searchText,
            selectedFilter: selectedFilter,
            onSearchTextChanged: { [weak self] text in
                self?.searchText = text
                self?.updateView()
            },
            onFilterChanged: { [weak self] filter in
                self?.selectedFilter = filter
                self?.updateView()
            },
            onBoardTapped: { [weak self] board in
                self?.listener?.didTapBoard(board)
            },
            onToggleBoardStatus: { [weak self] board in
                self?.listener?.didTapToggleBoardStatus(board)
            },
            onDeleteBoard: { [weak self] board in
                self?.listener?.didTapDeleteBoard(board)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        hostingController.rootView = allBoardsView
    }
    
    // MARK: - AllBoardsManagementPresentable
    
    func showBoards(_ boards: [BoardWithTeacher]) {
        self.boardsWithTeacher = boards
        self.error = nil
        updateView()
    }
    
    func showBoardsWithStats(_ boards: [BoardWithStats]) {
        self.boardsWithStats = boards
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

// MARK: - SwiftUI View

enum BoardFilter: String, CaseIterable {
    case all = "전체"
    case active = "활성"
    case inactive = "비활성"
    case recent = "최근 생성"
    
    var icon: String {
        switch self {
        case .all: return "rectangle.stack"
        case .active: return "checkmark.circle.fill"
        case .inactive: return "xmark.circle.fill"
        case .recent: return "clock"
        }
    }
}

struct AllBoardsManagementView: View {
    let boardsWithTeacher: [BoardWithTeacher]
    let boardsWithStats: [BoardWithStats]
    let isLoading: Bool
    let error: String?
    let searchText: String
    let selectedFilter: BoardFilter
    let onSearchTextChanged: (String) -> Void
    let onFilterChanged: (BoardFilter) -> Void
    let onBoardTapped: (Board) -> Void
    let onToggleBoardStatus: (Board) -> Void
    let onDeleteBoard: (Board) -> Void
    let onClose: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var boardToDelete: Board?
    @State private var showingStatusAlert = false
    @State private var boardToToggle: Board?
    
    // Use stats data if available, otherwise fall back to teacher data
    private var filteredBoards: [BoardWithStats] {
        // Convert BoardWithTeacher to BoardWithStats if needed
        let allBoards: [BoardWithStats]
        if !boardsWithStats.isEmpty {
            allBoards = boardsWithStats
        } else {
            allBoards = boardsWithTeacher.map { teacher in
                BoardWithStats(
                    board: teacher.board,
                    studentCount: 0,
                    photoCount: 0,
                    teacherName: teacher.teacherName
                )
            }
        }
        
        var filtered = allBoards
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { boardWithStats in
                boardWithStats.board.title.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.board.isActive }
        case .inactive:
            filtered = filtered.filter { !$0.board.isActive }
        case .recent:
            filtered = filtered.sorted { $0.board.createdAt > $1.board.createdAt }
        }
        
        return filtered
    }
    
    private var boardStatistics: (total: Int, active: Int, inactive: Int, students: Int) {
        let total = boardsWithTeacher.count
        let active = boardsWithTeacher.filter { $0.board.isActive }.count
        let inactive = boardsWithTeacher.filter { !$0.board.isActive }.count
        let students = 0 // TODO: Implement actual student count calculation
        
        return (total, active, inactive, students)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Section
                    VStack(spacing: 20) {
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
                                    
                                    Image(systemName: "rectangle.stack.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text("전체 게시판 관리")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("시스템의 모든 게시판을 관리하고 모니터링하세요")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        
                        // Statistics Cards
                        if !boardsWithTeacher.isEmpty {
                            HStack(spacing: 12) {
                                AdminBoardStatCard(
                                    icon: "rectangle.stack.fill",
                                    title: "전체",
                                    value: "\(boardStatistics.total)",
                                    color: .blue
                                )
                                
                                AdminBoardStatCard(
                                    icon: "checkmark.circle.fill",
                                    title: "활성",
                                    value: "\(boardStatistics.active)",
                                    color: .green
                                )
                                
                                AdminBoardStatCard(
                                    icon: "xmark.circle.fill",
                                    title: "비활성",
                                    value: "\(boardStatistics.inactive)",
                                    color: .orange
                                )
                                
                                AdminBoardStatCard(
                                    icon: "person.2.fill",
                                    title: "총 학생",
                                    value: "\(boardStatistics.students)",
                                    color: .purple
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    // Search and Filter Section
                    VStack(spacing: 16) {
                        // Search Bar
                        AdminBoardSearchBar(
                            text: searchText,
                            onTextChanged: onSearchTextChanged
                        )
                        
                        // Filter Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(BoardFilter.allCases, id: \.self) { filter in
                                    AdminFilterChip(
                                        filter: filter,
                                        isSelected: selectedFilter == filter,
                                        onTap: { onFilterChanged(filter) }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Content Section
                    if isLoading {
                        Spacer()
                        ModernLoadingView(message: "게시판 목록을 불러오는 중...")
                        Spacer()
                    } else if let error = error {
                        Spacer()
                        ModernErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error]))
                        Spacer()
                    } else if filteredBoards.isEmpty {
                        Spacer()
                        AdminBoardEmptyState(hasSearch: !searchText.isEmpty)
                        Spacer()
                    } else {
                        // Boards List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredBoards, id: \.board.id) { boardWithStats in
                                    AdminBoardCard(
                                        boardWithTeacher: nil,
                                        boardWithStats: boardWithStats,
                                        onTap: { onBoardTapped(boardWithStats.board) },
                                        onToggleStatus: {
                                            boardToToggle = boardWithStats.board
                                            showingStatusAlert = true
                                        },
                                        onDelete: {
                                            boardToDelete = boardWithStats.board
                                            showingDeleteAlert = true
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("게시판 상태 변경", isPresented: $showingStatusAlert) {
                Button("취소", role: .cancel) {
                    boardToToggle = nil
                }
                Button(boardToToggle?.isActive == true ? "비활성화" : "활성화") {
                    if let board = boardToToggle {
                        onToggleBoardStatus(board)
                    }
                    boardToToggle = nil
                }
            } message: {
                if let board = boardToToggle {
                    Text("'\(board.title)' 게시판을 \(board.isActive ? "비활성화" : "활성화")하시겠습니까?")
                }
            }
            .alert("게시판 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {
                    boardToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let board = boardToDelete {
                        onDeleteBoard(board)
                    }
                    boardToDelete = nil
                }
            } message: {
                Text("'\(boardToDelete?.title ?? "")' 게시판을 완전히 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.")
            }
            .overlay(
                // Close Button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 32, height: 32)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            )
        }
    }
}

// MARK: - Supporting Views

struct AdminBoardStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .frame(width: 80)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AdminBoardSearchBar: View {
    let text: String
    let onTextChanged: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("게시판 이름으로 검색", text: Binding(
                get: { text },
                set: { onTextChanged($0) }
            ))
            .textFieldStyle(PlainTextFieldStyle())
            .font(.subheadline)
            
            if !text.isEmpty {
                Button(action: { onTextChanged("") }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 24)
    }
}

struct AdminFilterChip: View {
    let filter: BoardFilter
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) : LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AdminBoardCard: View {
    let boardWithTeacher: BoardWithTeacher?
    let boardWithStats: BoardWithStats?
    let onTap: () -> Void
    let onToggleStatus: () -> Void
    let onDelete: () -> Void
    
    // Computed properties for backward compatibility
    private var board: Board {
        if let stats = boardWithStats {
            return stats.board
        } else if let teacher = boardWithTeacher {
            return teacher.board
        } else {
            fatalError("Either boardWithStats or boardWithTeacher must be provided")
        }
    }
    
    private var teacherName: String {
        if let stats = boardWithStats {
            return stats.teacherName ?? "알 수 없음"
        } else if let teacher = boardWithTeacher {
            return teacher.teacherName
        } else {
            return "알 수 없음"
        }
    }
    
    private var studentCount: Int {
        return boardWithStats?.studentCount ?? 0
    }
    
    private var photoCount: Int {
        return boardWithStats?.photoCount ?? 0
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: board.isActive ? [.green, .mint] : [.gray.opacity(0.6), .gray.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 12, height: 12)
                            }
                            
                            Text(board.title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        Text(board.isActive ? "활성 게시판" : "비활성 게시판")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(board.isActive ? Color.green.opacity(0.15) : Color.gray.opacity(0.15))
                            .foregroundColor(board.isActive ? .green : .gray)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text(formatDate(board.createdAt))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("교사: \(teacherName)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                // Stats and Actions
                HStack {
                    HStack(spacing: 16) {
                        Label("\(studentCount)", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Label("\(photoCount)", systemImage: "photo.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: onToggleStatus) {
                            Image(systemName: board.isActive ? "pause.circle" : "play.circle")
                                .font(.system(size: 20))
                                .foregroundColor(board.isActive ? .orange : .green)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray5).opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct AdminBoardEmptyState: View {
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.red.opacity(0.1), .orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasSearch ? "magnifyingglass" : "rectangle.stack")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 8) {
                Text(hasSearch ? "검색 결과가 없어요" : "생성된 게시판이 없어요")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(hasSearch ? "다른 검색어로 다시 시도해보세요" : "교사들이 게시판을 생성할 때까지\n기다려주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(40)
    }
}