import RIBs
import SwiftUI
import UIKit

final class MyPhotosViewController: UIViewController, MyPhotosPresentable, MyPhotosViewControllable {
    
    weak var listener: MyPhotosPresentableListener?
    private var hostingController: UIHostingController<MyPhotosView>?
    private var photos: [Photo] = []
    private var isLoading = false
    private var studentName: String = "학생"
    private var boardSettings: BoardSettings?
    private var boardTitle: String = "게시판"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let myPhotosView = MyPhotosView(
            photos: photos,
            isLoading: isLoading,
            studentName: studentName,
            boardSettings: boardSettings,
            boardTitle: boardTitle,
            onUploadPhoto: { [weak self] in
                self?.listener?.didTapUploadPhoto()
            },
            onCamera: { [weak self] in
                print("🎥 MyPhotosViewController setupUI: Camera closure called")
                self?.listener?.didTapCamera()
            },
            onGallery: { [weak self] in
                print("📱 MyPhotosViewController setupUI: Gallery closure called")
                self?.listener?.didTapGallery()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onSelectPhoto: { [weak self] photo in
                self?.listener?.didSelectPhoto(photo)
            },
            onDeletePhoto: { [weak self] photo in
                self?.listener?.didTapDeletePhoto(photo)
            },
            onDeleteSelectedPhotos: { [weak self] photos in
                self?.listener?.didTapDeleteSelectedPhotos(photos)
            }
        )
        
        let hostingController = UIHostingController(rootView: myPhotosView)
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

    // MARK: - MyPhotosPresentable

    func showPhotos(_ photos: [Photo]) {
        self.photos = photos
        updateView()
    }
    
    func showLoading() {
        isLoading = true
        updateView()
    }
    
    func hideLoading() {
        isLoading = false
        updateView()
    }
    
    func showError(_ error: Error) {
        isLoading = false
        updateView()
        
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func updateStudentName(_ name: String) {
        studentName = name
        updateView()
    }
    
    func updateBoardSettings(_ board: Board) {
        boardSettings = board.settings
        updateView()
    }
    
    func updateBoardTitle(_ title: String) {
        boardTitle = title
        updateView()
    }
    
    private func updateView() {
        guard let hostingController = hostingController else { return }
        
        let myPhotosView = MyPhotosView(
            photos: photos,
            isLoading: isLoading,
            studentName: studentName,
            boardSettings: boardSettings,
            boardTitle: boardTitle,
            onUploadPhoto: { [weak self] in
                self?.listener?.didTapUploadPhoto()
            },
            onCamera: { [weak self] in
                print("🎥 MyPhotosViewController updateView: Camera closure called")
                self?.listener?.didTapCamera()
            },
            onGallery: { [weak self] in
                print("📱 MyPhotosViewController updateView: Gallery closure called")
                self?.listener?.didTapGallery()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onRefresh: { [weak self] in
                self?.listener?.didTapRefresh()
            },
            onSelectPhoto: { [weak self] photo in
                self?.listener?.didSelectPhoto(photo)
            },
            onDeletePhoto: { [weak self] photo in
                self?.listener?.didTapDeletePhoto(photo)
            },
            onDeleteSelectedPhotos: { [weak self] photos in
                self?.listener?.didTapDeleteSelectedPhotos(photos)
            }
        )
        
        hostingController.rootView = myPhotosView
    }
    
    // MARK: - MyPhotosViewControllable
    
    func presentCamera() {
        // 🚨 이미 다른 ViewController가 present된 상태인지 확인
        if presentedViewController != nil {
            print("❌ 다른 ViewController가 표시중 - 0.5초 후 재시도")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.presentCamera() // 재귀적으로 재시도
            }
            return
        }
        
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ 카메라를 사용할 수 없습니다")
            return
        }
        
        print("📷 카메라 ImagePicker 표시")
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func presentGallery() {
        // 🚨 이미 다른 ViewController가 present된 상태인지 확인
        if presentedViewController != nil {
            print("❌ 다른 ViewController가 표시중 - 0.5초 후 재시도")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.presentGallery() // 재귀적으로 재시도
            }
            return
        }
        
        print("📱 갤러리 ImagePicker 표시")
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func dismissImagePicker() {
        dismiss(animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MyPhotosViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // 이미지 선택 완료 - PhotoUpload로 이동하거나 직접 업로드
            listener?.didSelectImageForUpload(selectedImage)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - SwiftUI View

struct MyPhotosView: View {
    let photos: [Photo]
    let isLoading: Bool
    let studentName: String
    let boardSettings: BoardSettings?
    let boardTitle: String
    let onUploadPhoto: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onClose: () -> Void
    let onRefresh: () -> Void
    let onSelectPhoto: (Photo) -> Void
    let onDeletePhoto: (Photo) -> Void
    let onDeleteSelectedPhotos: ([Photo]) -> Void
    
    @State private var showingUploadOptions = false
    @State private var isSelectionMode = false
    @State private var selectedPhotos: Set<String> = []
    @State private var showingBulkDeleteAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        boardSettings?.theme == .dark || (boardSettings?.theme != .light && colorScheme == .dark)
    }
    
    var body: some View {
        ZStack {
            // Background with gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                // Content based on state
                contentView
            }
        }
        .background(
            boardSettings?.theme == .dark ? Color.black : Color(.systemBackground)
        )
        .preferredColorScheme(
            boardSettings?.theme == .dark ? .dark : .light
        )
        .sheet(isPresented: $showingUploadOptions) {
            uploadOptionsSheet
        }
        .alert("사진 일괄 삭제", isPresented: $showingBulkDeleteAlert) {
            Button("삭제", role: .destructive) {
                let selectedPhotoObjects = photos.filter { selectedPhotos.contains($0.id) }
                onDeleteSelectedPhotos(selectedPhotoObjects)
                exitSelectionMode()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("선택된 \(selectedPhotos.count)개의 사진을 삭제하시겠습니까?\n삭제된 사진은 복구할 수 없습니다.")
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            if let boardSettings = boardSettings {
                switch boardSettings.backgroundImage {
                case .pastelBlue:
                    LinearGradient(colors: [.blue.opacity(0.1), .cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .pastelGreen:
                    LinearGradient(colors: [.green.opacity(0.1), .mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .pastelPurple:
                    LinearGradient(colors: [.purple.opacity(0.1), .pink.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .pastelOrange:
                    LinearGradient(colors: [.orange.opacity(0.1), .yellow.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .pastelPink:
                    LinearGradient(colors: [.pink.opacity(0.1), .red.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                case .pastelYellow:
                    LinearGradient(colors: [.yellow.opacity(0.1), .orange.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
                }
            } else {
                LinearGradient(
                    colors: [
                        Color.indigo.opacity(0.1),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            if isSelectionMode {
                // 선택 모드 헤더
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(selectedPhotos.count)개 선택됨")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isDarkMode ? .white : .primary)
                    
                    HStack(spacing: 16) {
                        Button(selectedPhotos.count == photos.count ? "전체 해제" : "전체 선택") {
                            if selectedPhotos.count == photos.count {
                                selectedPhotos.removeAll()
                            } else {
                                selectedPhotos = Set(photos.map { $0.id })
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        
                        Button("취소") {
                            exitSelectionMode()
                        }
                        .font(.subheadline)
                        .foregroundColor(isDarkMode ? .gray : .secondary)
                    }
                }
            } else {
                // 일반 모드 헤더
                Button(action: onClose) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                        Text("닫기")
                    }
                    .font(.headline)
                    .foregroundColor(isDarkMode ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground).opacity(0.8))
                    .cornerRadius(20)
                }
                
                Spacer()
                
                Text(boardTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isDarkMode ? .white : .primary)
            }
            
            Spacer()
            
            if isSelectionMode {
                // 선택된 사진 삭제 버튼
                Button {
                    deleteSelectedPhotos()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(18)
                }
                .disabled(selectedPhotos.isEmpty)
            } else {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                        .foregroundColor(isDarkMode ? .white : .primary)
                        .frame(width: 36, height: 36)
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(18)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            loadingView
        } else if photos.isEmpty {
            emptyStateView
        } else {
            photoGridView
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(Color.indigo.opacity(0.2), lineWidth: 6)
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .indigo))
                    .scaleEffect(1.5)
            }
            
            VStack(spacing: 8) {
                Text("사진 불러오는 중...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(isDarkMode ? .white : .primary)
                
                Text("잠시만 기다려주세요")
                    .font(.subheadline)
                    .foregroundColor(isDarkMode ? .gray : .secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                VStack(spacing: 24) {
                    // Icon with gradient circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.indigo.opacity(0.1), .purple.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 140, height: 140)
                        
                        Image(systemName: "photo.stack")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.indigo, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("아직 업로드한 사진이 없어요")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(isDarkMode ? .white : .primary)
                        
                        Text("첫 번째 사진을 업로드해서\n게시판을 채워보세요!")
                            .font(.subheadline)
                            .foregroundColor(isDarkMode ? .gray : .secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                }
                
                // Upload suggestions
                VStack(spacing: 16) {
                    HStack {
                        Text("사진 업로드 방법")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isDarkMode ? .white : .primary)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            print("🎥 Camera button tapped") // Debug log
                            onCamera()
                        }) {
                            uploadSuggestionItem(
                                icon: "camera.fill",
                                title: "카메라로 촬영",
                                description: "지금 바로 사진을 찍어보세요",
                                gradient: [.blue, .cyan]
                            )
                        }
                        .buttonStyle(InteractiveButtonStyle())
                        
                        Button(action: {
                            print("📱 Gallery button tapped") // Debug log
                            onGallery()
                        }) {
                            uploadSuggestionItem(
                                icon: "photo.on.rectangle",
                                title: "갤러리에서 선택",
                                description: "저장된 사진 중에서 골라보세요",
                                gradient: [.green, .mint]
                            )
                        }
                        .buttonStyle(InteractiveButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
                )
                
                Spacer(minLength: 60)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func uploadSuggestionItem(
        icon: String,
        title: String,
        description: String,
        gradient: [Color]
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isDarkMode ? .white : .primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(isDarkMode ? .gray : .secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Add chevron to indicate clickability
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(isDarkMode ? .gray : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle()) // Ensure entire area is tappable
    }
    
    // MARK: - Photo Grid View
    
    private var photoGridView: some View {
        ZStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Stats header
                    photoStatsHeader
                    
                    // Photo grid - 겹치지 않는 안전한 레이아웃
                    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
                    
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(photos, id: \.id) { photo in
                            EnhancedPhotoCard(
                                photo: photo,
                                isSelectionMode: isSelectionMode,
                                isSelected: selectedPhotos.contains(photo.id),
                                onTap: {
                                    if isSelectionMode {
                                        togglePhotoSelection(photo.id)
                                    } else {
                                        onSelectPhoto(photo)
                                    }
                                },
                                onDelete: {
                                    onDeletePhoto(photo)
                                },
                                onLongPress: {
                                    enterSelectionMode(with: photo.id)
                                }
                            )
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1.0, contentMode: .fit)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            
            // 플로팅 액션 버튼 (사진 추가)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button {
                        showingUploadOptions = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                            Text("사진 추가")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 34)
                }
            }
        }
    }
    
    // MARK: - Photo Stats Header
    
    private var photoStatsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("업로드한 사진")
                    .font(.subheadline)
                    .foregroundColor(isDarkMode ? .gray : .secondary)
                
                HStack(spacing: 8) {
                    Text("\(photos.count)개")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isDarkMode ? .white : .primary)
                    
                    if photos.count > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("최근 업로드")
                    .font(.subheadline)
                    .foregroundColor(isDarkMode ? .gray : .secondary)
                
                if let lastPhoto = photos.first {
                    Text(lastPhoto.uploadedAt, style: .relative)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.indigo)
                } else {
                    Text("없음")
                        .font(.caption)
                        .foregroundColor(isDarkMode ? .gray : .secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Upload Options Sheet
    
    private var uploadOptionsSheet: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 24) {
                Text("사진 업로드")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 24)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showingUploadOptions = false
                        onCamera()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("카메라로 촬영")
                                    .font(.headline)
                                    .foregroundColor(isDarkMode ? .white : .primary)
                                
                                Text("새로운 사진을 촬영합니다")
                                    .font(.caption)
                                    .foregroundColor(isDarkMode ? .gray : .secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(isDarkMode ? .gray : .secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingUploadOptions = false
                        onGallery()
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("갤러리에서 선택")
                                    .font(.headline)
                                    .foregroundColor(isDarkMode ? .white : .primary)
                                
                                Text("저장된 사진에서 선택합니다")
                                    .font(.caption)
                                    .foregroundColor(isDarkMode ? .gray : .secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(isDarkMode ? .gray : .secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("취소") {
                    showingUploadOptions = false
                }
                .font(.headline)
                .foregroundColor(isDarkMode ? .gray : .secondary)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.medium])
    }
    
    // MARK: - Selection Mode Helpers
    
    private func enterSelectionMode(with photoId: String) {
        isSelectionMode = true
        selectedPhotos.insert(photoId)
    }
    
    private func exitSelectionMode() {
        isSelectionMode = false
        selectedPhotos.removeAll()
    }
    
    private func togglePhotoSelection(_ photoId: String) {
        if selectedPhotos.contains(photoId) {
            selectedPhotos.remove(photoId)
        } else {
            selectedPhotos.insert(photoId)
        }
        
        // 선택된 사진이 없으면 선택 모드 종료
        if selectedPhotos.isEmpty {
            isSelectionMode = false
        }
    }
    
    private func deleteSelectedPhotos() {
        guard !selectedPhotos.isEmpty else { return }
        showingBulkDeleteAlert = true
    }
}

// MARK: - Interactive Button Style

struct InteractiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Photo Card

struct EnhancedPhotoCard: View {
    let photo: Photo
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onLongPress: () -> Void
    
    @State private var imageLoaded = false
    @State private var showingDeleteAlert = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        colorScheme == .dark
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Image section
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .aspectRatio(1.0, contentMode: .fit)
                
                AsyncImage(url: photo.imageUrl.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(1.0, contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    case .failure(_):
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.title2)
                                .foregroundColor(.red.opacity(0.6))
                            
                            Text("로드 실패")
                                .font(.caption2)
                                .foregroundColor(isDarkMode ? .gray : .secondary)
                        }
                    case .empty:
                        VStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("로딩중...")
                                .font(.caption2)
                                .foregroundColor(isDarkMode ? .gray : .secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Selection overlay (체크박스)
                VStack {
                    HStack {
                        if isSelectionMode {
                            // 선택 체크박스
                            Button {
                                onTap()
                            } label: {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(isSelected ? .blue : .white)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        } else {
                            // 업로드 완료 표시
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .opacity(imageLoaded ? 1.0 : 0.0)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            
            // Info section
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(photo.uploadedAt, style: .date)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isDarkMode ? .white : .primary)
                        
                        Text(photo.uploadedAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(isDarkMode ? .gray : .secondary)
                    }
                    
                    Spacer()
                    
                    // Board indicator (if available)
                    if !photo.boardId.isEmpty {
                        Image(systemName: "rectangle.stack.person.crop")
                            .font(.caption2)
                            .foregroundColor(.indigo.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                .overlay(
                    // 선택 상태 테두리
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.blue : Color.clear,
                            lineWidth: isSelected ? 2.5 : 0
                        )
                )
        )
        .scaleEffect(imageLoaded ? (isSelected ? 0.96 : 1.0) : 0.95)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: imageLoaded)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            if !isSelectionMode {
                print("🔴 길게 누르기 감지됨 - 선택 모드 진입!")
                onLongPress()
            } else {
                print("🔴 길게 누르기 감지됨 - 개별 삭제!")
                showingDeleteAlert = true
            }
        }
        .alert("사진 삭제", isPresented: $showingDeleteAlert) {
            Button("삭제", role: .destructive) {
                onDelete()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("이 사진을 삭제하시겠습니까?\n삭제된 사진은 복구할 수 없습니다.")
        }
    }
}
