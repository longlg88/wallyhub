import RIBs
import SwiftUI
import UIKit

final class StudentManagementViewController: UIViewController, StudentManagementPresentable, StudentManagementViewControllable {
    
    weak var listener: StudentManagementPresentableListener?
    private var hostingController: UIHostingController<StudentManagementView>?
    private var students: [Student] = []
    private var studentsWithPhotoCount: [StudentWithMetadata] = []
    private var isLoading = false
    private var error: String?
    private var searchText = ""
    private var selectedFilter: StudentFilter = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listener?.viewDidLoad()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let studentManagementView = StudentManagementView(
            students: students,
            studentsWithMetadata: studentsWithPhotoCount,
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
            onStudentTapped: { [weak self] student in
                self?.listener?.didTapStudent(student)
            },
            onRemoveStudent: { [weak self] student in
                self?.listener?.didTapRemoveStudent(student)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        let hostingController = UIHostingController(rootView: studentManagementView)
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
        
        let studentManagementView = StudentManagementView(
            students: students,
            studentsWithMetadata: studentsWithPhotoCount,
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
            onStudentTapped: { [weak self] student in
                self?.listener?.didTapStudent(student)
            },
            onRemoveStudent: { [weak self] student in
                self?.listener?.didTapRemoveStudent(student)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        hostingController.rootView = studentManagementView
    }
    
    // MARK: - StudentManagementPresentable
    
    func showStudents(_ students: [Student]) {
        self.students = students
        self.error = nil
        
        // Load real photo counts for each student
        loadStudentMetadata(for: students)
        updateView()
    }
    
    private func loadStudentMetadata(for students: [Student]) {
        Task { [weak self] in
            guard let self = self else { return }
            
            var studentsWithMetadata: [StudentWithMetadata] = []
            
            for student in students {
                let photoCount = await student.getPhotoCount()
                let lastActivity = await student.getLastActivityDate()
                
                let studentWithMetadata = StudentWithMetadata(
                    student: student,
                    photoCount: photoCount,
                    lastActivityDate: lastActivity
                )
                studentsWithMetadata.append(studentWithMetadata)
            }
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.studentsWithPhotoCount = studentsWithMetadata
                self.updateView()
            }
        }
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

enum StudentFilter: String, CaseIterable {
    case all = "전체"
    case recent = "최근 가입"
    case active = "활발한 활동"
    
    var icon: String {
        switch self {
        case .all: return "person.2"
        case .recent: return "clock"
        case .active: return "star.fill"
        }
    }
}

struct StudentManagementView: View {
    let students: [Student]
    let studentsWithMetadata: [StudentWithMetadata]
    let isLoading: Bool
    let error: String?
    let searchText: String
    let selectedFilter: StudentFilter
    let onSearchTextChanged: (String) -> Void
    let onFilterChanged: (StudentFilter) -> Void
    let onStudentTapped: (Student) -> Void
    let onRemoveStudent: (Student) -> Void
    let onClose: () -> Void
    
    @State private var showingRemoveAlert = false
    @State private var studentToRemove: Student?
    
    private var filteredStudents: [Student] {
        var filtered = students
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { student in
                student.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .recent:
            filtered = filtered.sorted { $0.joinedAt > $1.joinedAt }
        case .active:
            // Sort by photo count (assuming we add this to Student model)
            break
        }
        
        return filtered
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
                                            colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "person.2.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text("학생 관리")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("게시판 참여 학생들을 관리하고 확인하세요")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        
                        // Statistics Cards
                        if !students.isEmpty {
                            HStack(spacing: 16) {
                                StudentStatCard(
                                    icon: "person.2.fill",
                                    title: "전체 학생",
                                    value: "\(students.count)",
                                    color: .blue
                                )
                                
                                StudentStatCard(
                                    icon: "photo.fill",
                                    title: "총 작품",
                                    value: "\(studentsWithMetadata.reduce(0) { $0 + $1.photoCount })",
                                    color: .green
                                )
                                
                                StudentStatCard(
                                    icon: "clock.fill",
                                    title: "최근 활동",
                                    value: recentActivityText,
                                    color: .orange
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    // Search and Filter Section
                    VStack(spacing: 16) {
                        // Search Bar
                        StudentSearchBar(
                            text: searchText,
                            onTextChanged: onSearchTextChanged
                        )
                        
                        // Filter Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(StudentFilter.allCases, id: \.self) { filter in
                                    FilterChip(
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
                        ModernLoadingView(message: "학생 목록을 불러오는 중...")
                        Spacer()
                    } else if let error = error {
                        Spacer()
                        ModernErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error]))
                        Spacer()
                    } else if filteredStudents.isEmpty {
                        Spacer()
                        StudentEmptyState(hasSearch: !searchText.isEmpty)
                        Spacer()
                    } else {
                        // Students List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredStudents, id: \.id) { student in
                                    if let metadata = studentsWithMetadata.first(where: { $0.student.id == student.id }) {
                                        StudentRowCard(
                                            student: student,
                                            photoCount: metadata.photoCount,
                                            lastActivity: metadata.lastActivityDate,
                                            onTap: { onStudentTapped(student) },
                                            onRemove: {
                                                studentToRemove = student
                                                showingRemoveAlert = true
                                            }
                                        )
                                    } else {
                                        StudentRowCard(
                                            student: student,
                                            photoCount: 0,
                                            lastActivity: student.joinedAt,
                                            onTap: { onStudentTapped(student) },
                                            onRemove: {
                                                studentToRemove = student
                                                showingRemoveAlert = true
                                            }
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("학생 제거", isPresented: $showingRemoveAlert) {
                Button("취소", role: .cancel) {
                    studentToRemove = nil
                }
                Button("제거", role: .destructive) {
                    if let student = studentToRemove {
                        onRemoveStudent(student)
                    }
                    studentToRemove = nil
                }
            } message: {
                Text("\(studentToRemove?.name ?? "")님을 게시판에서 제거하시겠습니까?")
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
    
    private var recentActivityText: String {
        guard let mostRecent = studentsWithMetadata.max(by: { $0.lastActivityDate < $1.lastActivityDate }) else {
            return "없음"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: mostRecent.lastActivityDate)
    }
}

// MARK: - Supporting Views

struct StudentStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 100)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct StudentSearchBar: View {
    let text: String
    let onTextChanged: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("학생 이름으로 검색", text: Binding(
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

struct FilterChip: View {
    let filter: StudentFilter
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
                        colors: [.blue, .purple],
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

struct StudentRowCard: View {
    let student: Student
    let photoCount: Int
    let lastActivity: Date
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Student Avatar
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                colors: [studentAvatarColor.opacity(0.8), studentAvatarColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 50, height: 50)
                        
                        Text(String(student.name.prefix(1)))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Student Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(student.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            Label("\(photoCount) 작품", systemImage: "photo")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            Label(joinDateText, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("최근 활동: \(formatDate(lastActivity))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Actions
                    VStack(spacing: 8) {
                        Button(action: onRemove) {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 20))
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
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
    
    private var studentAvatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo]
        let index = abs(student.name.hashValue) % colors.count
        return colors[index]
    }
    
    private var joinDateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd 가입"
        return formatter.string(from: student.joinedAt)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

struct StudentEmptyState: View {
    let hasSearch: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: hasSearch ? "magnifyingglass" : "person.2")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 8) {
                Text(hasSearch ? "검색 결과가 없어요" : "아직 참여한 학생이 없어요")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(hasSearch ? "다른 검색어로 다시 시도해보세요" : "학생들이 QR 코드를 스캔하여\n게시판에 참여할 때까지 기다려주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(40)
    }
}

// MARK: - Student Metadata Helper

struct StudentWithMetadata {
    let student: Student
    let photoCount: Int
    let lastActivityDate: Date
}
