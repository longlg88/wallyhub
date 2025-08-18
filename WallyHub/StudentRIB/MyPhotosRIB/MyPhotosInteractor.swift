import RIBs
import RxSwift
import Foundation
import UIKit

// MARK: - Business Logic Protocols

protocol MyPhotosPresentable: Presentable {
    var listener: MyPhotosPresentableListener? { get set }
    func showPhotos(_ photos: [Photo])
    func showLoading()
    func hideLoading()
    func showError(_ error: Error)
    func updateStudentName(_ name: String)
    func updateBoardSettings(_ board: Board)
    func updateBoardTitle(_ title: String)
}

protocol MyPhotosListener: AnyObject {
    func myPhotosDidRequestPhotoUpload(boardId: String)
    func myPhotosDidComplete()
}

final class MyPhotosInteractor: PresentableInteractor<MyPhotosPresentable>, MyPhotosInteractable, MyPhotosPresentableListener {

    weak var router: MyPhotosRouting?
    weak var listener: MyPhotosListener?
    
    private let photoService: PhotoService
    private let studentService: StudentService
    private let boardService: BoardService
    private let studentName: String
    private let boardId: String
    private let studentId: String
    
    // 📸 선택된 이미지를 임시 저장
    private var pendingImageForUpload: UIImage?

    init(
        presenter: MyPhotosPresentable,
        photoService: PhotoService,
        studentService: StudentService,
        boardService: BoardService,
        studentName: String,
        boardId: String,
        studentId: String
    ) {
        self.photoService = photoService
        self.studentService = studentService
        self.boardService = boardService
        self.studentName = studentName
        self.boardId = boardId
        self.studentId = studentId
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        presenter.updateStudentName(studentName)
        loadBoardSettings()
        loadMyPhotos()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - MyPhotosPresentableListener
    
    func didTapUploadPhoto() {
        print("📸 MyPhotosInteractor: 사진 업로드 요청 - 업로드 옵션 표시")
        // 플로팅 버튼에서는 업로드 옵션 시트를 표시 (기존 동작 유지)
        // UI에서 showingUploadOptions = true로 처리됨
    }
    
    func didTapCamera() {
        print("🎥 MyPhotosInteractor: Camera tap received")
        router?.presentCamera()
        print("🎥 MyPhotosInteractor: Camera navigation requested")
    }
    
    func didTapGallery() {
        print("📱 MyPhotosInteractor: Gallery tap received")
        router?.presentGallery()
        print("📱 MyPhotosInteractor: Gallery navigation requested")
    }
    
    func didSelectImageForUpload(_ image: UIImage) {
        print("📸 MyPhotosInteractor: Image selected for upload - BoardID: \(boardId)")
        
        // 🚨 CRITICAL FIX: 선택된 이미지를 저장
        pendingImageForUpload = image
        print("💾 MyPhotosInteractor: 이미지 저장 완료 - 크기: \(image.size)")
        
        listener?.myPhotosDidRequestPhotoUpload(boardId: boardId)
    }
    
    // 📸 저장된 이미지를 반환하고 정리하는 메서드 (public)
    public func getPendingImageForUpload() -> UIImage? {
        let image = pendingImageForUpload
        pendingImageForUpload = nil // 한 번 사용 후 정리
        
        if let image = image {
            print("✅ MyPhotosInteractor: 저장된 이미지 반환 - 크기: \(image.size)")
        } else {
            print("⚠️ MyPhotosInteractor: 저장된 이미지가 없음")
        }
        
        return image
    }
    
    func didTapClose() {
        listener?.myPhotosDidComplete()
    }
    
    func didTapRefresh() {
        loadMyPhotos()
    }
    
    func didSelectPhoto(_ photo: Photo) {
        // Handle photo selection if needed
        // Could navigate to photo detail view
    }
    
    func didTapDeletePhoto(_ photo: Photo) {
        print("🗑️ MyPhotosInteractor: 사진 삭제 요청 - PhotoID: \(photo.id)")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // PhotoService의 deletePhoto 메서드 호출
                try await self.photoService.deletePhoto(photoId: photo.id, studentId: self.studentId)
                
                await MainActor.run { [weak self] in
                    print("✅ MyPhotosInteractor: 사진 삭제 완료")
                    // 삭제 후 목록 새로고침
                    self?.loadMyPhotos()
                }
            } catch {
                await MainActor.run { [weak self] in
                    print("❌ MyPhotosInteractor: 사진 삭제 실패 - \(error)")
                    self?.presenter.showError(error)
                }
            }
        }
    }
    
    func didTapDeleteSelectedPhotos(_ photos: [Photo]) {
        print("🗑️ MyPhotosInteractor: 다중 사진 삭제 요청 - \(photos.count)개 사진")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            var successCount = 0
            var failureCount = 0
            
            // 각 사진을 순차적으로 삭제
            for photo in photos {
                do {
                    try await self.photoService.deletePhoto(photoId: photo.id, studentId: self.studentId)
                    successCount += 1
                    print("✅ MyPhotosInteractor: 사진 삭제 성공 - \(photo.id)")
                } catch {
                    failureCount += 1
                    print("❌ MyPhotosInteractor: 사진 삭제 실패 - \(photo.id): \(error)")
                }
            }
            
            await MainActor.run { [weak self] in
                print("🏁 MyPhotosInteractor: 다중 삭제 완료 - 성공: \(successCount), 실패: \(failureCount)")
                
                if failureCount > 0 {
                    // 실패가 있을 때는 photoNotFound 오류를 사용하고, 성공/실패 개수는 로그로만 표시
                    print("📊 다중 삭제 결과: 성공 \(successCount)개, 실패 \(failureCount)개")
                    self?.presenter.showError(WallyError.photoNotFound)
                }
                
                // 삭제 후 목록 새로고침
                self?.loadMyPhotos()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadMyPhotos() {
        presenter.showLoading()
        
        print("📸 MyPhotosInteractor: 사진 로딩 시작 - StudentID: \(studentId), BoardID: \(boardId)")
        
        Task {
            do {
                // 실제 Firebase에서 현재 학생의 사진들을 로드
                let photos = try await photoService.getPhotosForStudent(studentId: studentId, boardId: boardId)
                
                await MainActor.run {
                    print("✅ MyPhotosInteractor: 사진 로딩 완료 - \(photos.count)개")
                    self.presenter.hideLoading()
                    self.presenter.showPhotos(photos)
                }
                
            } catch {
                print("❌ MyPhotosInteractor: 사진 로딩 실패 - \(error)")
                
                await MainActor.run {
                    self.presenter.hideLoading()
                    self.presenter.showError(error)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadBoardSettings() {
        Task { @MainActor in
            do {
                let board = try await boardService.getBoard(id: boardId)
                presenter.updateBoardSettings(board)
                presenter.updateBoardTitle(board.title)
                print("✅ MyPhotos: 게시판 설정 로드 완료 - 배경: \(board.settings.backgroundImage.displayName), 제목: \(board.title)")
            } catch {
                print("❌ MyPhotos: 게시판 설정 로드 실패 - \(error)")
                // 에러가 발생해도 기본 설정으로 계속 진행
            }
        }
    }
}

// MARK: - Protocols

protocol MyPhotosInteractable: Interactable {
    var router: MyPhotosRouting? { get set }
    var listener: MyPhotosListener? { get set }
}

protocol MyPhotosPresentableListener: AnyObject {
    func didTapUploadPhoto()
    func didTapCamera()
    func didTapGallery()
    func didTapClose()
    func didTapRefresh()
    func didSelectPhoto(_ photo: Photo)
    func didSelectImageForUpload(_ image: UIImage)
    func didTapDeletePhoto(_ photo: Photo)
    func didTapDeleteSelectedPhotos(_ photos: [Photo])
}