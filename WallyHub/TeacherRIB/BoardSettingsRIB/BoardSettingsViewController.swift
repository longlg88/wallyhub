import RIBs
import UIKit
import SwiftUI

final class BoardSettingsViewController: UIViewController, BoardSettingsPresentable, BoardSettingsViewControllable {
    weak var listener: BoardSettingsPresentableListener?
    private var boardService: BoardService?
    private var boardId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setBoardService(_ boardService: BoardService, boardId: String) {
        self.boardService = boardService
        self.boardId = boardId
        setupUI()
    }
    
    private func setupUI() {
        // Clear previous content
        view.subviews.forEach { $0.removeFromSuperview() }
        children.forEach { child in
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        
        guard let boardService = boardService,
              let boardId = boardId else {
            return
        }
        
        let settingsView = BoardSettingsViewContent(
            boardId: boardId,
            boardService: boardService,
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            }
        )
        
        let hostingController = UIHostingController(rootView: settingsView)
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
}

// MARK: - SwiftUI Content

struct BoardSettingsViewContent: View {
    let boardId: String
    let boardService: BoardService
    let onClose: () -> Void
    
    @State private var board: Board?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isSaving = false
    @State private var showSuccessAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("게시판 설정 로딩 중...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text("오류 발생")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("다시 시도") {
                            loadBoard()
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding()
                } else if let board = board {
                    BoardSettingsForm(
                        board: board,
                        isSaving: $isSaving,
                        onSave: { updatedBoard in
                            saveBoard(updatedBoard)
                        }
                    )
                }
            }
            .navigationTitle("게시판 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        onClose()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("저장 완료", isPresented: $showSuccessAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("게시판 설정이 성공적으로 저장되었습니다.")
        }
        .onAppear {
            loadBoard()
        }
    }
    
    private func loadBoard() {
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                let loadedBoard = try await boardService.getBoard(id: boardId)
                self.board = loadedBoard
            } catch {
                print("❌ 게시판 로드 실패: \(error)")
                self.errorMessage = "게시판 정보를 불러올 수 없습니다."
            }
            isLoading = false
        }
    }
    
    private func saveBoard(_ updatedBoard: Board) {
        isSaving = true
        
        Task { @MainActor in
            do {
                try await boardService.updateBoard(updatedBoard)
                showSuccessAlert = true
                print("✅ 게시판 설정 저장 완료")
            } catch {
                print("❌ 게시판 설정 저장 실패: \(error)")
                errorMessage = "설정을 저장할 수 없습니다."
            }
            isSaving = false
        }
    }
}

struct BoardSettingsForm: View {
    @State private var board: Board
    @Binding var isSaving: Bool
    let onSave: (Board) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(board: Board, isSaving: Binding<Bool>, onSave: @escaping (Board) -> Void) {
        self._board = State(initialValue: board)
        self._isSaving = isSaving
        self.onSave = onSave
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 게시판 정보 섹션
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("게시판 정보")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("제목:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(board.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("생성일:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(board.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("상태:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(board.isActive ? "활성" : "비활성")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(board.isActive ? .green : .red)
                        }
                    }
                    .padding(16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // 배경 이미지 설정
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .foregroundColor(.purple)
                        Text("배경 테마")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(BoardSettings.BackgroundImage.allCases, id: \.self) { bgImage in
                            BackgroundImageOption(
                                backgroundImage: bgImage,
                                isSelected: board.settings.backgroundImage == bgImage
                            ) {
                                board.settings.backgroundImage = bgImage
                            }
                        }
                    }
                }
                
                // 테마 설정
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "paintpalette.fill")
                            .foregroundColor(.orange)
                        Text("테마")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(BoardSettings.Theme.allCases, id: \.self) { theme in
                            ThemeOption(
                                theme: theme,
                                isSelected: board.settings.theme == theme
                            ) {
                                board.settings.theme = theme
                            }
                        }
                    }
                }
                
                // 폰트 설정
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "textformat")
                            .foregroundColor(.green)
                        Text("폰트")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(BoardSettings.FontFamily.allCases, id: \.self) { fontFamily in
                            FontFamilyOption(
                                fontFamily: fontFamily,
                                isSelected: board.settings.fontFamily == fontFamily
                            ) {
                                board.settings.fontFamily = fontFamily
                            }
                        }
                    }
                }
                
                // 새 게시물 위치 설정
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "plus.square.fill")
                            .foregroundColor(.red)
                        Text("새 게시물 위치")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(BoardSettings.NewPostPosition.allCases, id: \.self) { position in
                            PostPositionOption(
                                position: position,
                                isSelected: board.settings.newPostPosition == position
                            ) {
                                board.settings.newPostPosition = position
                            }
                        }
                    }
                }
                
                // 저장 버튼
                Button(action: { onSave(board) }) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        Text(isSaving ? "저장 중..." : "설정 저장")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isSaving ? [.gray] : [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                
                Spacer(minLength: 50)
            }
            .padding(24)
        }
        .background(colorScheme == .dark ? Color.black : Color(.systemBackground))
    }
}

// MARK: - Option Components

struct BackgroundImageOption: View {
    let backgroundImage: BoardSettings.BackgroundImage
    let isSelected: Bool
    let onTap: () -> Void
    
    var backgroundColor: Color {
        switch backgroundImage {
        case .pastelPink: return Color.pink.opacity(0.3)
        case .pastelBlue: return Color.blue.opacity(0.3)
        case .pastelGreen: return Color.green.opacity(0.3)
        case .pastelYellow: return Color.yellow.opacity(0.3)
        case .pastelPurple: return Color.purple.opacity(0.3)
        case .pastelOrange: return Color.orange.opacity(0.3)
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        isSelected ?
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        : nil
                    )
                
                Text(backgroundImage.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeOption: View {
    let theme: BoardSettings.Theme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: theme == .light ? "sun.max.fill" : "moon.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(theme.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FontFamilyOption: View {
    let fontFamily: BoardSettings.FontFamily
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
                
                Text(fontFamily.displayName)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PostPositionOption: View {
    let position: BoardSettings.NewPostPosition
    let isSelected: Bool
    let onTap: () -> Void
    
    var iconName: String {
        switch position {
        case .topLeft: return "arrow.up.left.square.fill"
        case .topRight: return "arrow.up.right.square.fill"
        case .center: return "square.grid.3x3.middle.filled"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(position.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .medium)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}