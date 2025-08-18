import RIBs
import UIKit

protocol PhotoUploadDependency: Dependency {
    var photoService: PhotoService { get }
    var studentService: StudentService { get }
    var boardService: BoardService { get }
}

final class PhotoUploadComponent: Component<PhotoUploadDependency> {
    
    var photoService: PhotoService {
        return dependency.photoService
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
}

// MARK: - Builder

protocol PhotoUploadBuildable: Buildable {
    func build(withListener listener: PhotoUploadListener, boardId: String, currentStudentId: String) -> PhotoUploadRouting
    func build(withListener listener: PhotoUploadListener, boardId: String, currentStudentId: String, preSelectedImage: UIImage) -> PhotoUploadRouting
}

final class PhotoUploadBuilder: Builder<PhotoUploadDependency>, PhotoUploadBuildable {

    override init(dependency: PhotoUploadDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: PhotoUploadListener, boardId: String, currentStudentId: String) -> PhotoUploadRouting {
        let component = PhotoUploadComponent(dependency: dependency)
        let viewController = PhotoUploadViewController()
        let interactor = PhotoUploadInteractor(
            presenter: viewController,
            photoService: component.photoService,
            studentService: component.studentService,
            boardService: component.boardService,
            boardId: boardId,
            currentStudentId: currentStudentId
        )
        interactor.listener = listener
        
        return PhotoUploadRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
    
    func build(withListener listener: PhotoUploadListener, boardId: String, currentStudentId: String, preSelectedImage: UIImage) -> PhotoUploadRouting {
        let component = PhotoUploadComponent(dependency: dependency)
        let viewController = PhotoUploadViewController()
        let interactor = PhotoUploadInteractor(
            presenter: viewController,
            photoService: component.photoService,
            studentService: component.studentService,
            boardService: component.boardService,
            boardId: boardId,
            currentStudentId: currentStudentId,
            preSelectedImage: preSelectedImage
        )
        interactor.listener = listener
        
        return PhotoUploadRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
}

