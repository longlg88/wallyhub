import RIBs
import Foundation

// MARK: - Business Logic Protocols

protocol MyParticipationsListener: AnyObject {
    func myParticipationsDidComplete()
    func myParticipationsDidSelectBoard(boardId: String, boardTitle: String)
}

protocol MyParticipationsPresentableListener: AnyObject {
    func viewDidLoad()
    func didTapClose()
    func didTapRefresh()
    func didSelectParticipation(_ participation: StudentParticipation)
}

protocol MyParticipationsInteractable: Interactable {
    var router: MyParticipationsRouting? { get set }
    var listener: MyParticipationsListener? { get set }
}

final class MyParticipationsInteractor: PresentableInteractor<MyParticipationsPresentable>, 
                                       MyParticipationsInteractable, 
                                       MyParticipationsPresentableListener {
    
    weak var router: MyParticipationsRouting?
    weak var listener: MyParticipationsListener?
    
    private let studentService: StudentService
    private let studentId: String
    private let studentName: String
    private var participations: [StudentParticipation] = []
    
    init(
        presenter: MyParticipationsPresentable,
        studentService: StudentService,
        studentId: String,
        studentName: String
    ) {
        self.studentService = studentService
        self.studentId = studentId
        self.studentName = studentName
        super.init(presenter: presenter)
        presenter.listener = self
    }
    
    deinit {
        print("🗑️ MyParticipationsInteractor deinit - 메모리 해제")
    }
    
    override func willResignActive() {
        super.willResignActive()
        print("🔄 MyParticipationsInteractor willResignActive - 리소스 정리")
        stopObservingParticipations()
    }
    
    func viewDidLoad() {
        print("📱 MyParticipationsInteractor - viewDidLoad 시작")
        presenter.showLoading()
        loadParticipations()
    }
    
    func didTapClose() {
        print("❌ MyParticipationsInteractor - 닫기 버튼 탭")
        listener?.myParticipationsDidComplete()
    }
    
    func didTapRefresh() {
        print("🔄 MyParticipationsInteractor - 새로고침 시작")
        presenter.showLoading()
        loadParticipations()
    }
    
    func didSelectParticipation(_ participation: StudentParticipation) {
        print("📋 MyParticipationsInteractor - 게시판 선택: \(participation.boardTitle)")
        listener?.myParticipationsDidSelectBoard(
            boardId: participation.boardId,
            boardTitle: participation.boardTitle
        )
    }
    
    // MARK: - Private Methods
    
    private func loadParticipations() {
        Task { @MainActor in
            do {
                print("🔍 학생 참여 게시판 로드 시작 - studentId: \(studentId), studentName: \(studentName)")
                
                // StudentService에서 실제 참여 데이터 로드
                let participations = try await studentService.getStudentParticipations(userId: studentId)
                
                self.participations = participations
                
                if participations.isEmpty {
                    print("📋 참여 중인 게시판이 없습니다")
                    presenter.showEmptyState()
                } else {
                    print("✅ 참여 게시판 \(participations.count)개 로드 완료")
                    for participation in participations {
                        print("   📋 \(participation.boardTitle) - 사진 \(participation.photoCount)개")
                    }
                    presenter.showParticipations(participations)
                }
                
            } catch {
                print("❌ 참여 게시판 로드 실패: \(error.localizedDescription)")
                presenter.showError("참여 게시판을 불러올 수 없습니다: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopObservingParticipations() {
        print("🛑 MyParticipationsInteractor - 실시간 모니터링 중지")
        // TODO: Firebase 리스너 정리 구현
    }
}