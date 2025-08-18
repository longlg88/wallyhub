import RIBs
import Foundation

// MARK: - Business Logic Protocols

protocol PhotoModerationListener: AnyObject {
    func photoModerationDidComplete()
}

protocol PhotoModerationPresentableListener: AnyObject {
    func didTapClose()
    func didRequestLoadPhotos()
    func didTapDeletePhoto(_ photo: Photo)
    func didTapDeleteSelectedPhotos(_ photos: [Photo])
    func didViewPhoto(_ photo: Photo, sessionDuration: TimeInterval?)
    func didRequestMarkPhotosAsViewed(_ photoIds: [String])
}

protocol PhotoModerationInteractable: Interactable {
    var router: PhotoModerationRouting? { get set }
    var listener: PhotoModerationListener? { get set }
}

protocol PhotoModerationPresentable: Presentable {
    var listener: PhotoModerationPresentableListener? { get set }
    func showPhotos(_ photos: [Photo])
    func showPhotoViewStatuses(_ statuses: [String: PhotoViewStatus])
    func showLoading()
    func hideLoading()
    func showError(_ error: Error)
}

final class PhotoModerationInteractor: PresentableInteractor<PhotoModerationPresentable>, PhotoModerationInteractable, PhotoModerationPresentableListener {
    weak var router: PhotoModerationRouting?
    weak var listener: PhotoModerationListener?
    
    private let boardId: String
    private let photoService: PhotoService
    private let photoViewTrackingService: PhotoViewTrackingService
    private let currentTeacherId: String

    init(
        presenter: PhotoModerationPresentable, 
        boardId: String, 
        photoService: PhotoService,
        photoViewTrackingService: PhotoViewTrackingService,
        currentTeacherId: String
    ) {
        self.boardId = boardId
        self.photoService = photoService
        self.photoViewTrackingService = photoViewTrackingService
        self.currentTeacherId = currentTeacherId
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    override func didBecomeActive() {
        super.didBecomeActive()
        loadPhotos()
    }
    
    // MARK: - PhotoModerationPresentableListener
    
    func didTapClose() {
        listener?.photoModerationDidComplete()
    }
    
    func didRequestLoadPhotos() {
        loadPhotos()
    }
    
    func didViewPhoto(_ photo: Photo, sessionDuration: TimeInterval?) {
        print("👁️ PhotoModerationInteractor: 사진 조회 기록 - PhotoID: \(photo.id)")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.photoViewTrackingService.trackPhotoView(
                    photoId: photo.id,
                    teacherId: self.currentTeacherId,
                    boardId: photo.boardId,
                    sessionDuration: sessionDuration
                )
                
                await MainActor.run {
                    print("✅ PhotoModerationInteractor: 사진 조회 기록 완료")
                    // 조회 상태 업데이트
                    self.loadPhotoViewStatuses()
                }
            } catch {
                await MainActor.run {
                    print("❌ PhotoModerationInteractor: 조회 기록 실패 - \(error)")
                }
            }
        }
    }
    
    func didRequestMarkPhotosAsViewed(_ photoIds: [String]) {
        print("✅ PhotoModerationInteractor: 사진 일괄 확인 요청 - \(photoIds.count)개")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.photoViewTrackingService.markPhotosAsViewed(
                    photoIds: photoIds,
                    teacherId: self.currentTeacherId,
                    boardId: self.boardId
                )
                
                await MainActor.run {
                    print("✅ PhotoModerationInteractor: 일괄 확인 처리 완료")
                    // 조회 상태 업데이트
                    self.loadPhotoViewStatuses()
                }
            } catch {
                await MainActor.run {
                    print("❌ PhotoModerationInteractor: 일괄 확인 실패 - \(error)")
                    self.presenter.showError(error)
                }
            }
        }
    }
    
    func didTapDeletePhoto(_ photo: Photo) {
        print("🗑️ PhotoModerationInteractor: 사진 삭제 요청 - PhotoID: \(photo.id)")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            do {
                // PhotoService의 deletePhoto 메서드 호출 (교사는 모든 사진 삭제 권한 있음)
                try await self.photoService.deletePhoto(photoId: photo.id, studentId: photo.studentId)
                
                await MainActor.run { [weak self] in
                    print("✅ PhotoModerationInteractor: 사진 삭제 완료")
                    // 삭제 후 목록 새로고침
                    self?.loadPhotos()
                }
            } catch {
                await MainActor.run { [weak self] in
                    print("❌ PhotoModerationInteractor: 사진 삭제 실패 - \(error)")
                    self?.presenter.showError(error)
                }
            }
        }
    }
    
    func didTapDeleteSelectedPhotos(_ photos: [Photo]) {
        print("🗑️ PhotoModerationInteractor: 다중 사진 삭제 요청 - \(photos.count)개 사진")
        
        Task { [weak self] in
            guard let self = self else { return }
            
            var successCount = 0
            var failureCount = 0
            
            // 각 사진을 순차적으로 삭제
            for photo in photos {
                do {
                    try await self.photoService.deletePhoto(photoId: photo.id, studentId: photo.studentId)
                    successCount += 1
                    print("✅ PhotoModerationInteractor: 사진 삭제 성공 - \(photo.id)")
                } catch {
                    failureCount += 1
                    print("❌ PhotoModerationInteractor: 사진 삭제 실패 - \(photo.id): \(error)")
                }
            }
            
            await MainActor.run { [weak self] in
                print("🏁 PhotoModerationInteractor: 다중 삭제 완료 - 성공: \(successCount), 실패: \(failureCount)")
                
                if failureCount > 0 {
                    print("📊 다중 삭제 결과: 성공 \(successCount)개, 실패 \(failureCount)개")
                    self?.presenter.showError(WallyError.photoNotFound)
                }
                
                // 삭제 후 목록 새로고침
                self?.loadPhotos()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPhotos() {
        print("📸 PhotoModerationInteractor: 게시판 사진 로딩 시작 - boardId: \(boardId)")
        presenter.showLoading()
        
        Task {
            do {
                let photos = try await photoService.getPhotosForBoard(boardId: boardId)
                
                await MainActor.run {
                    print("✅ PhotoModerationInteractor: 사진 로딩 완료 - \(photos.count)개")
                    self.presenter.hideLoading()
                    self.presenter.showPhotos(photos)
                    
                    // 사진 로딩 후 조회 상태도 함께 로딩
                    self.loadPhotoViewStatuses()
                }
                
            } catch {
                print("❌ PhotoModerationInteractor: 사진 로딩 실패 - \(error)")
                
                await MainActor.run {
                    self.presenter.hideLoading()
                    self.presenter.showError(error)
                }
            }
        }
    }
    
    private func loadPhotoViewStatuses() {
        print("📊 PhotoModerationInteractor: 사진 조회 상태 로딩 시작")
        
        Task {
            do {
                let viewStatuses = try await photoViewTrackingService.getBoardPhotoViewStatuses(boardId: boardId)
                
                await MainActor.run {
                    print("✅ PhotoModerationInteractor: 조회 상태 로딩 완료 - \(viewStatuses.count)개")
                    self.presenter.showPhotoViewStatuses(viewStatuses)
                }
                
            } catch {
                print("❌ PhotoModerationInteractor: 조회 상태 로딩 실패 - \(error)")
                // 조회 상태 로딩 실패는 에러로 표시하지 않음 (선택적 기능)
            }
        }
    }
}