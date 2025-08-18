import Foundation
import FirebaseFirestore
import FirebaseCore
import CoreImage

public protocol BoardService {
    func createBoard(title: String, adminId: String, teacherId: String?, settings: BoardSettings) async throws -> Board
    func updateBoard(_ board: Board) async throws
    func getAdminBoards(adminId: String) async throws -> [Board]
    func getAllBoards() async throws -> [Board]
    func getBoard(id: String) async throws -> Board
    func getBoardByQRCode(_ qrCode: String) async throws -> Board?
    func deleteBoard(boardId: String) async throws
    func generateQRCode(for boardId: String) -> String
    func regenerateQRCode(for boardId: String) async throws -> Board
    func deactivateBoard(boardId: String) async throws
    
    // 교사용 메서드 추가
    func getBoardsForTeacher(teacherId: String) async throws -> [Board]
    func getBoardsWithStatsForTeacher(teacherId: String) async throws -> [BoardWithStats]
    
    // 통계 계산 메서드
    func calculateStudentCount(for boardId: String) async throws -> Int
    func calculatePhotoCount(for boardId: String) async throws -> Int
}


public class FirebaseBoardService: BoardService, ObservableObject {
    @Published public var boards: [Board] = []
    
    private lazy var db: Firestore = {
        print("🔥 BoardService Firestore 초기화: 데이터베이스 wallydb")
        let firestore = Firestore.firestore(database: "wallydb")
        print("✅ BoardService Firestore 연결 완료: wallydb 데이터베이스")
        return firestore
    }()
    private let boardsCollection = "boards"
    
    public init() {}
    
    // MARK: - Board CRUD Operations
    
    public func createBoard(title: String, adminId: String, teacherId: String? = nil, settings: BoardSettings) async throws -> Board {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.networkError
        }
        
        // 입력 검증
        try Board.validateForCreation(title: title, adminId: adminId, teacherId: teacherId, settings: settings)
        
        // 새 게시판 생성
        let boardId = UUID().uuidString
        let qrCode = generateQRCode(for: boardId)
        let board = Board(
            id: boardId,
            title: title,
            adminId: adminId,
            teacherId: teacherId,
            qrCode: qrCode,
            settings: settings
        )
        
        do {
            // Firestore에 저장
            let boardData = board.toFirestoreDictionary()
            print("🔥 BoardService: Firestore에 게시판 저장 시작 - ID: \(board.id), Title: \(board.title)")
            print("📝 BoardService: 저장할 데이터: \(boardData)")
            
            try await db.collection(boardsCollection).document(board.id).setData(boardData)
            print("✅ BoardService: Firestore 저장 성공 - boards 컬렉션에 저장됨")
            
            // 로컬 상태 업데이트
            await MainActor.run {
                self.boards.append(board)
                print("📱 BoardService: 로컬 상태 업데이트 완료 - 총 게시판 수: \(self.boards.count)")
            }
            
            return board
        } catch {
            print("❌ BoardService: Firestore 저장 실패 - \(error)")
            throw mapFirestoreError(error)
        }
    }
    
    public func updateBoard(_ board: Board) async throws {
        // 게시판 검증
        try board.validate()
        
        do {
            let boardData = board.toFirestoreDictionary()
            try await db.collection(boardsCollection).document(board.id).updateData(boardData)
            
            // 로컬 상태 업데이트
            await MainActor.run {
                if let index = self.boards.firstIndex(where: { $0.id == board.id }) {
                    self.boards[index] = board
                }
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    public func getAdminBoards(adminId: String) async throws -> [Board] {
        guard !adminId.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            let query = db.collection(boardsCollection)
                .whereField("adminId", isEqualTo: adminId)
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            let boards = try snapshot.documents.compactMap { document in
                try Board.fromFirestoreDictionary(document.data())
            }
            
            // 로컬 상태 업데이트
            await MainActor.run {
                self.boards = boards
            }
            
            return boards
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    public func getBoard(id: String) async throws -> Board {
        guard !id.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            let document = try await db.collection(boardsCollection).document(id).getDocument()
            
            guard let data = document.data() else {
                throw WallyError.boardNotFound
            }
            
            return try Board.fromFirestoreDictionary(data)
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    public func getBoardByQRCode(_ qrCode: String) async throws -> Board? {
        guard !qrCode.isEmpty else {
            throw WallyError.invalidQRCode
        }
        
        do {
            let query = db.collection(boardsCollection)
                .whereField("qrCode", isEqualTo: qrCode)
                .whereField("isActive", isEqualTo: true)
                .limit(to: 1)
            
            let snapshot = try await query.getDocuments()
            
            guard let document = snapshot.documents.first else {
                return nil
            }
            
            return try Board.fromFirestoreDictionary(document.data())
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    public func deleteBoard(boardId: String) async throws {
        guard !boardId.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            try await db.collection(boardsCollection).document(boardId).delete()
            
            // 로컬 상태 업데이트
            await MainActor.run {
                self.boards.removeAll { $0.id == boardId }
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - QR Code Management
    
    public func generateQRCode(for boardId: String) -> String {
        // QR 코드는 게시판 ID와 타임스탬프를 조합하여 고유성 보장
        let timestamp = Int(Date().timeIntervalSince1970)
        return "\(boardId)_\(timestamp)"
    }
    
    public func regenerateQRCode(for boardId: String) async throws -> Board {
        guard !boardId.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            // 새 QR 코드 생성
            let newQRCode = generateQRCode(for: boardId)
            
            // Firestore에서 게시판 업데이트
            try await db.collection(boardsCollection).document(boardId).updateData([
                "qrCode": newQRCode
            ])
            
            // 업데이트된 게시판 반환
            let snapshot = try await db.collection(boardsCollection).document(boardId).getDocument()
            guard let data = snapshot.data() else {
                throw WallyError.boardNotFound
            }
            
            let updatedBoard = try Board.fromFirestoreDictionary(data)
            
            // 로컬 상태 업데이트
            await MainActor.run {
                if let index = self.boards.firstIndex(where: { $0.id == boardId }) {
                    self.boards[index] = updatedBoard
                }
            }
            
            return updatedBoard
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    public func deactivateBoard(boardId: String) async throws {
        guard !boardId.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            try await db.collection(boardsCollection).document(boardId).updateData([
                "isActive": false
            ])
            
            // 로컬 상태 업데이트
            await MainActor.run {
                if let index = self.boards.firstIndex(where: { $0.id == boardId }) {
                    self.boards[index].isActive = false
                }
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - 교사용 메서드
    
    public func getBoardsForTeacher(teacherId: String) async throws -> [Board] {
        guard !teacherId.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            print("🔍 교사 게시판 조회: teacherId=\(teacherId)")
            
            // 교사가 생성한 게시판들을 조회 (adminId가 teacherId와 같은 것들)
            // 인덱스 문제를 피하기 위해 정렬 없이 조회하고 클라이언트에서 정렬
            let query = db.collection(boardsCollection)
                .whereField("adminId", isEqualTo: teacherId)
            
            let snapshot = try await query.getDocuments()
            print("📋 조회된 게시판 수: \(snapshot.documents.count)")
            
            let boards = try snapshot.documents.compactMap { document in
                do {
                    let board = try Board.fromFirestoreDictionary(document.data())
                    print("  📄 게시판: \(board.title) (ID: \(board.id))")
                    return board
                } catch {
                    print("⚠️ 게시판 파싱 실패: \(document.documentID) - \(error)")
                    return nil
                }
            }
            
            // 클라이언트에서 생성일 기준으로 정렬 (최신순)
            let sortedBoards = boards.sorted { $0.createdAt > $1.createdAt }
            
            print("✅ 교사 게시판 조회 완료: \(sortedBoards.count)개")
            return sortedBoards
            
        } catch {
            print("❌ 교사 게시판 조회 실패: \(error)")
            throw mapFirestoreError(error)
        }
    }
    
    public func getAllBoards() async throws -> [Board] {
        do {
            print("🔍 모든 게시판 조회 (관리자용)")
            
            let query = db.collection(boardsCollection)
                .order(by: "adminId")
                .order(by: "createdAt", descending: true)
            
            let snapshot = try await query.getDocuments()
            print("📋 조회된 전체 게시판 수: \(snapshot.documents.count)")
            
            let boards = try snapshot.documents.compactMap { document in
                do {
                    let board = try Board.fromFirestoreDictionary(document.data())
                    print("  📄 게시판: \(board.title) (관리자: \(board.adminId), ID: \(board.id), 활성: \(board.isActive))")
                    return board
                } catch {
                    print("⚠️ 게시판 파싱 실패: \(document.documentID) - \(error)")
                    return nil
                }
            }
            
            // 교사별로 그룹화하여 정렬
            let sortedBoards = boards.sorted { lhs, rhs in
                if lhs.adminId != rhs.adminId {
                    return lhs.adminId < rhs.adminId
                }
                return lhs.createdAt > rhs.createdAt
            }
            
            print("✅ 전체 게시판 조회 완료 (교사별 그룹화): \(sortedBoards.count)개")
            return sortedBoards
            
        } catch {
            print("❌ 전체 게시판 조회 실패: \(error)")
            throw mapFirestoreError(error)
        }
    }
    
    // MARK: - Board Statistics Methods
    
    /// 통계를 포함한 교사의 게시판 목록을 조회합니다
    public func getBoardsWithStatsForTeacher(teacherId: String) async throws -> [BoardWithStats] {
        print("📊 BoardService: 통계와 함께 교사 게시판 조회 시작 - teacherId: \(teacherId)")
        
        // 기본 게시판 목록 가져오기
        let boards = try await getBoardsForTeacher(teacherId: teacherId)
        print("📋 기본 게시판 \(boards.count)개 조회 완료, 통계 계산 시작")
        
        var boardsWithStats: [BoardWithStats] = []
        
        for board in boards {
            // 각 게시판의 학생 수와 사진 수 계산
            async let studentCount = calculateStudentCount(for: board.id)
            async let photoCount = calculatePhotoCount(for: board.id)
            
            let stats = try await (studentCount, photoCount)
            
            let boardWithStats = BoardWithStats(
                board: board,
                studentCount: stats.0,
                photoCount: stats.1,
                teacherName: nil  // 교사 이름은 BoardService에서는 설정하지 않음
            )
            
            boardsWithStats.append(boardWithStats)
            print("  📊 \(board.title): 학생 \(stats.0)명, 사진 \(stats.1)개")
        }
        
        print("✅ 통계 포함 게시판 조회 완료: \(boardsWithStats.count)개")
        return boardsWithStats
    }
    
    /// 특정 게시판의 학생 수를 계산합니다
    public func calculateStudentCount(for boardId: String) async throws -> Int {
        do {
            let studentsQuery = db.collection("students")
                .whereField("boardId", isEqualTo: boardId)
            
            let snapshot = try await studentsQuery.getDocuments()
            return snapshot.documents.count
        } catch {
            print("❌ 게시판 학생 수 계산 실패: \(error)")
            return 0
        }
    }
    
    /// 특정 게시판의 사진 수를 계산합니다
    public func calculatePhotoCount(for boardId: String) async throws -> Int {
        do {
            // 게시판의 모든 학생 찾기
            let studentsQuery = db.collection("students")
                .whereField("boardId", isEqualTo: boardId)
            
            let studentsSnapshot = try await studentsQuery.getDocuments()
            
            var totalPhotoCount = 0
            
            // 각 학생의 uploads 서브컬렉션에서 사진 수 계산
            for studentDoc in studentsSnapshot.documents {
                let uploadsQuery = db.collection("students")
                    .document(studentDoc.documentID)
                    .collection("uploads")
                
                let uploadsSnapshot = try await uploadsQuery.getDocuments()
                totalPhotoCount += uploadsSnapshot.documents.count
            }
            
            return totalPhotoCount
        } catch {
            print("❌ 게시판 사진 수 계산 실패: \(error)")
            return 0
        }
    }
    
    // MARK: - Student Participation Methods
    
    public func getBoardParticipantCount(boardId: String) async throws -> Int {
        return try await calculateStudentCount(for: boardId)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentAdminId() -> String {
        // 임시로 UUID를 반환하지만, 실제로는 createBoard 호출 시 adminId가 전달됨
        return UUID().uuidString
    }
    
    private func mapFirestoreError(_ error: Error) -> WallyError {
        if let firestoreError = error as NSError? {
            switch firestoreError.code {
            case FirestoreErrorCode.notFound.rawValue:
                return .boardNotFound
            case FirestoreErrorCode.permissionDenied.rawValue:
                return .insufficientPermissions
            case FirestoreErrorCode.unavailable.rawValue,
                 FirestoreErrorCode.deadlineExceeded.rawValue:
                return .networkError
            default:
                return .networkError
            }
        }
        
        if error is WallyError {
            return error as! WallyError
        }
        
        return .networkError
    }
}

// MARK: - Board Dictionary Conversion
extension Board {
    func toDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        
        let data = try encoder.encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        return dictionary ?? [:]
    }
    
    static func fromDictionary(_ dictionary: [String: Any], id: String) throws -> Board {
        var mutableDict = dictionary
        mutableDict["id"] = id
        
        let data = try JSONSerialization.data(withJSONObject: mutableDict)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        return try decoder.decode(Board.self, from: data)
    }
}