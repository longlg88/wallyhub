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
        print("🔨 TeacherBuilder: build 시작")
        
        let component = TeacherComponent(dependency: dependency)
        print("✅ TeacherBuilder: Component 생성 완료")
        
        let viewController = TeacherViewController()
        print("✅ TeacherBuilder: ViewController 생성 완료")
        
        let interactor = TeacherInteractor(
            presenter: viewController, 
            authenticationService: dependency.authenticationService,
            boardService: dependency.boardService
        )
        interactor.listener = listener
        print("✅ TeacherBuilder: Interactor 생성 완료")
        
        let boardCreationBuilder = BoardCreationBuilder(dependency: component)
        let studentManagementBuilder = StudentManagementBuilder(dependency: component)
        let photoModerationBuilder = PhotoModerationBuilder(dependency: component)
        let boardSettingsBuilder = BoardSettingsBuilder(dependency: component)
        
        let router = TeacherRouter(
            interactor: interactor,
            viewController: viewController,
            boardCreationBuilder: boardCreationBuilder,
            studentManagementBuilder: studentManagementBuilder,
            photoModerationBuilder: photoModerationBuilder,
            boardSettingsBuilder: boardSettingsBuilder
        )
        
        print("✅ TeacherBuilder: Router 생성 완료")
        print("🎯 TeacherBuilder: build 완료 - TeacherRIB 생성됨")
        
        return router
    }
}