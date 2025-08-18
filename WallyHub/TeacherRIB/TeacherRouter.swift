import RIBs
import SwiftUI

// MARK: - Navigation Protocols

protocol TeacherRouting: ViewableRouting {
    func routeToBoardCreation()
    func routeToStudentManagement(boardId: String)
    func routeToPhotoModeration(boardId: String)
    func routeToBoardSettings(boardId: String)
    func dismissBoardCreation()
    func dismissStudentManagement()
    func dismissPhotoModeration()
    func dismissBoardSettings()
    func dismissChild()
}

protocol TeacherViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss()
}

final class TeacherRouter: ViewableRouter<TeacherInteractable, TeacherViewControllable>, TeacherRouting {
    
    private let boardCreationBuilder: BoardCreationBuildable
    private let studentManagementBuilder: StudentManagementBuildable
    private let photoModerationBuilder: PhotoModerationBuildable
    private let boardSettingsBuilder: BoardSettingsBuildable
    
    private var boardCreationRouter: BoardCreationRouting?
    private var studentManagementRouter: StudentManagementRouting?
    private var photoModerationRouter: PhotoModerationRouting?
    private var boardSettingsRouter: BoardSettingsRouting?
    
    init(
        interactor: TeacherInteractable,
        viewController: TeacherViewControllable,
        boardCreationBuilder: BoardCreationBuildable,
        studentManagementBuilder: StudentManagementBuildable,
        photoModerationBuilder: PhotoModerationBuildable,
        boardSettingsBuilder: BoardSettingsBuildable
    ) {
        self.boardCreationBuilder = boardCreationBuilder
        self.studentManagementBuilder = studentManagementBuilder
        self.photoModerationBuilder = photoModerationBuilder
        self.boardSettingsBuilder = boardSettingsBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    func routeToBoardCreation() {
        dismissCurrentChild()
        
        guard boardCreationRouter == nil else { return }
        
        let router = boardCreationBuilder.build(withListener: interactor)
        boardCreationRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissBoardCreation() {
        if let router = boardCreationRouter {
            detachChild(router)
            boardCreationRouter = nil
            viewController.dismiss()
        }
    }
    
    func routeToStudentManagement(boardId: String) {
        dismissCurrentChild()
        
        guard studentManagementRouter == nil else { return }
        
        let router = studentManagementBuilder.build(withListener: interactor, boardId: boardId)
        studentManagementRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissStudentManagement() {
        if let router = studentManagementRouter {
            detachChild(router)
            studentManagementRouter = nil
            viewController.dismiss()
        }
    }
    
    func routeToPhotoModeration(boardId: String) {
        dismissCurrentChild()
        
        guard photoModerationRouter == nil else { return }
        
        let router = photoModerationBuilder.build(withListener: interactor, boardId: boardId)
        photoModerationRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissPhotoModeration() {
        if let router = photoModerationRouter {
            detachChild(router)
            photoModerationRouter = nil
            viewController.dismiss()
        }
    }
    
    func routeToBoardSettings(boardId: String) {
        dismissCurrentChild()
        
        guard boardSettingsRouter == nil else { return }
        
        let router = boardSettingsBuilder.build(withListener: interactor, boardId: boardId)
        boardSettingsRouter = router
        attachChild(router)
        viewController.present(viewController: router.viewControllable)
    }
    
    func dismissBoardSettings() {
        if let router = boardSettingsRouter {
            detachChild(router)
            boardSettingsRouter = nil
            viewController.dismiss()
        }
    }
    
    func dismissChild() {
        dismissCurrentChild()
    }
    
    private func dismissCurrentChild() {
        if let router = boardCreationRouter {
            detachChild(router)
            boardCreationRouter = nil
            viewController.dismiss()
        } else if let router = studentManagementRouter {
            detachChild(router)
            studentManagementRouter = nil
            viewController.dismiss()
        } else if let router = photoModerationRouter {
            detachChild(router)
            photoModerationRouter = nil
            viewController.dismiss()
        } else if let router = boardSettingsRouter {
            detachChild(router)
            boardSettingsRouter = nil
            viewController.dismiss()
        }
    }
}

