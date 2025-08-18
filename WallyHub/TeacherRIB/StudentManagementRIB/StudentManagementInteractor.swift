import RIBs
import RxSwift

// MARK: - Business Logic Protocols

protocol StudentManagementListener: AnyObject {
    func studentManagementDidComplete()
}

protocol StudentManagementPresentableListener: AnyObject {
    func viewDidLoad()
    func didRequestStudentList()
    func didTapClose()
    func didTapStudent(_ student: Student)
    func didTapRemoveStudent(_ student: Student)
}

protocol StudentManagementInteractable: Interactable {
    var router: StudentManagementRouting? { get set }
    var listener: StudentManagementListener? { get set }
}

protocol StudentManagementPresentable: Presentable {
    var listener: StudentManagementPresentableListener? { get set }
    func showStudents(_ students: [Student])
    func showLoading()
    func hideLoading()
    func showError(_ message: String)
}

final class StudentManagementInteractor: PresentableInteractor<StudentManagementPresentable>, StudentManagementInteractable, StudentManagementPresentableListener {

    weak var router: StudentManagementRouting?
    weak var listener: StudentManagementListener?
    
    private let studentService: StudentService
    private let boardService: BoardService
    private let boardId: String

    init(
        presenter: StudentManagementPresentable,
        studentService: StudentService,
        boardService: BoardService,
        boardId: String
    ) {
        self.studentService = studentService
        self.boardService = boardService
        self.boardId = boardId
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - StudentManagementPresentableListener
    
    func viewDidLoad() {
        didRequestStudentList()
    }
    
    func didRequestStudentList() {
        presenter.showLoading()
        
        Task {
            do {
                let students = try await studentService.getStudentsForBoard(boardId: boardId)
                await MainActor.run {
                    self.presenter.hideLoading()
                    self.presenter.showStudents(students)
                }
            } catch {
                await MainActor.run {
                    self.presenter.hideLoading()
                    self.presenter.showError(error.localizedDescription)
                }
            }
        }
    }
    
    func didTapClose() {
        listener?.studentManagementDidComplete()
    }
    
    func didTapStudent(_ student: Student) {
        // Show student details or perform action
        // TODO: Implement student detail navigation or action
    }
    
    func didTapRemoveStudent(_ student: Student) {
        // Remove student from board
        Task {
            do {
                try await studentService.removeStudentFromBoard(studentId: student.id, boardId: boardId)
                // Refresh the student list
                didRequestStudentList()
            } catch {
                await MainActor.run {
                    self.presenter.showError("학생 제거 중 오류가 발생했습니다: \(error.localizedDescription)")
                }
            }
        }
    }
}