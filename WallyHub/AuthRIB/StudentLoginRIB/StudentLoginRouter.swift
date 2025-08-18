import RIBs

// MARK: - Navigation Protocols

protocol StudentLoginRouting: ViewableRouting {
    func routeToQRScanner()
    func dismissQRScanner()
    func dismissQRScanner(completion: @escaping () -> Void)
    func routeToBoardJoin(boardId: String)
    func dismissBoardJoin()
}

protocol StudentLoginViewControllable: ViewControllable {
    func present(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable)
    func dismiss(viewController: ViewControllable, completion: @escaping () -> Void)
}

final class StudentLoginRouter: ViewableRouter<StudentLoginInteractable, StudentLoginViewControllable>, StudentLoginRouting {

    // MARK: - Child RIBs
    private let qrScannerBuilder: QRScannerBuildable
    private let boardJoinBuilder: BoardJoinBuildable
    
    private var qrScannerRouter: QRScannerRouting?
    private var boardJoinRouter: BoardJoinRouting?

    init(
        interactor: StudentLoginInteractable,
        viewController: StudentLoginViewControllable,
        qrScannerBuilder: QRScannerBuildable,
        boardJoinBuilder: BoardJoinBuildable
    ) {
        self.qrScannerBuilder = qrScannerBuilder
        self.boardJoinBuilder = boardJoinBuilder
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    // MARK: - StudentLoginRouting
    
    func routeToQRScanner() {
        guard qrScannerRouter == nil else { return }
        
        let qrScanner = qrScannerBuilder.build(withListener: interactor)
        guard let qrScannerRouting = qrScanner as? QRScannerRouting else { return }
        qrScannerRouter = qrScannerRouting
        
        attachChild(qrScanner)
        viewController.present(viewController: qrScanner.viewControllable)
    }
    
    func dismissQRScanner() {
        guard let qrScanner = qrScannerRouter else { return }
        
        viewController.dismiss(viewController: qrScanner.viewControllable)
        detachChild(qrScanner)
        qrScannerRouter = nil
    }
    
    func dismissQRScanner(completion: @escaping () -> Void) {
        guard let qrScanner = qrScannerRouter else { 
            completion()
            return 
        }
        
        viewController.dismiss(viewController: qrScanner.viewControllable) {
            self.detachChild(qrScanner)
            self.qrScannerRouter = nil
            completion()
        }
    }
    
    func routeToBoardJoin(boardId: String) {
        guard boardJoinRouter == nil else { return }
        
        let boardJoin = boardJoinBuilder.build(withListener: interactor, boardId: boardId)
        guard let boardJoinRouting = boardJoin as? BoardJoinRouting else { return }
        boardJoinRouter = boardJoinRouting
        
        attachChild(boardJoin)
        viewController.present(viewController: boardJoin.viewControllable)
    }
    
    func dismissBoardJoin() {
        guard let boardJoin = boardJoinRouter else { return }
        
        viewController.dismiss(viewController: boardJoin.viewControllable)
        detachChild(boardJoin)
        boardJoinRouter = nil
    }
}