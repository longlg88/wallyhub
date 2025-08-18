import RIBs

protocol MyPhotosDependency: Dependency {
    var photoService: PhotoService { get }
    var studentService: StudentService { get }
    var boardService: BoardService { get }
    var studentName: String { get }
}

final class MyPhotosComponent: Component<MyPhotosDependency> {
    
    var photoService: PhotoService {
        return dependency.photoService
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    var studentName: String {
        return dependency.studentName
    }
}

// MARK: - Builder

protocol MyPhotosBuildable: Buildable {
    func build(withListener listener: MyPhotosListener, boardId: String, studentId: String) -> MyPhotosRouting
}

final class MyPhotosBuilder: Builder<MyPhotosDependency>, MyPhotosBuildable {

    override init(dependency: MyPhotosDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: MyPhotosListener, boardId: String, studentId: String) -> MyPhotosRouting {
        let component = MyPhotosComponent(dependency: dependency)
        let viewController = MyPhotosViewController()
        let interactor = MyPhotosInteractor(
            presenter: viewController,
            photoService: component.photoService,
            studentService: component.studentService,
            boardService: component.boardService,
            studentName: component.studentName,
            boardId: boardId,
            studentId: studentId
        )
        interactor.listener = listener
        
        return MyPhotosRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
}