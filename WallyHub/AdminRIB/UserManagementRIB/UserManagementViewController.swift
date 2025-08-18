import RIBs
import SwiftUI
import UIKit

final class UserManagementViewController: UIViewController, UserManagementPresentable, UserManagementViewControllable {
    
    weak var listener: UserManagementPresentableListener?
    private var hostingController: UIHostingController<UserManagementView>?
    private var teachers: [Teacher] = []
    private var students: [Student] = []
    private var isLoading = false
    private var error: String?
    private var searchText = ""
    private var selectedUserType: UserType = .all

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        listener?.viewDidLoad()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let userManagementView = UserManagementView(
            teachers: teachers,
            students: students,
            isLoading: isLoading,
            error: error,
            searchText: searchText,
            selectedUserType: selectedUserType,
            onSearchTextChanged: { [weak self] text in
                self?.searchText = text
                self?.updateView()
            },
            onUserTypeChanged: { [weak self] userType in
                self?.selectedUserType = userType
                self?.updateView()
            },
            onCreateTeacher: { [weak self] in
                self?.listener?.didTapCreateTeacher()
            },
            onTeacherTapped: { [weak self] teacher in
                self?.listener?.didTapTeacher(teacher)
            },
            onStudentTapped: { [weak self] student in
                self?.listener?.didTapStudent(student)
            },
            onDeleteTeacher: { [weak self] teacher in
                self?.listener?.didTapDeleteTeacher(teacher)
            },
            onDeleteStudent: { [weak self] student in
                self?.listener?.didTapDeleteStudent(student)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        let hostingController = UIHostingController(rootView: userManagementView)
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
        
        let userManagementView = UserManagementView(
            teachers: teachers,
            students: students,
            isLoading: isLoading,
            error: error,
            searchText: searchText,
            selectedUserType: selectedUserType,
            onSearchTextChanged: { [weak self] text in
                self?.searchText = text
                self?.updateView()
            },
            onUserTypeChanged: { [weak self] userType in
                self?.selectedUserType = userType
                self?.updateView()
            },
            onCreateTeacher: { [weak self] in
                self?.listener?.didTapCreateTeacher()
            },
            onTeacherTapped: { [weak self] teacher in
                self?.listener?.didTapTeacher(teacher)
            },
            onStudentTapped: { [weak self] student in
                self?.listener?.didTapStudent(student)
            },
            onDeleteTeacher: { [weak self] teacher in
                self?.listener?.didTapDeleteTeacher(teacher)
            },
            onDeleteStudent: { [weak self] student in
                self?.listener?.didTapDeleteStudent(student)
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        hostingController.rootView = userManagementView
    }
    
    // MARK: - UserManagementPresentable
    
    func showTeachers(_ teachers: [Teacher]) {
        self.teachers = teachers
        self.error = nil
        updateView()
    }
    
    func showStudents(_ students: [Student]) {
        self.students = students
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

enum UserType: String, CaseIterable {
    case all = "전체 사용자"
    case teachers = "교사"
    case students = "학생"
    case recent = "최근 가입"
    
    var icon: String {
        switch self {
        case .all: return "person.3"
        case .teachers: return "person.badge.key"
        case .students: return "graduationcap"
        case .recent: return "clock"
        }
    }
}

struct UserManagementView: View {
    let teachers: [Teacher]
    let students: [Student]
    let isLoading: Bool
    let error: String?
    let searchText: String
    let selectedUserType: UserType
    let onSearchTextChanged: (String) -> Void
    let onUserTypeChanged: (UserType) -> Void
    let onCreateTeacher: () -> Void
    let onTeacherTapped: (Teacher) -> Void
    let onStudentTapped: (Student) -> Void
    let onDeleteTeacher: (Teacher) -> Void
    let onDeleteStudent: (Student) -> Void
    let onClose: () -> Void
    
    @State private var showingDeleteAlert = false
    @State private var teacherToDelete: Teacher?
    @State private var studentToDelete: Student?
    
    private var filteredTeachers: [Teacher] {
        var filtered = teachers
        
        if !searchText.isEmpty {
            filtered = filtered.filter { teacher in
                teacher.name.lowercased().contains(searchText.lowercased()) ||
                teacher.email.lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered
    }
    
    private var filteredStudents: [Student] {
        var filtered = students
        
        if !searchText.isEmpty {
            filtered = filtered.filter { student in
                student.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        return filtered
    }
    
    private var userStatistics: (totalUsers: Int, teachers: Int, students: Int, activeUsers: Int) {
        let totalUsers = teachers.count + students.count
        let teacherCount = teachers.count
        let studentCount = students.count
        let activeUsers = teachers.filter { $0.isActive }.count + students.count // Students are always considered active
        
        return (totalUsers, teacherCount, studentCount, activeUsers)
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
                                    
                                    Image(systemName: "person.3.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text("사용자 관리")
                                    .font(.system(size: 24, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            
                            HStack {
                                Text("시스템의 모든 교사 및 학생 계정을 관리하세요")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                            }
                        }
                        
                        // Statistics Cards
                        HStack(spacing: 12) {
                            AdminUserStatCard(
                                icon: "person.3.fill",
                                title: "전체",
                                value: "\(userStatistics.totalUsers)",
                                color: .blue
                            )
                            
                            AdminUserStatCard(
                                icon: "person.badge.key.fill",
                                title: "교사",
                                value: "\(userStatistics.teachers)",
                                color: .green
                            )
                            
                            AdminUserStatCard(
                                icon: "graduationcap.fill",
                                title: "학생",
                                value: "\(userStatistics.students)",
                                color: .orange
                            )
                            
                            AdminUserStatCard(
                                icon: "person.badge.clock.fill",
                                title: "활성",
                                value: "\(userStatistics.activeUsers)",
                                color: .purple
                            )
                        }
                        
                        // Create Teacher Button
                        Button(action: onCreateTeacher) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.headline)
                                Text("새 교사 계정 생성")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    
                    // Search and Filter Section
                    VStack(spacing: 16) {
                        // Search Bar
                        AdminUserSearchBar(
                            text: searchText,
                            onTextChanged: onSearchTextChanged
                        )
                        
                        // Filter Buttons
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(UserType.allCases, id: \.self) { userType in
                                    AdminUserFilterChip(
                                        userType: userType,
                                        isSelected: selectedUserType == userType,
                                        onTap: { onUserTypeChanged(userType) }
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
                        ModernLoadingView(message: "사용자 목록을 불러오는 중...")
                        Spacer()
                    } else if let error = error {
                        Spacer()
                        ModernErrorView(error: NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: error]))
                        Spacer()
                    } else if (selectedUserType == .all && filteredTeachers.isEmpty && filteredStudents.isEmpty) ||
                              (selectedUserType == .teachers && filteredTeachers.isEmpty) ||
                              (selectedUserType == .students && filteredStudents.isEmpty) {
                        Spacer()
                        AdminUserEmptyState(hasSearch: !searchText.isEmpty, userType: selectedUserType)
                        Spacer()
                    } else {
                        // Users List
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Teachers Section
                                if selectedUserType == .all || selectedUserType == .teachers {
                                    if !filteredTeachers.isEmpty {
                                        AdminUserSectionHeader(
                                            title: "교사 계정",
                                            count: filteredTeachers.count,
                                            icon: "person.badge.key.fill",
                                            color: .green
                                        )
                                        
                                        LazyVStack(spacing: 12) {
                                            ForEach(filteredTeachers, id: \.id) { teacher in
                                                AdminTeacherCard(
                                                    teacher: teacher,
                                                    onTap: { onTeacherTapped(teacher) },
                                                    onDelete: {
                                                        teacherToDelete = teacher
                                                        showingDeleteAlert = true
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                                
                                // Students Section
                                if selectedUserType == .all || selectedUserType == .students {
                                    if !filteredStudents.isEmpty {
                                        AdminUserSectionHeader(
                                            title: "학생 계정",
                                            count: filteredStudents.count,
                                            icon: "graduationcap.fill",
                                            color: .orange
                                        )
                                        
                                        LazyVStack(spacing: 12) {
                                            ForEach(filteredStudents, id: \.id) { student in
                                                AdminStudentCard(
                                                    student: student,
                                                    onTap: { onStudentTapped(student) },
                                                    onDelete: {
                                                        studentToDelete = student
                                                        showingDeleteAlert = true
                                                    }
                                                )
                                            }
                                        }
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
            .alert("사용자 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) {
                    teacherToDelete = nil
                    studentToDelete = nil
                }
                Button("삭제", role: .destructive) {
                    if let teacher = teacherToDelete {
                        onDeleteTeacher(teacher)
                        teacherToDelete = nil
                    } else if let student = studentToDelete {
                        onDeleteStudent(student)
                        studentToDelete = nil
                    }
                }
            } message: {
                if let teacher = teacherToDelete {
                    Text("'\(teacher.name)' 교사 계정을 삭제하시겠습니까?\n관련된 모든 게시판도 함께 삭제됩니다.")
                } else if let student = studentToDelete {
                    Text("'\(student.name)' 학생을 시스템에서 완전히 삭제하시겠습니까?")
                }
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

struct AdminUserStatCard: View {
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

struct AdminUserSearchBar: View {
    let text: String
    let onTextChanged: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16))
            
            TextField("이름 또는 이메일로 검색", text: Binding(
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

struct AdminUserFilterChip: View {
    let userType: UserType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: userType.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(userType.rawValue)
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

struct AdminUserSectionHeader: View {
    let title: String
    let count: Int
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.headline)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

struct AdminTeacherCard: View {
    let teacher: Teacher
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Teacher Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.green.opacity(0.8), .mint.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Teacher Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(teacher.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if teacher.isActive {
                            Text("활성")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(3)
                        }
                    }
                    
                    Text(teacher.email)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    
                    HStack(spacing: 12) {
                        Label("\(teacher.boardCount) 게시판", systemImage: "rectangle.stack")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("생성일: \(formatDate(teacher.createdAt))", systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 8) {
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
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct AdminStudentCard: View {
    let student: Student
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                        Label("작품 수 조회중...", systemImage: "photo")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("가입: \(formatDate(student.joinedAt))", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !student.boardId.isEmpty {
                        Text("게시판 ID: \(String(student.boardId.prefix(8)))")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // Actions
                VStack(spacing: 8) {
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
    
    private var studentAvatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo]
        let index = abs(student.name.hashValue) % colors.count
        return colors[index]
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }
}

struct AdminUserEmptyState: View {
    let hasSearch: Bool
    let userType: UserType
    
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
                
                Image(systemName: hasSearch ? "magnifyingglass" : userType.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(40)
    }
    
    private var emptyStateTitle: String {
        if hasSearch {
            return "검색 결과가 없어요"
        }
        
        switch userType {
        case .all:
            return "등록된 사용자가 없어요"
        case .teachers:
            return "등록된 교사가 없어요"
        case .students:
            return "등록된 학생이 없어요"
        case .recent:
            return "최근 가입한 사용자가 없어요"
        }
    }
    
    private var emptyStateMessage: String {
        if hasSearch {
            return "다른 검색어로 다시 시도해보세요"
        }
        
        switch userType {
        case .all:
            return "새 교사 계정을 생성하거나\n학생들이 가입할 때까지 기다려주세요"
        case .teachers:
            return "새 교사 계정을 생성해주세요"
        case .students:
            return "학생들이 QR 코드로 가입할 때까지\n기다려주세요"
        case .recent:
            return "최근에 가입한 사용자가 없습니다"
        }
    }
}
