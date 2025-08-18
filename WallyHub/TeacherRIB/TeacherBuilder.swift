import RIBs

protocol TeacherDependency: Dependency {
    var boardService: BoardService { get }
    var studentService: StudentService { get }
    var photoService: PhotoService { get }
    var photoViewTrackingService: PhotoViewTrackingService { get }
    var authenticationService: AuthenticationService { get }
}

final class TeacherComponent: Component<TeacherDependency>, BoardCreationDependency, StudentManagementDependency, PhotoModerationDependency, BoardSettingsDependency {
    
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
    
    var photoViewTrackingService: PhotoViewTrackingService {
        return dependency.photoViewTrackingService
    }
}

// MARK: - Builder

protocol TeacherBuildable: Buildable {
    func build(withListener listener: TeacherListener) -> TeacherRouting
}

final class TeacherBuilder: Builder<TeacherDependency>, TeacherBuildable {

    override init(dependency: TeacherDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: TeacherListener) -> TeacherRouting {
        let component = TeacherComponent(dependency: dependency)
        let viewController = TeacherViewController()
        let interactor = TeacherInteractor(
            presenter: viewController, 
            authenticationService: dependency.authenticationService,
            boardService: dependency.boardService
        )
        interactor.listener = listener
        
        let boardCreationBuilder = BoardCreationBuilder(dependency: component)
        let studentManagementBuilder = StudentManagementBuilder(dependency: component)
        let photoModerationBuilder = PhotoModerationBuilder(dependency: component)
        let boardSettingsBuilder = BoardSettingsBuilder(dependency: component)
        
        return TeacherRouter(
            interactor: interactor,
            viewController: viewController,
            boardCreationBuilder: boardCreationBuilder,
            studentManagementBuilder: studentManagementBuilder,
            photoModerationBuilder: photoModerationBuilder,
            boardSettingsBuilder: boardSettingsBuilder
        )
    }
}