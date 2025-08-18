import RIBs

protocol QRScannerDependency: Dependency {
    var boardService: BoardService { get }
}

final class QRScannerComponent: Component<QRScannerDependency> {
    var boardService: BoardService {
        return dependency.boardService
    }
}

// MARK: - Builder

protocol QRScannerBuildable: Buildable {
    func build(withListener listener: QRScannerListener) -> ViewableRouting
}

final class QRScannerBuilder: Builder<QRScannerDependency>, QRScannerBuildable {

    override init(dependency: QRScannerDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: QRScannerListener) -> ViewableRouting {
        let component = QRScannerComponent(dependency: dependency)
        let viewController = QRScannerViewController()
        let interactor = QRScannerInteractor(
            presenter: viewController,
            boardService: component.boardService
        )
        interactor.listener = listener
        
        return QRScannerRouter(interactor: interactor, viewController: viewController)
    }
}