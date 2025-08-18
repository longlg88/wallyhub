import RIBs

protocol AdminDependency: Dependency {
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var photoService: PhotoService { get }
    var authenticationService: AuthenticationService { get }
}

final class AdminComponent: Component<AdminDependency>, SystemDashboardDependency, AllBoardsManagementDependency, UserManagementDependency {
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var photoService: PhotoService {
        return dependency.photoService
    }
    
    var authenticationService: AuthenticationService {
        return dependency.authenticationService
    }
}

// MARK: - Builder

protocol AdminBuildable: Buildable {
    func build(withListener listener: AdminListener) -> AdminRouting
}

final class AdminBuilder: Builder<AdminDependency>, AdminBuildable {

    override init(dependency: AdminDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: AdminListener) -> AdminRouting {
        let component = AdminComponent(dependency: dependency)
        let viewController = AdminViewController()
        let interactor = AdminInteractor(presenter: viewController)
        interactor.listener = listener
        
        let systemDashboardBuilder = SystemDashboardBuilder(dependency: component)
        let allBoardsManagementBuilder = AllBoardsManagementBuilder(dependency: component)
        let userManagementBuilder = UserManagementBuilder(dependency: component)
        
        return AdminRouter(
            interactor: interactor,
            viewController: viewController,
            systemDashboardBuilder: systemDashboardBuilder,
            allBoardsManagementBuilder: allBoardsManagementBuilder,
            userManagementBuilder: userManagementBuilder
        )
    }
}