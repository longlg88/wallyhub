import RIBs

// MARK: - Navigation Protocols

protocol BoardCreationRouting: ViewableRouting {
    // Add routing methods if needed
}

final class BoardCreationRouter: ViewableRouter<BoardCreationInteractable, BoardCreationViewControllable>, BoardCreationRouting {
    
    override init(interactor: BoardCreationInteractable, viewController: BoardCreationViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    // MARK: - BoardCreationRouting
    
    // Add any routing methods specific to BoardCreation if needed
}

// MARK: - ViewControllable Protocol

protocol BoardCreationViewControllable: ViewControllable {
    // Add any view controller specific methods if needed
}