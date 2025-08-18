import RIBs

protocol SystemDashboardDependency: Dependency {
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var authenticationService: AuthenticationService { get }
    var photoService: PhotoService { get }
}

final class SystemDashboardComponent: Component<SystemDashboardDependency> {
    var boardService: BoardService { dependency.boardService }
    var studentService: StudentService { dependency.studentService }
    var authenticationService: AuthenticationService { dependency.authenticationService }
    var photoService: PhotoService { dependency.photoService }
}

protocol SystemDashboardBuildable: Buildable {
    func build(withListener listener: SystemDashboardListener) -> SystemDashboardRouting
}

final class SystemDashboardBuilder: Builder<SystemDashboardDependency>, SystemDashboardBuildable {
    override init(dependency: SystemDashboardDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: SystemDashboardListener) -> SystemDashboardRouting {
        let component = SystemDashboardComponent(dependency: dependency)
        let viewController = SystemDashboardViewController()
        let interactor = SystemDashboardInteractor(
            presenter: viewController,
            boardService: component.boardService,
            studentService: component.studentService,
            authenticationService: component.authenticationService,
            photoService: component.photoService
        )
        interactor.listener = listener
        
        return SystemDashboardRouter(interactor: interactor, viewController: viewController)
    }
}