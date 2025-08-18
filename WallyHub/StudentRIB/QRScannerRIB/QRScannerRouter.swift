import RIBs

// MARK: - Navigation Protocols

protocol QRScannerRouting: ViewableRouting {
    // Add routing methods if needed
}

protocol QRScannerViewControllable: ViewControllable {
    // Add view controller interface methods
}

final class QRScannerRouter: ViewableRouter<QRScannerInteractable, QRScannerViewControllable>, QRScannerRouting {

    override init(interactor: QRScannerInteractable, viewController: QRScannerViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}