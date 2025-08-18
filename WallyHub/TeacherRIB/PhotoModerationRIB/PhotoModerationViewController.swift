import RIBs
import SwiftUI
import UIKit
import Foundation

final class PhotoModerationViewController: UIViewController, PhotoModerationPresentable, PhotoModerationViewControllable {

    weak var listener: PhotoModerationPresentableListener?
    private var hostingController: UIHostingController<PhotoGalleryView>?
    private var photos: [Photo] = []
    private var photoViewStatuses: [String: PhotoViewStatus] = [:]
    private var boardTitle: String = ""
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        let photoGalleryView = PhotoGalleryView(
            photos: photos,
            photoViewStatuses: photoViewStatuses,
            boardTitle: boardTitle,
            isLoading: isLoading,
            onRefresh: { [weak self] in
                self?.listener?.didRequestLoadPhotos()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onDeletePhoto: { [weak self] photo in
                self?.listener?.didTapDeletePhoto(photo)
            },
            onDeleteSelectedPhotos: { [weak self] photos in
                self?.listener?.didTapDeleteSelectedPhotos(photos)
            },
            onViewPhoto: { [weak self] photo, duration in
                self?.listener?.didViewPhoto(photo, sessionDuration: duration)
            },
            onMarkPhotosAsViewed: { [weak self] photoIds in
                self?.listener?.didRequestMarkPhotosAsViewed(photoIds)
            }
        )
        
        let hostingController = UIHostingController(rootView: photoGalleryView)
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

    // MARK: - PhotoModerationPresentable

    func showPhotos(_ photos: [Photo]) {
        self.photos = photos
        updateView()
    }
    
    func showPhotoViewStatuses(_ statuses: [String: PhotoViewStatus]) {
        self.photoViewStatuses = statuses
        updateView()
    }
    
    func showBoardTitle(_ title: String) {
        self.boardTitle = title
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
    
    private func updateView() {
        guard let hostingController = hostingController else { return }
        
        let photoGalleryView = PhotoGalleryView(
            photos: photos,
            photoViewStatuses: photoViewStatuses,
            boardTitle: boardTitle,
            isLoading: isLoading,
            onRefresh: { [weak self] in
                self?.listener?.didRequestLoadPhotos()
            },
            onClose: { [weak self] in
                self?.listener?.didTapClose()
            },
            onDeletePhoto: { [weak self] photo in
                self?.listener?.didTapDeletePhoto(photo)
            },
            onDeleteSelectedPhotos: { [weak self] photos in
                self?.listener?.didTapDeleteSelectedPhotos(photos)
            },
            onViewPhoto: { [weak self] photo, duration in
                self?.listener?.didViewPhoto(photo, sessionDuration: duration)
            },
            onMarkPhotosAsViewed: { [weak self] photoIds in
                self?.listener?.didRequestMarkPhotosAsViewed(photoIds)
            }
        )
        
        hostingController.rootView = photoGalleryView
    }
}

// MARK: - SwiftUI Views

struct PhotoGalleryView: View {
    let photos: [Photo]
    let photoViewStatuses: [String: PhotoViewStatus]
    let boardTitle: String
    let isLoading: Bool
    let onRefresh: () -> Void
    let onClose: () -> Void
    let onDeletePhoto: (Photo) -> Void
    let onDeleteSelectedPhotos: ([Photo]) -> Void
    let onViewPhoto: (Photo, TimeInterval?) -> Void
    let onMarkPhotosAsViewed: ([String]) -> Void
    
    @State private var selectedPhoto: Photo?
    @State private var columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    @State private var isSelectionMode = false
    @State private var selectedPhotos: Set<String> = []
    @State private var showingBulkDeleteAlert = false
    @State private var currentFilter = PhotoFilterType.all
    @State private var showingMarkAsViewedAlert = false
    
    var body: some View {
        NavigationView {
            mainContent
        }
        .fullScreenCover(item: $selectedPhoto) { photo in
            photoDetailView(for: photo)
        }
        .alert("사진 일괄 삭제", isPresented: $showingBulkDeleteAlert) {
            bulkDeleteAlert
        } message: {
            Text("선택된 \(selectedPhotos.count)개의 사진을 삭제하시겠습니까?\n삭제된 사진은 복구할 수 없습니다.")
        }
        .alert("사진 일괄 확인", isPresented: $showingMarkAsViewedAlert) {
            markAsViewedAlert
        } message: {
            Text("미확인 사진 \(unviewedPhotos.count)개를 모두 '확인됨'으로 처리하시겠습니까?")
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            modernHeader
            
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                contentView
            }
        }
        .navigationBarHidden(true)
    }
    
    private var navigationTitleText: String {
        isSelectionMode ? "\(selectedPhotos.count)개 선택됨" : navigationTitle
    }
    
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
    
    @ViewBuilder
    private var loadingView: some View {
        ProgressView("사진 로딩중...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("업로드된 사진이 없습니다")
                .font(.title2)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var photoGridView: some View {
        VStack(spacing: 0) {
            PhotoStatusFilter(
                selectedFilter: $currentFilter,
                unviewedCount: unviewedPhotos.count,
                totalCount: filteredPhotos.count
            )
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(filteredPhotos, id: \.id) { photo in
                        photoGridItem(for: photo)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
    }
    
    @ViewBuilder
    private func photoGridItem(for photo: Photo) -> some View {
        ZStack {
            PhotoCard(
                photo: photo,
                isSelectionMode: isSelectionMode,
                isSelected: selectedPhotos.contains(photo.id),
                onTap: {
                    if isSelectionMode {
                        togglePhotoSelection(photo.id)
                    } else {
                        selectedPhoto = photo
                    }
                },
                onLongPress: {
                    enterSelectionMode(with: photo.id)
                },
                onDelete: {
                    onDeletePhoto(photo)
                }
            )
            
            PhotoThumbnailOverlay(
                photo: photo,
                viewStatus: photoViewStatuses[photo.id]
            )
        }
    }
    
    @ViewBuilder
    private var modernHeader: some View {
        VStack(spacing: 0) {
            // Status bar background
            Color.clear
                .frame(height: 0)
                .background(.ultraThinMaterial)
            
            // Main header content
            HStack(spacing: 16) {
                // Leading: Close button with modern design
                Button(action: {
                    if isSelectionMode {
                        exitSelectionMode()
                    } else {
                        onClose()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: isSelectionMode ? "xmark" : "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        if !isSelectionMode {
                            Text("갤러리")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Spacer()
                
                // Center: Title with photo count
                VStack(spacing: 2) {
                    if isSelectionMode {
                        Text("\(selectedPhotos.count)개 선택됨")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.stack.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.blue)
                            
                            Text("\(photos.count)개")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                        }
                        
                        if !unviewedPhotos.isEmpty {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(.orange)
                                    .frame(width: 6, height: 6)
                                
                                Text("미확인 \(unviewedPhotos.count)개")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Trailing: Action buttons
                HStack(spacing: 8) {
                    if isSelectionMode {
                        selectionModeActions
                    } else {
                        normalModeActions
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }
    
    @ViewBuilder
    private var selectionModeActions: some View {
        // Select all/none button
        Button(action: {
            if selectedPhotos.count == photos.count {
                selectedPhotos.removeAll()
            } else {
                selectedPhotos = Set(photos.map { $0.id })
            }
        }) {
            Image(systemName: selectedPhotos.count == photos.count ? "checkmark.circle" : "circle.dashed")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue.opacity(0.1))
                )
        }
        
        // Delete button
        Button(action: deleteSelectedPhotos) {
            Image(systemName: "trash.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedPhotos.isEmpty ? .gray : .red)
                )
        }
        .disabled(selectedPhotos.isEmpty)
    }
    
    @ViewBuilder
    private var normalModeActions: some View {
        // Batch confirm button
        if !unviewedPhotos.isEmpty {
            Button(action: {
                showingMarkAsViewedAlert = true
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("일괄확인")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.blue)
                )
            }
        }
        
        // Refresh button
        Button(action: onRefresh) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.blue.opacity(0.1))
                )
        }
    }
    
    @ViewBuilder
    private var bulkDeleteAlert: some View {
        Button("삭제", role: .destructive) {
            let selectedPhotoObjects = photos.filter { selectedPhotos.contains($0.id) }
            onDeleteSelectedPhotos(selectedPhotoObjects)
            exitSelectionMode()
        }
        Button("취소", role: .cancel) { }
    }
    
    @ViewBuilder
    private var markAsViewedAlert: some View {
        Button("확인 처리") {
            let unviewedPhotoIds = unviewedPhotos.map { $0.id }
            onMarkPhotosAsViewed(unviewedPhotoIds)
        }
        Button("취소", role: .cancel) { }
    }
    
    @ViewBuilder
    private func photoDetailView(for photo: Photo) -> some View {
        if let currentIndex = photos.firstIndex(where: { $0.id == photo.id }) {
            PhotoDetailViewWithTracking(
                photos: photos,
                photoViewStatuses: photoViewStatuses,
                initialIndex: currentIndex,
                onViewPhoto: onViewPhoto
            ) {
                selectedPhoto = nil
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPhotos: [Photo] {
        switch currentFilter {
        case .all:
            return photos
        case .unviewed:
            return unviewedPhotos
        case .viewed:
            return viewedPhotos
        }
    }
    
    private var unviewedPhotos: [Photo] {
        return photos.filter { photo in
            guard let status = photoViewStatuses[photo.id] else { return true }
            return !status.isViewed
        }
    }
    
    private var viewedPhotos: [Photo] {
        return photos.filter { photo in
            guard let status = photoViewStatuses[photo.id] else { return false }
            return status.isViewed
        }
    }
    
    private var navigationTitle: String {
        let totalCount = photos.count
        let unviewedCount = unviewedPhotos.count
        
        if unviewedCount > 0 {
            return "사진 갤러리 (\(totalCount)개) - 미확인 \(unviewedCount)개"
        } else {
            return "사진 갤러리 (\(totalCount)개)"
        }
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

struct PhotoCard: View {
    let photo: Photo
    let isSelectionMode: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDelete: () -> Void
    
    @State private var studentName: String = "로딩중..."
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Photo thumbnail with modern design
            ZStack {
                if let imageUrl = photo.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(1.2, contentMode: .fill)  // 더 세로로 긴 비율
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .aspectRatio(1.2, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.blue)
                                    Text("로딩중...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            )
                    }
                    .clipped()
                } else {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .aspectRatio(1.2, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                                Text("이미지 없음")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
                
                // Selection overlay with improved design
                if isSelectionMode {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onTap) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.6))
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundColor(isSelected ? .blue : .white)
                                }
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
            }
            .cornerRadius(16)  // 둥근 모서리 추가
            
            // Photo info with modern card design  
            VStack(alignment: .leading, spacing: 8) {
                // Title with better typography
                if !photo.title.isEmpty {
                    Text(photo.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                
                // Student info with improved design
                HStack(spacing: 6) {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue.opacity(0.8), .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                    
                    Text(studentName)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                    
                    Spacer(minLength: 0)
                    
                    // Upload time badge
                    Text(photo.uploadedAt, style: .relative)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? 
                                LinearGradient(colors: [.blue, .blue.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: isSelected ? 3 : 0
                        )
                )
        )
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.6) {
            if !isSelectionMode {
                print("🔴 Teacher PhotoCard: 길게 누르기 감지됨 - 선택 모드 진입!")
                onLongPress()
            } else {
                print("🔴 Teacher PhotoCard: 길게 누르기 감지됨 - 개별 삭제!")
                showingDeleteAlert = true
            }
        }
        .onAppear {
            loadStudentName()
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
    
    private func loadStudentName() {
        Task {
            do {
                let studentService = ServiceFactory.shared.studentService
                let students = try await studentService.getStudentsForBoard(boardId: photo.boardId)
                
                if let student = students.first(where: { $0.studentId == photo.studentId }) {
                    await MainActor.run {
                        self.studentName = student.name
                    }
                } else {
                    await MainActor.run {
                        self.studentName = "알 수 없음"
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.studentName = "오류"
                }
            }
        }
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photos: [Photo]
    let photoViewStatuses: [String: PhotoViewStatus]
    let initialIndex: Int
    let onViewPhoto: (Photo, TimeInterval?) -> Void
    let onClose: () -> Void
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var preloadedImages: [String: UIImage] = [:]
    @State private var hasTrackedView = false
    
    init(
        photos: [Photo], 
        photoViewStatuses: [String: PhotoViewStatus],
        initialIndex: Int, 
        onViewPhoto: @escaping (Photo, TimeInterval?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.photos = photos
        self.photoViewStatuses = photoViewStatuses
        self.initialIndex = initialIndex
        self.onViewPhoto = onViewPhoto
        self.onClose = onClose
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    private var currentPhoto: Photo {
        if currentIndex >= 0 && currentIndex < photos.count {
            return photos[currentIndex]
        }
        return photos[0]
    }
    
    private func markPhotoAsViewed() {
        if !hasTrackedView && !isPhotoAlreadyViewed {
            onViewPhoto(currentPhoto, nil)
            hasTrackedView = true
            print("✅ 수동 확인: \(currentPhoto.id)")
        }
    }
    
    private var isPhotoAlreadyViewed: Bool {
        guard let status = photoViewStatuses[currentPhoto.id] else { return false }
        return status.isViewed
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Photo counter
                    HStack {
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Photo with gestures
                    photoImageView
                    
                    Spacer()
                    
                    // Navigation hints
                    navigationHints
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("닫기") {
                    onClose()
                }
                .foregroundColor(.white),
                trailing: HStack(spacing: 16) {
                    VStack(alignment: .trailing) {
                        if !currentPhoto.title.isEmpty {
                            Text(currentPhoto.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Text("학번: \(currentPhoto.studentId)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: {
                        markPhotoAsViewed()
                    }) {
                        HStack(spacing: 4) {
                            if isPhotoAlreadyViewed || hasTrackedView {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("확인완료")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 12, weight: .bold))
                                Text("확인")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(isPhotoAlreadyViewed || hasTrackedView ? .green : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill((isPhotoAlreadyViewed || hasTrackedView) ? .green.opacity(0.1) : .blue.opacity(0.1))
                        )
                    }
                    .disabled(isPhotoAlreadyViewed || hasTrackedView)
                    .font(.system(size: 16, weight: .semibold))
                }
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasTrackedView = isPhotoAlreadyViewed  // Set initial state
            preloadNearbyImages()
        }
        .onChange(of: currentIndex) { _ in
            hasTrackedView = isPhotoAlreadyViewed  // Set based on existing view status
            preloadNearbyImages()
        }
    }
    
    @ViewBuilder
    private var photoImageView: some View {
        if let imageUrl = currentPhoto.imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.width + dragOffset, y: offset.height)
                    .gesture(photoGestures)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        ProgressView("이미지 로딩중...")
                            .foregroundColor(.white)
                    )
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.title)
                            .foregroundColor(.white)
                        Text("이미지를 불러올 수 없습니다")
                            .foregroundColor(.white)
                    }
                )
        }
    }
    
    private var photoGestures: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    scale = max(1.0, min(value, 4.0))
                }
                .onEnded { _ in
                    if scale < 1.0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            scale = 1.0
                            offset = .zero
                        }
                    }
                },
            DragGesture()
                .onChanged { value in
                    if scale > 1.0 {
                        offset = value.translation
                    } else {
                        dragOffset = value.translation.width
                        isDragging = true
                    }
                }
                .onEnded { value in
                    if scale > 1.0 {
                        return
                    } else {
                        let threshold: CGFloat = 100
                        let swipeVelocity = value.velocity.width
                        
                        if (value.translation.width > threshold || swipeVelocity > 300) && currentIndex > 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex -= 1
                                resetZoom()
                                preloadNearbyImages()
                            }
                        } else if (value.translation.width < -threshold || swipeVelocity < -300) && currentIndex < photos.count - 1 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex += 1
                                resetZoom()
                                preloadNearbyImages()
                            }
                        }
                        
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dragOffset = 0
                            isDragging = false
                        }
                    }
                }
        )
        .simultaneously(with: TapGesture(count: 2)
            .onEnded {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if scale > 1.0 {
                        resetZoom()
                    } else {
                        scale = 2.0
                    }
                }
            }
        )
    }
    
    @ViewBuilder
    private var navigationHints: some View {
        if !isDragging && scale <= 1.0 {
            HStack {
                if currentIndex > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("이전")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                if currentIndex < photos.count - 1 {
                    HStack(spacing: 4) {
                        Text("다음")
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
    }
    
    private func resetZoom() {
        scale = 1.0
        offset = .zero
        dragOffset = 0
    }
    
    private func preloadNearbyImages() {
        let indicesToPreload = [
            currentIndex - 1,
            currentIndex,
            currentIndex + 1
        ].compactMap { (index: Int) -> Int? in
            guard index >= 0 && index < photos.count else { return nil }
            return index
        }
        
        for index in indicesToPreload {
            let photo = photos[index]
            guard let imageUrl = photo.imageUrl,
                  preloadedImages[imageUrl] == nil,
                  let url = URL(string: imageUrl) else { continue }
            
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            preloadedImages[imageUrl] = uiImage
                        }
                    }
                } catch {
                    print("이미지 프리로드 실패: \(imageUrl)")
                }
            }
        }
    }
}

// MARK: - Photo Detail View with View Tracking

struct PhotoDetailViewWithTracking: View {
    let photos: [Photo]
    let photoViewStatuses: [String: PhotoViewStatus]
    let initialIndex: Int
    let onViewPhoto: (Photo, TimeInterval?) -> Void
    let onClose: () -> Void
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var preloadedImages: [String: UIImage] = [:]
    
    // View tracking
    @State private var hasTrackedView = false
    
    init(
        photos: [Photo], 
        photoViewStatuses: [String: PhotoViewStatus],
        initialIndex: Int, 
        onViewPhoto: @escaping (Photo, TimeInterval?) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.photos = photos
        self.photoViewStatuses = photoViewStatuses
        self.initialIndex = initialIndex
        self.onViewPhoto = onViewPhoto
        self.onClose = onClose
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    private var currentPhoto: Photo {
        if currentIndex >= 0 && currentIndex < photos.count {
            return photos[currentIndex]
        }
        return photos[0]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Photo counter
                    HStack {
                        Text("\(currentIndex + 1) / \(photos.count)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        
                        Spacer()
                        
                        // View status indicator
                        if let status = photoViewStatuses[currentPhoto.id] {
                            PhotoStatusIndicator(
                                status: currentPhoto.displayStatus(with: status),
                                size: 20,
                                showLabel: true
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Photo with gestures
                    photoImageView
                    
                    Spacer()
                    
                    // View details card (if viewed)
                    if let status = photoViewStatuses[currentPhoto.id], status.isViewed {
                        PhotoViewDetailsCard(
                            photo: currentPhoto, 
                            viewStatus: status
                        )
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    
                    // Navigation hints
                    navigationHints
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("")
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("닫기") {
                    onClose()
                }
                .foregroundColor(.white),
                trailing: HStack(spacing: 16) {
                    VStack(alignment: .trailing) {
                        if !currentPhoto.title.isEmpty {
                            Text(currentPhoto.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        
                        Text("학번: \(currentPhoto.studentId)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Button(action: {
                        markPhotoAsViewed()
                    }) {
                        HStack(spacing: 4) {
                            if isPhotoAlreadyViewed || hasTrackedView {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .bold))
                                Text("확인완료")
                                    .font(.system(size: 14, weight: .semibold))
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 12, weight: .bold))
                                Text("확인")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(isPhotoAlreadyViewed || hasTrackedView ? .green : .blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill((isPhotoAlreadyViewed || hasTrackedView) ? .green.opacity(0.1) : .blue.opacity(0.1))
                        )
                    }
                    .disabled(isPhotoAlreadyViewed || hasTrackedView)
                    .font(.system(size: 16, weight: .semibold))
                }
            )
        }
        .preferredColorScheme(.dark)
        .onAppear {
            hasTrackedView = isPhotoAlreadyViewed  // Set initial state
            preloadNearbyImages()
        }
        .onDisappear {
            // No auto-tracking anymore
        }
        .onChange(of: currentIndex) { _ in
            hasTrackedView = isPhotoAlreadyViewed  // Set based on existing view status
            preloadNearbyImages()
        }
    }
    
    @ViewBuilder
    private var photoImageView: some View {
        if let imageUrl = currentPhoto.imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(x: offset.width + dragOffset, y: offset.height)
                    .gesture(photoGestures)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(
                        ProgressView("이미지 로딩중...")
                            .foregroundColor(.white)
                    )
            }
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 300)
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                        Text("이미지를 찾을 수 없습니다")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                )
        }
    }
    
    @ViewBuilder
    private var navigationHints: some View {
        if photos.count > 1 {
            HStack {
                if currentIndex > 0 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex -= 1
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("이전")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
                
                if currentIndex < photos.count - 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex += 1
                        }
                    } label: {
                        HStack {
                            Text("다음")
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }
    
    private var photoGestures: some Gesture {
        SimultaneousGesture(
            // Magnification gesture for zoom
            MagnificationGesture()
                .onChanged { value in
                    scale = max(0.5, min(value, 3.0))
                }
                .onEnded { _ in
                    withAnimation(.interactiveSpring()) {
                        if scale < 1.0 {
                            scale = 1.0
                        }
                    }
                },
            
            // Drag gesture for pan and swipe
            DragGesture()
                .onChanged { value in
                    if scale > 1.0 {
                        // Pan when zoomed
                        offset = value.translation
                    } else {
                        // Horizontal swipe when not zoomed
                        dragOffset = value.translation.width
                        isDragging = true
                    }
                }
                .onEnded { value in
                    withAnimation(.interactiveSpring()) {
                        if scale > 1.0 {
                            // Reset pan
                            offset = .zero
                        } else {
                            isDragging = false
                            
                            // Handle swipe
                            if abs(value.translation.width) > 100 {
                                if value.translation.width > 0 && currentIndex > 0 {
                                    // Swipe right - previous image
                                    currentIndex -= 1
                                } else if value.translation.width < 0 && currentIndex < photos.count - 1 {
                                    // Swipe left - next image
                                    currentIndex += 1
                                }
                            }
                            
                            dragOffset = 0
                        }
                    }
                }
        )
    }
    
    // MARK: - View Tracking Methods
    
    private func markPhotoAsViewed() {
        if !hasTrackedView && !isPhotoAlreadyViewed {
            onViewPhoto(currentPhoto, nil)
            hasTrackedView = true
            print("✅ 수동 확인: \(currentPhoto.id)")
        }
    }
    
    private var isPhotoAlreadyViewed: Bool {
        guard let status = photoViewStatuses[currentPhoto.id] else { return false }
        return status.isViewed
    }
    
    private func preloadNearbyImages() {
        let preloadRange = 2
        let startIndex = max(0, currentIndex - preloadRange)
        let endIndex = min(photos.count - 1, currentIndex + preloadRange)
        let indicesToPreload = Array(startIndex...endIndex).filter { $0 != currentIndex }
        
        for index in indicesToPreload {
            let photo = photos[index]
            guard let imageUrl = photo.imageUrl,
                  preloadedImages[imageUrl] == nil,
                  let url = URL(string: imageUrl) else { continue }
            
            Task {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            preloadedImages[imageUrl] = uiImage
                        }
                    }
                } catch {
                    print("이미지 프리로드 실패: \(imageUrl)")
                }
            }
        }
    }
}