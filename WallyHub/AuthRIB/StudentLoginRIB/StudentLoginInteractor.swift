import RIBs
import RxSwift
import Foundation

// MARK: - Business Logic Protocols

protocol StudentLoginPresentableListener: AnyObject {
    func didTapLogin(name: String, studentId: String, password: String)
    func didTapQRScan()
    func didTapBackButton()
}

protocol StudentLoginListener: AnyObject {
    func studentLoginDidComplete(student: Student)
    func studentLoginDidRequestBack()
}

protocol StudentLoginInteractable: Interactable, QRScannerListener, BoardJoinListener {
    var router: StudentLoginRouting? { get set }
    var listener: StudentLoginListener? { get set }
}

protocol StudentLoginPresentable: Presentable {
    var listener: StudentLoginPresentableListener? { get set }
    func showLoginError(_ message: String)
}

final class StudentLoginInteractor: PresentableInteractor<StudentLoginPresentable>, StudentLoginInteractable, StudentLoginPresentableListener {

    weak var router: StudentLoginRouting?
    weak var listener: StudentLoginListener?
    
    private let studentService: StudentService

    init(
        presenter: StudentLoginPresentable,
        studentService: StudentService
    ) {
        self.studentService = studentService
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - StudentLoginPresentableListener
    
    func didTapLogin(name: String, studentId: String, password: String) {
        print("📤 StudentLoginInteractor: 실제 DB 로그인 처리 시작 - Name: \(name), StudentID: \(studentId)")
        
        // 실제 StudentService를 통해 DB에서 로그인 처리
        Task { @MainActor in
            do {
                let student = try await studentService.loginStudent(
                    name: name,
                    studentId: studentId, 
                    password: password
                )
                
                print("✅ StudentLoginInteractor: DB 로그인 성공 - \(student.name)")
                listener?.studentLoginDidComplete(student: student)
                
            } catch {
                print("❌ StudentLoginInteractor: DB 로그인 실패 - \(error)")
                
                // 로그인 실패 처리
                await MainActor.run {
                    presenter.showLoginError("로그인에 실패했습니다. 이름과 학번을 확인해주세요.")
                }
            }
        }
    }
    
    func didTapQRScan() {
        print("📤 StudentLoginInteractor: QR 스캔 요청 - QRScannerRIB로 라우팅")
        router?.routeToQRScanner()
    }
    
    func didTapBackButton() {
        print("📤 StudentLoginInteractor: 뒤로가기 요청을 AuthInteractor로 전달")
        listener?.studentLoginDidRequestBack()
    }
    
    // MARK: - QRScannerListener
    
    func qrScannerDidScanBoard(boardId: String) {
        print("✅ StudentLoginInteractor: QR 스캔 성공 - BoardID: \(boardId)")
        
        // dismiss 완료 후 새 화면 띄우기
        router?.dismissQRScanner { [weak self] in
            self?.router?.routeToBoardJoin(boardId: boardId)
        }
    }
    
    func qrScannerDidCancel() {
        print("📤 StudentLoginInteractor: QR 스캔 취소")
        router?.dismissQRScanner()
    }
    
    // MARK: - BoardJoinListener
    
    func boardJoinDidComplete(boardId: String) {
        print("✅ StudentLoginInteractor: 게시판 참여 완료 - BoardID: \(boardId)")
        router?.dismissBoardJoin()
        
        // 새로 가입된 학생 정보를 가져와서 전달
        // BoardJoinRIB에서 학생 정보를 전달받도록 개선 필요
        Task { @MainActor in
            do {
                // 최근에 가입된 학생 정보를 가져오거나,
                // BoardJoin에서 Student 객체를 직접 전달받도록 수정 필요
                let students = try await studentService.getStudentsForBoard(boardId: boardId)
                if let lastStudent = students.last {
                    listener?.studentLoginDidComplete(student: lastStudent)
                }
            } catch {
                print("❌ StudentLoginInteractor: 학생 정보 가져오기 실패 - \(error)")
            }
        }
    }
    
    func boardJoinDidCancel() {
        print("📤 StudentLoginInteractor: 게시판 참여 취소")
        router?.dismissBoardJoin()
    }
}

