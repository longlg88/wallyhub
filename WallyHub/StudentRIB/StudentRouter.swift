import RIBs
import UIKit

// MARK: - Navigation Protocols

protocol StudentRouting: ViewableRouting {
    func routeToQRScanner()
    func dismissQRScanner()
    func routeToBoardJoin(boardId: String)
    func dismissBoardJoin()
    func routeToPhotoUpload(boardId: String, studentId: String)
    func routeToPhotoUpload(boardId: String, studentId: String, preSelectedImage: UIImage)
    func dismissPhotoUpload()
    func routeToMyPhotos(boardId: String, studentId: String)
    func dismissMyPhotos()
    func routeToMyParticipations()
    func dismissMyParticipations()
    
    // 📸 MyPhotos에서 저장된 이미지 가져오기
    func getPendingImageFromMyPhotos() -> UIImage?
}

protocol StudentViewControllable: ViewControllable {
    func presentQRScanner(viewController: ViewControllable)
    func dismissQRScanner()
    func presentBoardJoin(viewController: ViewControllable)
    func dismissBoardJoin()
    func presentPhotoUpload(viewController: ViewControllable)
    func dismissPhotoUpload()
    func presentMyPhotos(viewController: ViewControllable)
    func dismissMyPhotos()
    func presentMyParticipations(viewController: ViewControllable)
    func dismissMyParticipations()
}

final class StudentRouter: ViewableRouter<StudentInteractable, StudentViewControllable>, StudentRouting {

    private let qrScannerBuilder: QRScannerBuildable
    private let boardJoinBuilder: BoardJoinBuildable
    private let photoUploadBuilder: PhotoUploadBuildable
    private let myPhotosBuilder: MyPhotosBuildable
    private let myParticipationsBuilder: MyParticipationsBuildable
    
    private var qrScannerRouter: ViewableRouting?
    private var boardJoinRouter: ViewableRouting?
    private var photoUploadRouter: ViewableRouting?
    private var myPhotosRouter: ViewableRouting?
    private var myParticipationsRouter: ViewableRouting?

    init(
        interactor: StudentInteractable,
        viewController: StudentViewControllable,
        qrScannerBuilder: QRScannerBuildable,
        boardJoinBuilder: BoardJoinBuildable,
        photoUploadBuilder: PhotoUploadBuildable,
        myPhotosBuilder: MyPhotosBuildable,
        myParticipationsBuilder: MyParticipationsBuildable
    ) {
        self.qrScannerBuilder = qrScannerBuilder
        self.boardJoinBuilder = boardJoinBuilder
        self.photoUploadBuilder = photoUploadBuilder
        self.myPhotosBuilder = myPhotosBuilder
        self.myParticipationsBuilder = myParticipationsBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    // MARK: - StudentRouting
    
    func routeToQRScanner() {
        guard qrScannerRouter == nil else { return }
        
        let router = qrScannerBuilder.build(withListener: interactor)
        qrScannerRouter = router
        attachChild(router)
        viewController.presentQRScanner(viewController: router.viewControllable)
    }
    
    func dismissQRScanner() {
        guard let router = qrScannerRouter else { return }
        
        viewController.dismissQRScanner()
        detachChild(router)
        qrScannerRouter = nil
    }
    
    func routeToBoardJoin(boardId: String) {
        guard boardJoinRouter == nil else { return }
        
        let router = boardJoinBuilder.build(withListener: interactor, boardId: boardId)
        boardJoinRouter = router
        attachChild(router)
        viewController.presentBoardJoin(viewController: router.viewControllable)
    }
    
    func dismissBoardJoin() {
        guard let router = boardJoinRouter else { return }
        
        viewController.dismissBoardJoin()
        detachChild(router)
        boardJoinRouter = nil
    }
    
    func routeToPhotoUpload(boardId: String, studentId: String) {
        guard photoUploadRouter == nil else { return }
        
        let router = photoUploadBuilder.build(
            withListener: interactor, 
            boardId: boardId, 
            currentStudentId: studentId
        )
        photoUploadRouter = router
        attachChild(router)
        viewController.presentPhotoUpload(viewController: router.viewControllable)
    }
    
    func routeToPhotoUpload(boardId: String, studentId: String, preSelectedImage: UIImage) {
        guard photoUploadRouter == nil else { return }
        
        print("📸 StudentRouter: PhotoUpload with pre-selected image - 크기: \(preSelectedImage.size)")
        let router = photoUploadBuilder.build(
            withListener: interactor, 
            boardId: boardId, 
            currentStudentId: studentId,
            preSelectedImage: preSelectedImage
        )
        photoUploadRouter = router
        attachChild(router)
        viewController.presentPhotoUpload(viewController: router.viewControllable)
    }
    
    func dismissPhotoUpload() {
        guard let router = photoUploadRouter else { return }
        
        viewController.dismissPhotoUpload()
        detachChild(router)
        photoUploadRouter = nil
    }
    
    func routeToMyPhotos(boardId: String, studentId: String) {
        guard myPhotosRouter == nil else { return }
        
        print("📱 StudentRouter: MyPhotos 빌드 시작 - BoardID: \(boardId), StudentID: \(studentId)")
        let router = myPhotosBuilder.build(withListener: interactor, boardId: boardId, studentId: studentId)
        myPhotosRouter = router
        attachChild(router)
        viewController.presentMyPhotos(viewController: router.viewControllable)
        print("✅ StudentRouter: MyPhotos 빌드 완료")
    }
    
    func dismissMyPhotos() {
        guard let router = myPhotosRouter else { return }
        
        viewController.dismissMyPhotos()
        detachChild(router)
        myPhotosRouter = nil
    }
    
    func routeToMyParticipations() {
        guard myParticipationsRouter == nil else { return }
        
        let router = myParticipationsBuilder.build(withListener: interactor)
        myParticipationsRouter = router
        attachChild(router)
        viewController.presentMyParticipations(viewController: router.viewControllable)
    }
    
    func dismissMyParticipations() {
        guard let router = myParticipationsRouter else { return }
        
        viewController.dismissMyParticipations()
        detachChild(router)
        myParticipationsRouter = nil
    }
    
    // 📸 MyPhotos에서 저장된 이미지 가져오기
    func getPendingImageFromMyPhotos() -> UIImage? {
        guard let myPhotosRouter = myPhotosRouter else {
            print("⚠️ StudentRouter: MyPhotos RIB이 활성화되지 않음")
            return nil
        }
        
        // MyPhotosRouter로 타입 캐스팅하여 저장된 이미지 가져오기
        guard let myPhotosRouting = myPhotosRouter as? MyPhotosRouting else {
            print("❌ StudentRouter: MyPhotosRouting으로 캐스팅 실패")
            return nil
        }
        
        return myPhotosRouting.getPendingImageForUpload()
    }
}