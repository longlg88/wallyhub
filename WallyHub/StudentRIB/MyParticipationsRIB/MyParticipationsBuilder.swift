import RIBs

// MARK: - Dependency & Component Protocols

protocol MyParticipationsDependency: Dependency {
    var studentService: StudentService { get }
    var studentId: String { get }
    var studentName: String { get }
}

final class MyParticipationsComponent: Component<MyParticipationsDependency> {
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var studentId: String {
        return dependency.studentId
    }
    
    var studentName: String {
        return dependency.studentName
    }
}

protocol MyParticipationsBuildable: Buildable {
    func build(withListener listener: MyParticipationsListener?) -> MyParticipationsRouting
}

final class MyParticipationsBuilder: Builder<MyParticipationsDependency>, MyParticipationsBuildable {
    
    override init(dependency: MyParticipationsDependency) {
        super.init(dependency: dependency)
    }
    
    func build(withListener listener: MyParticipationsListener?) -> MyParticipationsRouting {
        let component = MyParticipationsComponent(dependency: dependency)
        let viewController = MyParticipationsViewController()
        let interactor = MyParticipationsInteractor(
            presenter: viewController,
            studentService: component.studentService,
            studentId: component.studentId,
            studentName: component.studentName
        )
        interactor.listener = listener
        
        return MyParticipationsRouter(
            interactor: interactor,
            viewController: viewController
        )
    }
}