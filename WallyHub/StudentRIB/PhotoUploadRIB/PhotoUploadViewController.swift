import RIBs
import SwiftUI
import UIKit

final class PhotoUploadViewController: UIViewController, PhotoUploadPresentable, PhotoUploadViewControllable {
    
    weak var listener: PhotoUploadPresentableListener?
    private var hostingController: UIHostingController<PhotoUploadView>?
    private var selectedImage: UIImage?
    private var isUploading = false
    private var uploadSuccess = false
    private var uploadError: Error?
    private var boardSettings: BoardSettings?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let photoUploadView = PhotoUploadView(
            selectedImage: selectedImage,
            isUploading: isUploading,
            uploadSuccess: uploadSuccess,
            uploadError: uploadError,
            boardSettings: boardSettings,
            onSelectPhoto: { [weak self] in
                self?.listener?.didTapSelectPhoto()
            },
            onCamera: { [weak self] in
                self?.listener?.didTapCamera()
            },
            onGallery: { [weak self] in
                self?.listener?.didTapGallery()
            },
            onUpload: { [weak self] in
                self?.listener?.didTapUpload()
            },
            onCancel: { [weak self] in
                self?.listener?.didTapCancel()
            },
            onRetry: { [weak self] in
                self?.listener?.didTapRetry()
            }
        )
        
        let hostingController = UIHostingController(rootView: photoUploadView)
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

    // MARK: - PhotoUploadPresentable
    
    func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func showCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("❌ 카메라를 사용할 수 없습니다")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }
    
    func showGallery() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true)
    }

    func showUploadProgress() {
        isUploading = true
        uploadSuccess = false
        uploadError = nil
        updateView()
    }
    
    func hideUploadProgress() {
        isUploading = false
        updateView()
    }
    
    func showUploadSuccess() {
        uploadSuccess = true
        uploadError = nil
        updateView()
    }
    
    func showUploadError(_ error: Error) {
        isUploading = false
        uploadSuccess = false
        uploadError = error
        updateView()
    }
    
    func updateSelectedImage(_ image: UIImage) {
        selectedImage = image
        updateView()
    }
    
    func updateBoardSettings(_ board: Board) {
        boardSettings = board.settings
        updateView()
    }
    
    private func updateView() {
        guard let hostingController = hostingController else { return }
        
        let photoUploadView = PhotoUploadView(
            selectedImage: selectedImage,
            isUploading: isUploading,
            uploadSuccess: uploadSuccess,
            uploadError: uploadError,
            boardSettings: boardSettings,
            onSelectPhoto: { [weak self] in
                self?.listener?.didTapSelectPhoto()
            },
            onCamera: { [weak self] in
                self?.listener?.didTapCamera()
            },
            onGallery: { [weak self] in
                self?.listener?.didTapGallery()
            },
            onUpload: { [weak self] in
                self?.listener?.didTapUpload()
            },
            onCancel: { [weak self] in
                self?.listener?.didTapCancel()
            },
            onRetry: { [weak self] in
                self?.listener?.didTapRetry()
            }
        )
        
        hostingController.rootView = photoUploadView
    }
}

// MARK: - UIImagePickerControllerDelegate

extension PhotoUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            listener?.didSelectImage(selectedImage)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - SwiftUI View

struct PhotoUploadView: View {
    let selectedImage: UIImage?
    let isUploading: Bool
    let uploadSuccess: Bool
    let uploadError: Error?
    let boardSettings: BoardSettings?
    let onSelectPhoto: () -> Void
    let onCamera: () -> Void
    let onGallery: () -> Void
    let onUpload: () -> Void
    let onCancel: () -> Void
    let onRetry: () -> Void
    
    @State private var animateSuccess = false
    @State private var showImageOptionsSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    private var isDarkMode: Bool {
        boardSettings?.theme == .dark || (boardSettings?.theme != .light && colorScheme == .dark)
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                headerView
                
                ScrollView {
                    VStack(spacing: 32) {
                        if uploadSuccess {
                            successView
                        } else {
                            contentView
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
        }
        .onAppear {
            if uploadSuccess {
                animateSuccess = true
            }
        }
        .sheet(isPresented: $showImageOptionsSheet) {
            imageOptionsSheet
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            if uploadSuccess {
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.1),
                        Color.mint.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else if let boardSettings = boardSettings {
                boardBackgroundGradient(for: boardSettings.backgroundImage)
            } else {
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.05)
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
            Button(action: onCancel) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("취소")
                }
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemBackground).opacity(0.8))
                .cornerRadius(20)
            }
            .disabled(isUploading)
            
            Spacer()
            
            Text(uploadSuccess ? "업로드 완료" : "사진 업로드")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isDarkMode ? .white : .primary)
            
            Spacer()
            
            // Balance the header
            Color.clear
                .frame(width: 80, height: 40)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 24) {
                // Success animation with photo preview
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(animateSuccess ? 1.0 : 0.5)
                        .animation(.spring(response: 0.8, dampingFraction: 0.6), value: animateSuccess)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateSuccess ? 1.0 : 0.3)
                        .animation(.spring(response: 1.0, dampingFraction: 0.5).delay(0.2), value: animateSuccess)
                }
                
                VStack(spacing: 12) {
                    Text("사진 업로드 완료!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateSuccess)
                    
                    Text("사진이 성공적으로 게시판에 추가되었습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateSuccess)
                    
                    Text("곧 게시판으로 돌아갑니다.")
                        .font(.caption)
                        .foregroundColor(isDarkMode ? .gray.opacity(0.8) : .secondary.opacity(0.8))
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.6).delay(0.8), value: animateSuccess)
                }
            }
            
            // Show uploaded image if available
            if let image = selectedImage {
                VStack(spacing: 16) {
                    Text("업로드된 사진")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 200)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                        .opacity(animateSuccess ? 1.0 : 0.0)
                        .scaleEffect(animateSuccess ? 1.0 : 0.8)
                        .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(1.0), value: animateSuccess)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 32) {
            // Photo selection area
            photoSelectionArea
            
            // Upload progress or actions
            if isUploading {
                uploadProgressView
            } else if let error = uploadError {
                uploadErrorView(error: error)
            } else {
                actionButtonsView
            }
        }
    }
    
    // MARK: - Photo Selection Area
    
    private var photoSelectionArea: some View {
        VStack(spacing: 24) {
            if let image = selectedImage {
                // Selected image preview
                VStack(spacing: 20) {
                    Text("선택된 사진")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipped()
                            .cornerRadius(20)
                            .shadow(color: .black.opacity(0.1), radius: 12, x: 0, y: 6)
                        
                        // Change photo overlay
                        VStack {
                            Spacer()
                            
                            HStack {
                                Spacer()
                                
                                Button(action: { showImageOptionsSheet = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                        Text("변경")
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(20)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            } else {
                // Empty state - photo selection
                VStack(spacing: 24) {
                        // Icon with gradient circle
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.purple.opacity(0.2), .pink.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        VStack(spacing: 12) {
                            Text("사진 추가하기")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("카메라로 촬영하거나\n갤러리에서 선택해주세요")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                        
                        // Action buttons
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                Button(action: onCamera) {
                                    photoActionButton(
                                        title: "카메라로 촬영",
                                        icon: "camera.fill",
                                        gradient: [.blue, .cyan]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: onGallery) {
                                    photoActionButton(
                                        title: "갤러리에서 선택",
                                        icon: "photo.on.rectangle",
                                        gradient: [.green, .mint]
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 8)
                    )
            }
        }
    }
    
    private func photoActionButton(title: String, icon: String, gradient: [Color]) -> some View {
        VStack(spacing: 8) {
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
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Upload Progress View
    
    private var uploadProgressView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.purple.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                        .scaleEffect(1.5)
                }
                
                VStack(spacing: 8) {
                    Text("사진 업로드 중...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("잠시만 기다려주세요")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
        }
    }
    
    // MARK: - Upload Error View
    
    private func uploadErrorView(error: Error) -> some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("업로드 실패")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("사진 업로드 중 문제가 발생했습니다.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
            )
            
            // Retry button
            Button(action: onRetry) {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.clockwise")
                    Text("다시 시도")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.red, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        VStack(spacing: 16) {
            if selectedImage != nil {
                Button(action: onUpload) {
                    HStack(spacing: 12) {
                        Image(systemName: "icloud.and.arrow.up.fill")
                        Text("사진 업로드")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedImage != nil)
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Image Options Sheet
    
    private var imageOptionsSheet: some View {
        VStack(spacing: 0) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 4)
                .padding(.top, 8)
            
            VStack(spacing: 24) {
                Text("사진 선택")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 24)
                
                VStack(spacing: 16) {
                    Button(action: {
                        showImageOptionsSheet = false
                        onCamera()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("카메라로 촬영")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("새로운 사진을 촬영합니다")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showImageOptionsSheet = false
                        onGallery()
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("갤러리에서 선택")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("저장된 사진에서 선택합니다")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Button("취소") {
                    showImageOptionsSheet = false
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34) // Safe area bottom
        }
        .background(
            boardSettings?.theme == .dark ? Color.black : Color(.systemBackground)
        )
        .preferredColorScheme(
            boardSettings?.theme == .dark ? .dark : .light
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .presentationDetents([.medium])
    }
    
    // MARK: - Helper Methods
    
    private func boardBackgroundGradient(for backgroundImage: BoardSettings.BackgroundImage) -> LinearGradient {
        switch backgroundImage {
        case .pastelBlue:
            return LinearGradient(colors: [.blue.opacity(0.1), .cyan.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelGreen:
            return LinearGradient(colors: [.green.opacity(0.1), .mint.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelPurple:
            return LinearGradient(colors: [.purple.opacity(0.1), .pink.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelOrange:
            return LinearGradient(colors: [.orange.opacity(0.1), .yellow.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelPink:
            return LinearGradient(colors: [.pink.opacity(0.1), .red.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .pastelYellow:
            return LinearGradient(colors: [.yellow.opacity(0.1), .orange.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

