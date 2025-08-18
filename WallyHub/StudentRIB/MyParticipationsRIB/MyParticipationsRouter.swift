import RIBs

// MARK: - Navigation Protocols

protocol MyParticipationsRouting: ViewableRouting {
    // 필요한 경우 추가 라우팅 메서드 정의
}

final class MyParticipationsRouter: ViewableRouter<MyParticipationsInteractable, MyParticipationsViewControllable>, 
                                   MyParticipationsRouting {
    
    override init(
        interactor: MyParticipationsInteractable, 
        viewController: MyParticipationsViewControllable
    ) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
    
    deinit {
        print("🗑️ MyParticipationsRouter deinit - 메모리 해제")
    }
}