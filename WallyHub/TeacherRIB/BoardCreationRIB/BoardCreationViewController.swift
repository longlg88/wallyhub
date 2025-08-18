import RIBs
import SwiftUI
import UIKit

final class BoardCreationViewController: UIViewController, BoardCreationPresentable, BoardCreationViewControllable {
    
    weak var listener: BoardCreationPresentableListener?
    private var hostingController: UIHostingController<BoardCreationView>?
    private var isLoading = false
    private var createdBoard: Board?
    private var error: Error?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let boardCreationView = BoardCreationView(
            isLoading: isLoading,
            createdBoard: createdBoard,
            error: error,
            onCreateBoard: { [weak self] name, description in
                self?.listener?.didTapCreateBoard(name: name, description: description)
            },
            onCancel: { [weak self] in
                self?.listener?.didTapCancel()
            }
        )
        
        let hostingController = UIHostingController(rootView: boardCreationView)
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

    // MARK: - BoardCreationPresentable

    func showLoading() {
        isLoading = true
        error = nil
        updateView()
    }
    
    func hideLoading() {
        isLoading = false
        updateView()
    }
    
    func showCreationSuccess(board: Board) {
        createdBoard = board
        error = nil
        updateView()
    }
    
    func showCreationError(_ error: Error) {
        isLoading = false
        self.error = error
        updateView()
    }
    
    private func updateView() {
        guard let hostingController = hostingController else { return }
        
        let boardCreationView = BoardCreationView(
            isLoading: isLoading,
            createdBoard: createdBoard,
            error: error,
            onCreateBoard: { [weak self] name, description in
                self?.listener?.didTapCreateBoard(name: name, description: description)
            },
            onCancel: { [weak self] in
                self?.listener?.didTapCancel()
            }
        )
        
        hostingController.rootView = boardCreationView
    }
}

// MARK: - SwiftUI View

struct BoardCreationView: View {
    let isLoading: Bool
    let createdBoard: Board?
    let error: Error?
    let onCreateBoard: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var boardName: String = ""
    @State private var boardDescription: String = ""
    @State private var selectedBackground: BoardSettings.BackgroundImage = .pastelBlue
    @State private var selectedTheme: BoardSettings.Theme = .light
    @State private var selectedFont: BoardSettings.FontFamily = .systemDefault
    @FocusState private var isNameFieldFocused: Bool
    @FocusState private var isDescriptionFieldFocused: Bool
    
    var isFormValid: Bool {
        !boardName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            if let board = createdBoard {
                BoardCreationSuccessView(board: board, onDone: onCancel)
            } else {
                boardCreationFormView
            }
        }
    }
    
    private var boardCreationFormView: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                formContentView
                errorAndLoadingSection
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("취소") {
                    onCancel()
                }
                .foregroundColor(.secondary)
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("만들기") {
                    onCreateBoard(boardName, boardDescription)
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(isFormValid ? .blue : .gray)
                .disabled(!isFormValid || isLoading)
            }
        }
        .onTapGesture {
            isNameFieldFocused = false
            isDescriptionFieldFocused = false
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "rectangle.stack.badge.plus")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 8) {
                Text("새 게시판 만들기")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("학생들이 작품을 공유할 수 있는\n특별한 공간을 설정해주세요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(.top, 20)
    }
    
    private var formContentView: some View {
        VStack(spacing: 24) {
            basicInformationSection
            backgroundSelectionSection
            themeSelectionSection
            fontSelectionSection
        }
        .padding(.horizontal, 24)
    }
    
    private var basicInformationSection: some View {
        VStack(spacing: 16) {
            WallySectionHeaderView(
                icon: "textformat.abc",
                title: "기본 정보"
            )
            
            VStack(spacing: 16) {
                boardNameInputView
                boardDescriptionInputView
            }
        }
    }
    
    private var boardNameInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("게시판 이름")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            TextField("예: \"우리반 그림 전시장\"", text: $boardName)
                .focused($isNameFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isNameFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
    
    private var boardDescriptionInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("게시판 설명")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("(선택사항)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            TextField("예: \"학생들이 그린 그림을 전시하는 공간\"", text: $boardDescription, axis: .vertical)
                .focused($isDescriptionFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .lineLimit(3...5)
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDescriptionFieldFocused ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
    }
    
    private var backgroundSelectionSection: some View {
        VStack(spacing: 16) {
            WallySectionHeaderView(
                icon: "paintpalette",
                title: "배경 디자인"
            )
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(BoardSettings.BackgroundImage.allCases, id: \.self) { background in
                    BackgroundSelectionCard(
                        background: background,
                        isSelected: selectedBackground == background,
                        onSelect: { selectedBackground = background }
                    )
                }
            }
        }
    }
    
    private var themeSelectionSection: some View {
        VStack(spacing: 16) {
            WallySectionHeaderView(
                icon: "circle.lefthalf.filled",
                title: "테마 설정"
            )
            
            HStack(spacing: 12) {
                ForEach(BoardSettings.Theme.allCases, id: \.self) { theme in
                    ThemeSelectionCard(
                        theme: theme,
                        isSelected: selectedTheme == theme,
                        onSelect: { selectedTheme = theme }
                    )
                }
            }
        }
    }
    
    private var fontSelectionSection: some View {
        VStack(spacing: 16) {
            WallySectionHeaderView(
                icon: "textformat",
                title: "폰트 설정"
            )
            
            VStack(spacing: 8) {
                ForEach(BoardSettings.FontFamily.allCases, id: \.self) { font in
                    FontSelectionCard(
                        font: font,
                        isSelected: selectedFont == font,
                        onSelect: { selectedFont = font }
                    )
                }
            }
        }
    }
    
    private var errorAndLoadingSection: some View {
        VStack(spacing: 16) {
            if let error = error {
                ModernErrorView(error: error)
                    .padding(.horizontal, 24)
            }
            
            if isLoading {
                ModernLoadingView(message: "게시판 생성 중...")
                    .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Supporting Views

struct WallySectionHeaderView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.headline)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}

struct BackgroundSelectionCard: View {
    let background: BoardSettings.BackgroundImage
    let isSelected: Bool
    let onSelect: () -> Void
    
    private var backgroundGradient: LinearGradient {
        switch background {
        case .pastelPink:
            return LinearGradient(colors: [.pink.opacity(0.3), .red.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelBlue:
            return LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelGreen:
            return LinearGradient(colors: [.green.opacity(0.3), .mint.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelYellow:
            return LinearGradient(colors: [.yellow.opacity(0.3), .orange.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelPurple:
            return LinearGradient(colors: [.purple.opacity(0.3), .blue.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelOrange:
            return LinearGradient(colors: [.orange.opacity(0.3), .yellow.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundGradient)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                
                Text(background.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeSelectionCard: View {
    let theme: BoardSettings.Theme
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Circle()
                    .fill(theme == .light ? Color.white : Color.black)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Circle()
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                
                Text(theme.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FontSelectionCard: View {
    let font: BoardSettings.FontFamily
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text("A")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .frame(width: 32)
                
                Text(font.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BoardCreationSuccessView: View {
    let board: Board
    let onDone: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.green.opacity(0.1), .mint.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            
            VStack(spacing: 16) {
                Text("게시판이 생성되었어요!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("학생들이 QR 코드를 스캔하여\n게시판에 참여할 수 있어요")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            // Board Info Card
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(board.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if !board.description.isEmpty {
                        Text(board.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack {
                        Label("QR 코드 준비됨", systemImage: "qrcode")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("생성일: \(formatDate(board.createdAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                )
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            // Done Button
            Button(action: onDone) {
                HStack {
                    Text("확인")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Image(systemName: "checkmark")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
            }
            .padding(.bottom, 34)
        }
        .navigationBarHidden(true)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

