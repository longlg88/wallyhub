import RIBs
import RxSwift
import UIKit

// MARK: - Business Logic Protocols

protocol PhotoUploadPresentable: Presentable {
    var listener: PhotoUploadPresentableListener? { get set }
    func showImagePicker()
    func showCamera()
    func showGallery()
    func showUploadProgress()
    func hideUploadProgress()
    func showUploadSuccess()
    func showUploadError(_ error: Error)
    func updateSelectedImage(_ image: UIImage)
    func updateBoardSettings(_ board: Board)
}

protocol PhotoUploadListener: AnyObject {
    func photoUploadDidComplete()
    func photoUploadDidCancel()
}

final class PhotoUploadInteractor: PresentableInteractor<PhotoUploadPresentable>, PhotoUploadInteractable, PhotoUploadPresentableListener {

    weak var router: PhotoUploadRouting?
    weak var listener: PhotoUploadListener?
    
    private let photoService: PhotoService
    private let studentService: StudentService
    private let boardService: BoardService
    private let boardId: String
    private let currentStudentId: String
    
    private var selectedImage: UIImage?

    init(
        presenter: PhotoUploadPresentable,
        photoService: PhotoService,
        studentService: StudentService,
        boardService: BoardService,
        boardId: String,
        currentStudentId: String,
        preSelectedImage: UIImage? = nil
    ) {
        self.photoService = photoService
        self.studentService = studentService
        self.boardService = boardService
        self.boardId = boardId
        self.currentStudentId = currentStudentId
        
        // 🚨 CRITICAL FIX: pre-selected image를 즉시 설정
        self.selectedImage = preSelectedImage
        
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        
        // 🚨 pre-selected image가 있으면 즉시 UI에 표시
        if let preSelectedImage = selectedImage {
            print("✅ PhotoUploadInteractor: Pre-selected 이미지 발견 - 크기: \(preSelectedImage.size)")
            presenter.updateSelectedImage(preSelectedImage)
        } else {
            print("📱 PhotoUploadInteractor: Pre-selected 이미지 없음 - 일반 모드")
        }
        
        // 게시판 설정 로드하여 UI에 반영
        loadBoardSettings()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - PhotoUploadPresentableListener
    
    func didTapSelectPhoto() {
        presenter.showImagePicker()
    }
    
    func didTapCamera() {
        presenter.showCamera()
    }
    
    func didTapGallery() {
        presenter.showGallery()
    }
    
    func didSelectImage(_ image: UIImage) {
        selectedImage = image
        presenter.updateSelectedImage(image)
    }
    
    func didTapUpload() {
        guard let image = selectedImage else { return }
        
        presenter.showUploadProgress()
        
        // 실제 PhotoService를 사용하여 업로드
        Task { @MainActor in
            do {
                let photo = try await photoService.uploadPhoto(
                    image: image,
                    studentId: currentStudentId,
                    boardId: boardId,
                    title: "학생 작품"
                )
                
                print("✅ 사진 업로드 성공: \(photo.title) (ID: \(photo.id))")
                
                presenter.hideUploadProgress()
                presenter.showUploadSuccess()
                
                // Complete after showing success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    self?.listener?.photoUploadDidComplete()
                }
                
            } catch {
                print("❌ 사진 업로드 실패: \(error)")
                presenter.hideUploadProgress()
                presenter.showUploadError(error)
            }
        }
    }
    
    func didTapCancel() {
        listener?.photoUploadDidCancel()
    }
    
    func didTapRetry() {
        guard selectedImage != nil else { return }
        didTapUpload()
    }
    
    // MARK: - Private Methods
    
    private func loadBoardSettings() {
        Task { @MainActor in
            do {
                let board = try await boardService.getBoard(id: boardId)
                presenter.updateBoardSettings(board)
                print("✅ PhotoUpload: 게시판 설정 로드 완료 - 배경: \(board.settings.backgroundImage.displayName)")
            } catch {
                print("❌ PhotoUpload: 게시판 설정 로드 실패 - \(error)")
                // 에러가 발생해도 기본 설정으로 계속 진행
            }
        }
    }
}

// MARK: - Protocols

protocol PhotoUploadInteractable: Interactable {
    var router: PhotoUploadRouting? { get set }
    var listener: PhotoUploadListener? { get set }
}

protocol PhotoUploadPresentableListener: AnyObject {
    func didTapSelectPhoto()
    func didTapCamera()
    func didTapGallery()
    func didSelectImage(_ image: UIImage)
    func didTapUpload()
    func didTapCancel()
    func didTapRetry()
}
