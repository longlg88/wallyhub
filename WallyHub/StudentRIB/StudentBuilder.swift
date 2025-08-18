import RIBs

protocol StudentDependency: Dependency {
    var studentService: StudentService { get }
    var photoService: PhotoService { get }
    var boardService: BoardService { get }
}

final class StudentComponent: Component<StudentDependency>, QRScannerDependency, BoardJoinDependency, PhotoUploadDependency, MyPhotosDependency, MyParticipationsDependency {
    
    private let student: Student
    
    init(dependency: StudentDependency, student: Student) {
        self.student = student
        super.init(dependency: dependency)
    }
    
    var studentService: StudentService {
        return dependency.studentService
    }
    
    var photoService: PhotoService {
        return dependency.photoService
    }
    
    var boardService: BoardService {
        return dependency.boardService
    }
    
    // MyPhotosDependency와 MyParticipationsDependency 구현 - 실제 학생 정보 제공
    var studentId: String {
        // StudentService.getStudentParticipations는 학번으로 검색하므로 student.studentId 사용
        return student.studentId
    }
    
    var studentName: String {
        return student.name
    }
}

// MARK: - Builder

protocol StudentBuildable: Buildable {
    func build(withListener listener: StudentListener, student: Student) -> StudentRouting
}

final class StudentBuilder: Builder<StudentDependency>, StudentBuildable {

    override init(dependency: StudentDependency) {
        super.init(dependency: dependency)
    }

    func build(withListener listener: StudentListener, student: Student) -> StudentRouting {
        let component = StudentComponent(dependency: dependency, student: student)
        let viewController = StudentViewController()
        let interactor = StudentInteractor(presenter: viewController, student: student)
        interactor.listener = listener
        
        let qrScannerBuilder = QRScannerBuilder(dependency: component)
        let boardJoinBuilder = BoardJoinBuilder(dependency: component)
        let photoUploadBuilder = PhotoUploadBuilder(dependency: component)
        let myPhotosBuilder = MyPhotosBuilder(dependency: component)
        let myParticipationsBuilder = MyParticipationsBuilder(dependency: component)
        
        return StudentRouter(
            interactor: interactor,
            viewController: viewController,
            qrScannerBuilder: qrScannerBuilder,
            boardJoinBuilder: boardJoinBuilder,
            photoUploadBuilder: photoUploadBuilder,
            myPhotosBuilder: myPhotosBuilder,
            myParticipationsBuilder: myParticipationsBuilder
        )
    }
}