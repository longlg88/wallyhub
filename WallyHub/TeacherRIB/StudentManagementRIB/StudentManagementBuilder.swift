import RIBs

protocol StudentManagementDependency: Dependency {
    var studentService: StudentService { get }
    var boardService: BoardService { get }
}

final class StudentManagementComponent: Component<StudentManagementDependency> {
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
}

// MARK: - Builder

protocol StudentManagementBuildable: Buildable {
    func build(withListener listener: StudentManagementListener, boardId: String) -> StudentManagementRouting
}

final class StudentManagementBuilder: Builder<StudentManagementDependency>, StudentManagementBuildable {

    override init(dependency: StudentManagementDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: StudentManagementListener, boardId: String) -> StudentManagementRouting {
        let component = StudentManagementComponent(dependency: dependency)
        let viewController = StudentManagementViewController()
        let interactor = StudentManagementInteractor(
            presenter: viewController,
            studentService: component.studentService,
            boardService: component.boardService,
            boardId: boardId
        )
        interactor.listener = listener
        
        return StudentManagementRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
}