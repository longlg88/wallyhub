import RIBs

protocol RootDependency: Dependency {
    var authenticationService: AuthenticationService { get }
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var photoService: PhotoService { get }
    var photoViewTrackingService: PhotoViewTrackingService { get }
    var configurationManager: ConfigurationManager { get }
    var serviceFactory: ServiceFactory { get }
}

final class RootComponent: Component<RootDependency>, AuthDependency, StudentDependency, TeacherDependency, AdminDependency {
    
    var authenticationService: AuthenticationService {
        return dependency.authenticationService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var photoService: PhotoService {
        return dependency.photoService
    }
    
    var configurationManager: ConfigurationManager {
        return dependency.configurationManager
    }
    
    var serviceFactory: ServiceFactory {
        return dependency.serviceFactory
    }
    
    var photoViewTrackingService: PhotoViewTrackingService {
        return dependency.photoViewTrackingService
    }
}

// MARK: - Builder

protocol RootBuildable: Buildable {
    func build() -> RootRouting
}

final class RootBuilder: Builder<RootDependency>, RootBuildable {

    override init(dependency: RootDependency) {
        super.init(dependency: dependency)
    }

    func build() -> RootRouting {
        let component = RootComponent(dependency: dependency)
        let viewController = RootViewController()
        let interactor = RootInteractor(
            presenter: viewController,
            authenticationService: component.authenticationService
        )
        
        let authBuilder = AuthBuilder(dependency: component)
        let studentBuilder = StudentBuilder(dependency: component)
        let teacherBuilder = TeacherBuilder(dependency: component)
        let adminBuilder = AdminBuilder(dependency: component)
        
        return RootRouter(
            interactor: interactor,
            viewController: viewController,
            authBuilder: authBuilder,
            studentBuilder: studentBuilder,
            teacherBuilder: teacherBuilder,
            adminBuilder: adminBuilder
        )
    }
}