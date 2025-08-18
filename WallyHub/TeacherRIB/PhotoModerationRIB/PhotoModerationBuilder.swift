import RIBs

protocol PhotoModerationDependency: Dependency {
    var photoService: PhotoService { get }
    var boardService: BoardService { get }
    var photoViewTrackingService: PhotoViewTrackingService { get }
    var authenticationService: AuthenticationService { get }
}

final class PhotoModerationComponent: Component<PhotoModerationDependency> {
    var photoService: PhotoService { dependency.photoService }
    var boardService: BoardService { dependency.boardService }
    var photoViewTrackingService: PhotoViewTrackingService { dependency.photoViewTrackingService }
    var authenticationService: AuthenticationService { dependency.authenticationService }
}

protocol PhotoModerationBuildable: Buildable {
    func build(withListener listener: PhotoModerationListener, boardId: String) -> PhotoModerationRouting
}

final class PhotoModerationBuilder: Builder<PhotoModerationDependency>, PhotoModerationBuildable {
    override init(dependency: PhotoModerationDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: PhotoModerationListener, boardId: String) -> PhotoModerationRouting {
        let component = PhotoModerationComponent(dependency: dependency)
        let viewController = PhotoModerationViewController()
        let interactor = PhotoModerationInteractor(
            presenter: viewController, 
            boardId: boardId,
            photoService: component.photoService,
            photoViewTrackingService: component.photoViewTrackingService,
            currentTeacherId: getCurrentTeacherId(from: component.authenticationService)
        )
        interactor.listener = listener
        
        return PhotoModerationRouter(interactor: interactor, viewController: viewController)
    }
    
    private func getCurrentTeacherId(from authService: AuthenticationService) -> String {
        // 현재 로그인한 교사 ID 반환
        // 실제 구현에서는 AuthenticationService에서 가져와야 함
        return "teacher_001" // 임시 값
    }
}
