import RIBs
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

final class TeacherViewController: UIViewController, TeacherPresentable, TeacherViewControllable {

    weak var listener: TeacherPresentableListener?
    private var currentUser: User?
    private var boardService: BoardService?
    
    func setBoardService(_ boardService: BoardService) {
        self.boardService = boardService
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func updateUser(_ user: User) {
        self.currentUser = user
        setupUI()
    }
    
    func refreshBoards() {
        // TeacherViewContent에서 loadBoards를 호출하기 위해
        // 현재는 setupUI()를 다시 호출하여 onAppear가 다시 실행되도록 함
        if currentUser != nil {
            setupUI()
        }
    }
    
    
    private func setupUI() {
        let teacherView = TeacherViewContent(
            currentUser: currentUser,
            boardService: boardService,
            onCreateBoardTapped: { [weak self] in
                self?.listener?.didTapCreateBoard()
            },
            onManageStudentsTapped: { [weak self] boardId in
                self?.listener?.didTapManageStudents(boardId: boardId)
            },
            onViewPhotosTapped: { [weak self] boardId in
                self?.listener?.didTapModeratePhotos(boardId: boardId)
            },
            onBoardSettingsTapped: { [weak self] boardId in
                self?.listener?.didTapBoardSettings(boardId: boardId)
            },
            onDeleteBoardTapped: { [weak self] boardId in
                self?.listener?.didTapDeleteBoard(boardId: boardId)
            },
            onShowQRCodeTapped: { [weak self] boardId in
                self?.listener?.didTapShowQRCode(boardId: boardId)
            },
            onRegenerateQRCodeTapped: { [weak self] boardId in
                self?.listener?.didTapRegenerateQRCode(boardId: boardId)
            },
            onSignOutTapped: { [weak self] in
                self?.listener?.didTapSignOut()
            }
        )
        
        let hostingController = UIHostingController(rootView: teacherView)
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
    
    // MARK: - TeacherViewControllable
    
    func present(viewController: ViewControllable) {
        let nav = UINavigationController(rootViewController: viewController.uiviewController)
        present(nav, animated: true)
    }
    
    func dismiss() {
        dismiss(animated: true)
    }
}

// MARK: - SwiftUI Content

struct TeacherViewContent: View {
    let currentUser: User?
    let boardService: BoardService?
    let onCreateBoardTapped: () -> Void
    let onManageStudentsTapped: (String) -> Void
    let onViewPhotosTapped: (String) -> Void
    let onBoardSettingsTapped: (String) -> Void
    let onDeleteBoardTapped: (String) -> Void
    let onShowQRCodeTapped: (String) -> Void
    let onRegenerateQRCodeTapped: (String) -> Void
    let onSignOutTapped: () -> Void
    
    @State private var boards: [BoardWithStats] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    @State private var boardToDelete: BoardWithStats?
    @State private var showQRCodeSheet = false
    @State private var qrCodeToShow: String = ""
    @State private var boardTitleForQR: String = ""
    @State private var qrCodeImage: UIImage?
    @State private var currentBoardId: String = ""
    @State private var qrCodeCache: [String: UIImage] = [:]  // QR 코드 캐시
    @State private var isDarkMode = false  // 다크 모드 상태
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    // Modern Header with Profile
                    VStack(spacing: 20) {
                        // Profile Circle with Gradient
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 8) {
                            Text("\(currentUser?.displayName ?? "교사")님, 환영합니다!")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(isDarkMode ? .white : .primary)
                            
                            Text("학생들의 창의적인 작품을 함께 만들어보세요")
                                .font(.subheadline)
                                .foregroundColor(isDarkMode ? .gray : .secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Statistics Cards (if have data)
                    if !boards.isEmpty {
                        HStack(spacing: 16) {
                            TeacherStatCard(
                                icon: "rectangle.stack.fill.badge.plus",
                                title: "총 게시판",
                                value: "\(boards.count)",
                                color: .blue
                            )
                            
                            TeacherStatCard(
                                icon: "person.2.fill",
                                title: "전체 학생",
                                value: "\(boards.reduce(0) { $0 + $1.studentCount })",
                                color: .green
                            )
                            
                            TeacherStatCard(
                                icon: "photo.fill",
                                title: "전체 사진",
                                value: "\(boards.reduce(0) { $0 + $1.photoCount })",
                                color: .orange
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Main Action - Create Board
                    VStack(spacing: 20) {
                        ModernActionCard(
                            title: "새 게시판 만들기",
                            subtitle: "학생들이 참여할 수 있는 새로운 공간을 만들어보세요",
                            icon: "plus.rectangle.fill",
                            gradientColors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                            action: onCreateBoardTapped,
                            style: .teacher
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Boards Section
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.stack.fill")
                                .foregroundColor(.blue)
                                .font(.headline)
                            Text("내 게시판")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(isDarkMode ? .white : .primary)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        if boards.isEmpty {
                            // Empty state UI 제거 - 기능은 상단 새 게시판 만들기 버튼으로 유지
                            Spacer(minLength: 100)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(boards, id: \.id) { board in
                                    ModernBoardCard(
                                        board: board,
                                        onManageStudents: { onManageStudentsTapped(board.id) },
                                        onViewPhotos: { onViewPhotosTapped(board.id) },
                                        onSettings: { onBoardSettingsTapped(board.id) },
                                        onDelete: { 
                                            boardToDelete = board
                                            showDeleteAlert = true
                                        },
                                        onShowQRCode: { 
                                            // 학생 QR 스캐너가 기대하는 형식: "wallyhub://board/{boardId}"
                                            let qrString = "wallyhub://board/\(board.id)"
                                            qrCodeToShow = qrString
                                            boardTitleForQR = board.title
                                            currentBoardId = board.id
                                            
                                            // 캐시된 QR 코드가 있는지 확인
                                            if let cachedImage = qrCodeCache[qrString] {
                                                print("📱 QR 코드 캐시 사용: \(qrString)")
                                                qrCodeImage = cachedImage
                                                showQRCodeSheet = true
                                            } else {
                                                // 캐시에 없으면 생성하고 캐시에 저장
                                                print("📱 새로운 QR 코드 생성: \(qrString)")
                                                DispatchQueue.main.async {
                                                    let newImage = generateQRCode(from: qrString)
                                                    qrCodeImage = newImage
                                                    if let image = newImage {
                                                        qrCodeCache[qrString] = image
                                                        print("✅ QR 코드 캐시에 저장: \(qrString)")
                                                    }
                                                    showQRCodeSheet = true
                                                }
                                            }
                                        },
                                        onRegenerateQRCode: { onRegenerateQRCodeTapped(board.id) }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(isDarkMode ? Color.black : Color(.systemBackground))
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .refreshable {
                await refreshBoards()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isDarkMode.toggle() }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadBoards()
            }
            .alert("게시판 삭제", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let board = boardToDelete {
                        onDeleteBoardTapped(board.id)
                        boardToDelete = nil
                    }
                }
            } message: {
                if let board = boardToDelete {
                    Text("'\(board.title)' 게시판을 삭제하시겠습니까?\n\n삭제된 게시판은 복구할 수 없으며, 게시판 내 모든 사진과 학생 데이터도 함께 삭제됩니다.")
                }
            }
            .sheet(isPresented: $showQRCodeSheet) {
                QRCodeModalView(
                    boardTitle: boardTitleForQR,
                    qrCodeImage: $qrCodeImage,
                    qrCodeString: qrCodeToShow,
                    onRegenerateQR: {
                        onRegenerateQRCodeTapped(currentBoardId)
                        // QR 코드 재생성 후 새로운 이미지 생성
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            // 캐시 무효화 (기존 QR 코드 제거)
                            let oldQRString = qrCodeToShow
                            qrCodeCache.removeValue(forKey: oldQRString)
                            print("🗑️ QR 코드 캐시 무효화: \(oldQRString)")
                            
                            // 새로운 QR 코드 URL로 업데이트 (재생성된 게시판 정보 반영)
                            let newQRString = "wallyhub://board/\(currentBoardId)"
                            qrCodeToShow = newQRString
                            let newImage = generateQRCode(from: newQRString)
                            qrCodeImage = newImage
                            
                            // 새로운 QR 코드를 캐시에 저장
                            if let image = newImage {
                                qrCodeCache[newQRString] = image
                                print("✅ 재생성된 QR 코드 캐시에 저장: \(newQRString)")
                            }
                        }
                    },
                    generateQRCode: generateQRCode
                )
            }
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
                                .fill(Color(.systemGray6))
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
    
    // MARK: - Data Loading
    
    private func loadBoards() {
        guard let boardService = boardService,
              let currentUser = currentUser else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                // 🚨 FIX: 통계를 포함한 교사의 게시판 로드
                let loadedBoards = try await boardService.getBoardsWithStatsForTeacher(teacherId: currentUser.id)
                self.boards = loadedBoards
                print("✅ 교사 게시판 (통계 포함) 로드 완료: \(loadedBoards.count)개")
            } catch {
                print("❌ 게시판 로드 실패: \(error)")
                self.errorMessage = "게시판을 불러올 수 없습니다."
                self.boards = []
            }
            
            isLoading = false
        }
    }
    
    private func refreshBoards() async {
        guard let boardService = boardService,
              let currentUser = currentUser else {
            return
        }
        
        do {
            let loadedBoards = try await boardService.getBoardsWithStatsForTeacher(teacherId: currentUser.id)
            await MainActor.run {
                self.boards = loadedBoards
                print("✅ 교사 게시판 새로고침 완료: \(loadedBoards.count)개")
            }
        } catch {
            await MainActor.run {
                print("❌ 게시판 새로고침 실패: \(error)")
                self.errorMessage = "게시판을 새로고침할 수 없습니다."
            }
        }
    }
}

// MARK: - Modern UI Components


struct TeacherStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
            }
        }
        .padding()
        .frame(width: 120)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ModernBoardCard: View {
    let board: BoardWithStats
    let onManageStudents: () -> Void
    let onViewPhotos: () -> Void
    let onSettings: () -> Void
    let onDelete: () -> Void
    let onShowQRCode: () -> Void
    let onRegenerateQRCode: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header with title and settings
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: board.isActive ? [.blue, .purple] : [.gray.opacity(0.6), .gray.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 12, height: 12)
                        }
                        
                        Text(board.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .primary)
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
                
                HStack(spacing: 8) {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                    }
                    
                    Button(action: onSettings) {
                        Image(systemName: "gearshape")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5).opacity(0.1))
                            .cornerRadius(10)
                    }
                }
            }
            
            // Stats
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("\(board.studentCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("학생")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "photo.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(board.photoCount)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("사진")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                }
            }
            
            // Quick Actions Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionButton(
                    icon: "person.2.badge.gearshape",
                    title: "학생 관리",
                    color: .blue,
                    action: onManageStudents
                )
                
                QuickActionButton(
                    icon: "photo.on.rectangle",
                    title: "사진 보기",
                    color: .green,
                    action: onViewPhotos
                )
                
                QuickActionButton(
                    icon: "qrcode",
                    title: "QR 코드 보기",
                    color: .purple,
                    action: onShowQRCode
                )
                
                QuickActionButton(
                    icon: "arrow.clockwise.circle",
                    title: "QR 재생성",
                    color: .orange,
                    action: onRegenerateQRCode
                )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.systemGray4).opacity(0.3), lineWidth: 0.5)
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.1))
                    .cornerRadius(12)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// TeacherEmptyState removed - UI 제거됨, 기능은 상단 새 게시판 만들기 버튼으로 유지

// MARK: - QR Code Generation
extension TeacherViewContent {
    /// QR 코드 이미지를 생성합니다
    /// - Parameter string: QR 코드로 변환할 문자열 (예: "wally://join/boardId_timestamp")
    /// - Returns: 생성된 QR 코드 UIImage 또는 nil
    private func generateQRCode(from string: String) -> UIImage? {
        guard !string.isEmpty else {
            print("❌ QR 코드 생성 실패: 빈 문자열")
            return nil
        }
        
        print("📱 QR 코드 생성 시작: \(string)")
        
        // 1. 문자열을 Data로 변환
        let data = string.data(using: String.Encoding.utf8)
        
        // 2. CIFilter를 사용해 QR 코드 생성
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("❌ QR 코드 생성 실패: CIQRCodeGenerator 필터를 찾을 수 없습니다")
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 높은 오류 수정 레벨
        
        // 3. CIImage 생성
        guard let ciImage = filter.outputImage else {
            print("❌ QR 코드 생성 실패: CIImage 출력이 없습니다")
            return nil
        }
        
        // 4. 고해상도로 변환 (기본 크기는 매우 작기 때문에)
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledCIImage = ciImage.transformed(by: transform)
        
        // 5. UIImage로 변환
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            print("❌ QR 코드 생성 실패: CGImage 변환 실패")
            return nil
        }
        
        let qrImage = UIImage(cgImage: cgImage)
        print("✅ QR 코드 생성 완료: \(qrImage.size)")
        
        return qrImage
    }
}

// MARK: - QR Code Modal View
struct QRCodeModalView: View {
    let boardTitle: String
    @Binding var qrCodeImage: UIImage?
    let qrCodeString: String
    let onRegenerateQR: () -> Void
    let generateQRCode: (String) -> UIImage?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isRegenerating = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "qrcode")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("QR 코드")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("'\(boardTitle)' 게시판")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Text("학생들이 카메라로 스캔하여 게시판에 참여할 수 있습니다")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
                
                // QR Code Image
                VStack(spacing: 24) {
                    if let qrImage = qrCodeImage, !isRegenerating {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 280, height: 280)
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                            .frame(width: 280, height: 280)
                            .overlay(
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text(isRegenerating ? "QR 코드 재생성 중..." : "QR 코드 생성 중...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    
                    // QR Code Text (for debugging)
                    Text(qrCodeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // 공유 버튼 (새로 추가)
                    Button {
                        shareQRCode()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .medium))
                            Text("QR 코드 공유")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: qrCodeImage == nil || isRegenerating ? 
                                        [Color.gray, Color.gray.opacity(0.8)] :
                                        [Color.green, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                    .disabled(qrCodeImage == nil || isRegenerating)
                    
                    // 기존 버튼들
                    HStack(spacing: 16) {
                        Button("QR 재생성") {
                            isRegenerating = true
                            onRegenerateQR()
                            
                            // 재생성 완료 후 상태 리셋
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                isRegenerating = false
                            }
                        }
                        .disabled(isRegenerating)
                        .foregroundColor(isRegenerating ? .gray : .orange)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isRegenerating ? Color.gray : Color.orange, lineWidth: 2)
                        )
                        
                        Button("완료") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
            .navigationTitle("QR 코드")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let qrImage = qrCodeImage {
                    ShareSheet(activityItems: createShareItems(qrImage: qrImage))
                }
            }
            .onAppear {
                // 모달이 표시될 때 QR 코드가 없으면 생성
                if qrCodeImage == nil {
                    DispatchQueue.main.async {
                        qrCodeImage = generateQRCode(qrCodeString)
                    }
                }
            }
        }
    }
    
    // MARK: - 공유 기능
    private func shareQRCode() {
        guard qrCodeImage != nil else {
            print("❌ QR 코드 공유 실패: QR 코드 이미지가 없습니다")
            return
        }
        
        print("📤 QR 코드 공유 시트 표시")
        showingShareSheet = true
    }
    
    private func createShareItems(qrImage: UIImage) -> [Any] {
        let boardName = boardTitle
        let message = "📱 '\(boardName)' 게시판에 참여해보세요!\n\nWallyHub 앱에서 이 QR 코드를 스캔하면 게시판에 바로 참여할 수 있습니다."
        
        print("📤 공유 아이템 생성:")
        print("📤 메시지: \(message)")
        print("📤 이미지 크기: \(qrImage.size)")
        print("📤 이미지 스케일: \(qrImage.scale)")
        
        var shareItems: [Any] = [message]
        
        // QR 코드 이미지를 PNG 데이터로 변환해서 더 확실하게 공유
        if let pngData = qrImage.pngData() {
            print("📤 PNG 데이터 생성 성공: \(pngData.count) bytes")
            
            // 임시 파일로 저장해서 공유 (일부 앱에서 더 잘 작동)
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("QRCode_\(boardName)")
                .appendingPathExtension("png")
            
            do {
                try pngData.write(to: tempURL)
                shareItems.append(tempURL)
                print("📤 임시 파일 저장 성공: \(tempURL)")
            } catch {
                print("❌ 임시 파일 저장 실패: \(error)")
                // 임시 파일 저장 실패 시 원본 이미지 사용
                shareItems.append(qrImage)
            }
        } else {
            print("❌ PNG 데이터 생성 실패, 원본 이미지 사용")
            shareItems.append(qrImage)
        }
        
        return shareItems
    }
}

// MARK: - 공유 시트 (UIActivityViewController 래퍼)
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        print("📤 공유할 아이템 개수: \(activityItems.count)")
        for (index, item) in activityItems.enumerated() {
            print("📤 아이템 \(index): \(type(of: item)) - \(item)")
        }
        
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // 제외할 활동 유형 설정 (선택사항)
        controller.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        // iPad에서의 표시 위치 설정
        if let popover = controller.popoverPresentationController {
            // 더 안전한 방식으로 sourceView 설정
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            } else {
                popover.sourceView = nil
            }
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}