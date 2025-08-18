import RIBs

protocol BoardJoinDependency: Dependency {
    var studentService: StudentService { get }
    var boardService: BoardService { get }
}

final class BoardJoinComponent: Component<BoardJoinDependency> {
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
}

// MARK: - Builder

protocol BoardJoinBuildable: Buildable {
    func build(withListener listener: BoardJoinListener, boardId: String) -> ViewableRouting
}

final class BoardJoinBuilder: Builder<BoardJoinDependency>, BoardJoinBuildable {

    override init(dependency: BoardJoinDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: BoardJoinListener, boardId: String) -> ViewableRouting {
        let component = BoardJoinComponent(dependency: dependency)
        let viewController = BoardJoinViewController()
        let interactor = BoardJoinInteractor(
            presenter: viewController,
            studentService: component.studentService,
            boardService: component.boardService,
            boardId: boardId
        )
        interactor.listener = listener
        
        return BoardJoinRouter(interactor: interactor, viewController: viewController)
    }
}