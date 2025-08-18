import RIBs

protocol StudentLoginDependency: Dependency {
    var studentService: StudentService { get }
    var boardService: BoardService { get }
}

final class StudentLoginComponent: Component<StudentLoginDependency> {
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    // MARK: - QRScannerDependency
    var qrScannerBuilder: QRScannerBuildable {
        return QRScannerBuilder(dependency: self)
    }
    
    // MARK: - BoardJoinDependency  
    var boardJoinBuilder: BoardJoinBuildable {
        return BoardJoinBuilder(dependency: self)
    }
}

// MARK: - QRScannerDependency
extension StudentLoginComponent: QRScannerDependency {
    // boardService 이미 위에서 정의됨
}

// MARK: - BoardJoinDependency
extension StudentLoginComponent: BoardJoinDependency {
    // studentService, boardService 이미 위에서 정의됨
}

// MARK: - Builder

protocol StudentLoginBuildable: Buildable {
    func build(withListener listener: StudentLoginListener) -> StudentLoginRouting
}

final class StudentLoginBuilder: Builder<StudentLoginDependency>, StudentLoginBuildable {

    override init(dependency: StudentLoginDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: StudentLoginListener) -> StudentLoginRouting {
        let component = StudentLoginComponent(dependency: dependency)
        let viewController = StudentLoginViewController()
        let interactor = StudentLoginInteractor(
            presenter: viewController,
            studentService: component.studentService
        )
        interactor.listener = listener
        
        return StudentLoginRouter(
            interactor: interactor,
            viewController: viewController,
            qrScannerBuilder: component.qrScannerBuilder,
            boardJoinBuilder: component.boardJoinBuilder
        )
    }
}