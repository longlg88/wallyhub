import RIBs

// MARK: - Navigation Protocols

protocol BoardJoinRouting: ViewableRouting {
    // Add routing methods if needed
}

protocol BoardJoinViewControllable: ViewControllable {
    // Add view controller interface methods
}

final class BoardJoinRouter: ViewableRouter<BoardJoinInteractable, BoardJoinViewControllable>, BoardJoinRouting {

    override init(interactor: BoardJoinInteractable, viewController: BoardJoinViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}