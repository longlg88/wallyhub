import RIBs

protocol RoleSelectionDependency: Dependency {
    // Add dependencies if needed
}

final class RoleSelectionComponent: Component<RoleSelectionDependency> {
    // Add shared dependencies if needed
}

// MARK: - Builder

protocol RoleSelectionBuildable: Buildable {
    func build(withListener listener: RoleSelectionListener) -> RoleSelectionRouting
}

final class RoleSelectionBuilder: Builder<RoleSelectionDependency>, RoleSelectionBuildable {

    override init(dependency: RoleSelectionDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: RoleSelectionListener) -> RoleSelectionRouting {
        let viewController = RoleSelectionViewController()
        let interactor = RoleSelectionInteractor(presenter: viewController)
        interactor.listener = listener
        
        return RoleSelectionRouter(interactor: interactor, viewController: viewController)
    }
}