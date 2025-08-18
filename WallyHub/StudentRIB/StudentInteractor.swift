import RIBs
import RxSwift
import UIKit

// MARK: - Business Logic Protocols

protocol StudentPresentableListener: AnyObject {
    func didTapQRScanButton()
    func didTapMyBoardsButton()
    func didTapMyPhotosButton() 
    func didTapSignOutButton()
}

protocol StudentListener: AnyObject {
    func studentDidRequestSignOut()
    func studentDidCompleteFlow()
}

protocol StudentInteractable: Interactable, QRScannerListener, BoardJoinListener, PhotoUploadListener, MyPhotosListener, MyParticipationsListener {
    var router: StudentRouting? { get set }
    var listener: StudentListener? { get set }
}

protocol StudentPresentable: Presentable {
    var listener: StudentPresentableListener? { get set }
    func updateStudentInfo(student: Student)
}

final class StudentInteractor: PresentableInteractor<StudentPresentable>, StudentInteractable, StudentPresentableListener {

    weak var router: StudentRouting?
    weak var listener: StudentListener?
    
    private let student: Student

    init(presenter: StudentPresentable, student: Student) {
        self.student = student
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        print("🎓 StudentInteractor.didBecomeActive() - Student: \(student.name)")
        
        // 학생 대시보드를 메인 화면으로 표시 (art_wall 방식과 동일)
        // QR 스캐너는 사용자가 버튼을 눌렀을 때만 실행
        
        // 학생 정보를 UI에 전달
        print("📱 StudentInteractor: Updating presenter with student info")
        presenter.updateStudentInfo(student: student)
        print("✅ StudentInteractor: Presenter update completed")
    }

    override func willResignActive() {
        super.willResignActive()
    }
    
    // MARK: - StudentPresentableListener
    
    func didTapQRScanButton() {
        router?.routeToQRScanner()
    }
    
    func didTapMyBoardsButton() {
        router?.routeToMyParticipations()
    }
    
    func didTapMyPhotosButton() {
        print("📱 StudentInteractor: MyPhotos 버튼 클릭 - 학생: \(student.name)")
        // MyPhotos에는 기본적으로 빈 boardId와 함께 시작하고, 사용자가 게시판을 선택하면 해당 게시판의 사진들을 로드
        router?.routeToMyPhotos(boardId: "", studentId: student.studentId)
    }
    
    func didTapSignOutButton() {
        listener?.studentDidRequestSignOut()
    }
}

// MARK: - Child RIB Listeners

extension StudentInteractor: QRScannerListener {
    func qrScannerDidScanBoard(boardId: String) {
        print("📱 QRScanner: 게시판 스캔 완료 - boardId: \(boardId)")
        print("🎓 학생 게시판 참여 시작 - 학생: \(student.name), 학번: \(student.studentId)")
        
        router?.dismissQRScanner()
        
        // 학생을 게시판에 자동 참여시키고 게시판 내부로 이동
        Task { @MainActor in
            do {
                // StudentService를 통해 게시판 참여 처리
                let studentService = ServiceFactory.shared.studentService
                
                print("🔄 게시판 참여 처리 중...")
                print("🔍 학생 정보: ID=\(student.id), Name=\(student.name), StudentId=\(student.studentId)")
                
                // 먼저 현재 학생이 Firestore에 존재하는지 확인
                let existingStudent = try await studentService.getStudent(id: student.id)
                
                if existingStudent == nil {
                    print("🆕 학생이 Firestore에 없음 - 새로 생성합니다")
                    // 학생이 없으면 joinBoard 메서드로 새로 생성하면서 게시판 참여
                    let newStudent = try await studentService.joinBoard(
                        name: student.name,
                        studentId: student.studentId, 
                        boardId: boardId
                    )
                    print("✅ 새 학생 생성 및 게시판 참여 성공: \(newStudent.name)")
                } else {
                    print("👤 기존 학생 발견 - 게시판에 추가합니다")
                    // 기존 학생이면 게시판에 추가
                    try await studentService.addStudentToBoard(studentId: student.id, boardId: boardId)
                    print("✅ 기존 학생 게시판 참여 성공!")
                }
                
                // 게시판 참여 성공 후 사진 업로드 화면으로 이동
                router?.routeToPhotoUpload(boardId: boardId, studentId: student.studentId)
                
            } catch {
                print("❌ 게시판 참여 실패: \(error)")
                
                // 에러 처리 - 사용자에게 알림
                if let viewController = presenter as? StudentViewController {
                    await MainActor.run {
                        let alert = UIAlertController(
                            title: "게시판 참여 실패",
                            message: "게시판에 참여할 수 없습니다. 다시 시도해주세요.",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "확인", style: .default))
                        viewController.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    func qrScannerDidCancel() {
        print("📱 QRScanner: 사용자가 취소")
        router?.dismissQRScanner()
    }
}

extension StudentInteractor: BoardJoinListener {
    func boardJoinDidComplete(boardId: String) {
        router?.dismissBoardJoin()
        router?.routeToPhotoUpload(boardId: boardId, studentId: student.studentId)
    }
    
    func boardJoinDidCancel() {
        router?.dismissBoardJoin()
        router?.routeToQRScanner()
    }
}

extension StudentInteractor: PhotoUploadListener {
    func photoUploadDidComplete() {
        print("📸 PhotoUpload: 업로드 완료 - 내 참여 게시판으로 이동")
        router?.dismissPhotoUpload()
        
        // 사진 업로드 완료 후 "내가 참여한 게시판" 화면으로 이동
        // 사용자가 방금 참여한 게시판을 확인할 수 있음
        router?.routeToMyParticipations()
    }
    
    func photoUploadDidCancel() {
        print("📸 PhotoUpload: 사용자가 취소")
        router?.dismissPhotoUpload()
    }
}

extension StudentInteractor: MyPhotosListener {
    func myPhotosDidRequestPhotoUpload(boardId: String) {
        print("📸 StudentInteractor: MyPhotos에서 사진 업로드 요청 받음")
        
        // MyPhotos에서 저장된 이미지 가져오기
        let selectedImage = router?.getPendingImageFromMyPhotos()
        
        // 🚨 CRITICAL FIX: MyPhotos를 먼저 dismiss하고 PhotoUpload present
        router?.dismissMyPhotos()
        
        // dismiss 완료 후 PhotoUpload 실행하도록 지연
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }
            
            if let image = selectedImage {
                print("✅ StudentInteractor: 이미지와 함께 PhotoUpload 시작 - 크기: \(image.size)")
                self.router?.routeToPhotoUpload(boardId: boardId, studentId: self.student.studentId, preSelectedImage: image)
            } else {
                print("⚠️ StudentInteractor: 저장된 이미지가 없음 - 일반 PhotoUpload로 이동")
                self.router?.routeToPhotoUpload(boardId: boardId, studentId: self.student.studentId)
            }
        }
    }
    
    func myPhotosDidComplete() {
        router?.dismissMyPhotos()
    }
}

extension StudentInteractor: MyParticipationsListener {
    func myParticipationsDidComplete() {
        router?.dismissMyParticipations()
    }
    
    func myParticipationsDidSelectBoard(boardId: String, boardTitle: String) {
        print("📋 StudentInteractor: 게시판 선택됨 - \(boardTitle) (ID: \(boardId))")
        router?.dismissMyParticipations()
        router?.routeToMyPhotos(boardId: boardId, studentId: student.studentId)
    }
}

