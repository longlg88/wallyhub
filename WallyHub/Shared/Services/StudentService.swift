import Foundation
import FirebaseFirestore
import FirebaseCore
import CryptoKit

// MARK: - Student Participation Data Model
public struct StudentParticipation: Identifiable, Hashable {
    public let id: String
    public let boardId: String
    public let boardTitle: String
    public let studentName: String
    public let studentId: String
    public let joinedAt: Date
    public let photoCount: Int
    public let lastActivity: Date?
    public let isActive: Bool
    
    public init(id: String, boardId: String, boardTitle: String, studentName: String, studentId: String, joinedAt: Date, photoCount: Int = 0, lastActivity: Date? = nil, isActive: Bool = true) {
        self.id = id
        self.boardId = boardId
        self.boardTitle = boardTitle
        self.studentName = studentName
        self.studentId = studentId
        self.joinedAt = joinedAt
        self.photoCount = photoCount
        self.lastActivity = lastActivity
        self.isActive = isActive
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: StudentParticipation, rhs: StudentParticipation) -> Bool {
        return lhs.id == rhs.id
    }
}

public protocol StudentService {
    func joinBoard(name: String, studentId: String, boardId: String) async throws -> Student
    func joinBoardWithPassword(name: String, studentId: String, password: String, boardId: String) async throws -> Student
    func updateStudentInfo(student: Student) async throws
    func getStudentsForBoard(boardId: String) async throws -> [Student]
    func getStudent(id: String) async throws -> Student?
    func deleteStudent(id: String) async throws
    func getStudentParticipations(userId: String) async throws -> [StudentParticipation]
    func getStudentPhotos(boardId: String, studentId: String) async throws -> [Photo]
    func uploadPhoto(boardId: String, studentId: String, imageData: Data) async throws
    func deletePhoto(boardId: String, photoId: String) async throws
    
    // 새로 추가된 메서드들
    func getAllStudents() async throws -> [Student]
    func addStudentToBoard(studentId: String, boardId: String) async throws
    func removeStudentFromBoard(studentId: String, boardId: String) async throws
    
    // 학생 인증 관련 메서드들
    func registerStudent(name: String, studentId: String, password: String) async throws -> Student
    func loginStudent(name: String, studentId: String, password: String) async throws -> Student
    func getStudentByCredentials(name: String, studentId: String) async throws -> Student?
    
    // 사용자별 학생 계정 조회
    func getStudentsForUser(userId: String) async throws -> [Student]
    
    // 활동 추적
    func getRecentStudentActivities() async throws -> [StudentActivity]
}

// MARK: - Student Activity Tracking Models

public struct StudentActivity {
    let id: String
    let type: StudentActivityType
    let studentId: String
    let studentName: String
    let boardId: String?
    let boardTitle: String?
    let description: String
    let timestamp: Date
    
    public enum StudentActivityType {
        case studentRegistered
        case studentJoinedBoard
        case studentLogin
        case photoUploaded
        
        var description: String {
            switch self {
            case .studentRegistered: return "학생 등록"
            case .studentJoinedBoard: return "게시판 참여"
            case .studentLogin: return "학생 로그인"
            case .photoUploaded: return "사진 업로드"
            }
        }
    }
}


public class FirebaseStudentService: StudentService, ObservableObject {
    private lazy var db: Firestore = {
        print("🔥 StudentService Firestore 초기화: 데이터베이스 wallydb")
        print("🔧 Firebase 앱 확인: \(FirebaseApp.app()?.name ?? "nil")")
        print("🔧 Firebase 프로젝트 ID: \(FirebaseApp.app()?.options.projectID ?? "nil")")
        
        let firestore = Firestore.firestore(database: "wallydb")
        print("✅ StudentService Firestore 연결 완료: wallydb 데이터베이스")
        print("🔧 Firestore 앱: \(firestore.app.name)")
        print("🔧 Firestore 프로젝트: \(firestore.app.options.projectID)")
        return firestore
    }()
    
    // MARK: - Student Management Methods
    
    public func joinBoard(name: String, studentId: String, boardId: String) async throws -> Student {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.networkError
        }
        
        print("🔍 joinBoard 시작 - 이름: \(name), 학생ID: \(studentId), 게시판ID: \(boardId)")
        print("🔍 학생ID 길이: \(studentId.count), 내용: '\(studentId)'")
        
        // 입력 데이터 유효성 검증
        do {
            try Student.validateForRegistration(name: name, studentId: studentId, boardId: boardId)
            print("✅ 유효성 검증 통과")
        } catch {
            print("❌ 유효성 검증 실패: \(error)")
            throw error
        }
        
        // 게시판 존재 여부 확인
        try await validateBoardExists(boardId: boardId)
        
        // 동일한 게시판에서 같은 학번의 학생이 이미 등록되어 있는지 확인
        try await validateStudentIdUnique(studentId: studentId, boardId: boardId)
        
        // 새 학생 객체 생성
        let student = Student(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            studentId: studentId.trimmingCharacters(in: .whitespacesAndNewlines),
            boardId: boardId
        )
        
        do {
            // Firestore에 학생 정보 저장
            let studentData = try encodeStudentForFirestore(student)
            try await db.collection("students").document(student.id).setData(studentData)
            
            // 게시판 참여 활동 추적
            await trackStudentActivity(
                type: .studentJoinedBoard,
                student: student,
                description: "\(student.name) 학생이 게시판에 참여했습니다"
            )
            
            return student
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.studentRegistrationFailed
            }
        }
    }
    
    public func updateStudentInfo(student: Student) async throws {
        // 학생 정보 유효성 검증
        try student.validate()
        
        // 학생이 존재하는지 확인
        let existingStudent = try await getStudent(id: student.id)
        guard existingStudent != nil else {
            throw WallyError.studentNotFound
        }
        
        // 학번이 변경된 경우, 동일한 게시판에서 중복 확인
        if existingStudent?.studentId != student.studentId {
            try await validateStudentIdUnique(studentId: student.studentId, boardId: student.boardId, excludeStudentId: student.id)
        }
        
        do {
            // 업데이트할 데이터 준비 (joinedAt과 boardId는 변경하지 않음)
            let updateData: [String: Any] = [
                "name": student.name.trimmingCharacters(in: .whitespacesAndNewlines),
                "studentId": student.studentId.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
            
            try await db.collection("students").document(student.id).updateData(updateData)
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.studentUpdateFailed
            }
        }
    }
    
    public func getStudentsForBoard(boardId: String) async throws -> [Student] {
        // 게시판 ID 유효성 검증
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            print("🔥 인덱스 테스트 - 프로젝트: wally-b635c, DB: wallydb")
            print("🔍 서버 정렬 쿼리 실행: boardId=\(boardId)")
            print("📋 쿼리 상세: collection('students').whereField('boardId', isEqualTo: '\(boardId)').order(by: 'joinedAt', descending: false)")
            
            let querySnapshot = try await db.collection("students")
                .whereField("boardId", isEqualTo: boardId)
                .order(by: "joinedAt", descending: false)
                .getDocuments()
            print("📊 서버 정렬 성공! 결과: \(querySnapshot.documents.count)개 문서")
            
            var students: [Student] = []
            
            for document in querySnapshot.documents {
                print("📄 처리 중인 문서: \(document.documentID)")
                do {
                    let student = try decodeStudentFromFirestore(document.data(), id: document.documentID)
                    print("✅ 학생 디코딩 성공: \(student.name), boardId=\(student.boardId)")
                    students.append(student)
                } catch {
                    // 개별 학생 데이터 파싱 오류는 로그만 남기고 계속 진행
                    print("❌ 학생 디코딩 실패 \(document.documentID): \(error)")
                }
            }
            
            // 서버에서 이미 정렬됨 (인덱스 사용)
            print("✅ 서버 정렬 완료! 학생 수: \(students.count)")
            return students
            
        } catch {
            print("❌ getStudentsForBoard 오류: \(error)")
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func getStudent(id: String) async throws -> Student? {
        // ID 유효성 검증
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            let document = try await db.collection("students").document(id).getDocument()
            
            guard document.exists, let data = document.data() else {
                return nil
            }
            
            return try decodeStudentFromFirestore(data, id: id)
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func deleteStudent(id: String) async throws {
        // ID 유효성 검증
        guard !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        // 학생이 존재하는지 확인
        let student = try await getStudent(id: id)
        guard student != nil else {
            throw WallyError.studentNotFound
        }
        
        do {
            try await db.collection("students").document(id).delete()
        } catch {
            throw WallyError.networkError
        }
    }
    
    public func getStudentParticipations(userId: String) async throws -> [StudentParticipation] {
        // 사용자 ID 유효성 검증
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            print("🔍 getStudentParticipations 시작 - 사용자 ID: \(userId)")
            
            // 현재 사용자(userId)와 매칭되는 학생 레코드만 조회
            // 기존 인덱스 활용: studentId 필터링만 하고 클라이언트에서 정렬
            let studentsSnapshot = try await db.collection("students")
                .whereField("studentId", isEqualTo: userId)
                .getDocuments()
            
            print("📊 userId \(userId)로 찾은 학생 레코드 수: \(studentsSnapshot.documents.count)")
            
            var participations: [StudentParticipation] = []
            
            for studentDoc in studentsSnapshot.documents {
                do {
                    let student = try decodeStudentFromFirestore(studentDoc.data(), id: studentDoc.documentID)
                    print("🎓 처리 중인 학생: \(student.name), 학번: \(student.studentId), 게시판: \(student.boardId)")
                    
                    // boardId가 빈 문자열이면 스킵 (아직 게시판에 참여하지 않은 학생)
                    guard !student.boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        print("⚠️ 학생 \(student.name)은 아직 게시판에 참여하지 않음")
                        continue
                    }
                    
                    // 게시판 정보 조회
                    print("🔍 게시판 정보 조회 시작 - boardId: \(student.boardId)")
                    let boardDoc = try await db.collection("boards").document(student.boardId).getDocument()
                    print("📊 게시판 문서 존재 여부: \(boardDoc.exists)")
                    guard boardDoc.exists, let boardData = boardDoc.data() else {
                        print("⚠️ 게시판 \(student.boardId)을 찾을 수 없음")
                        continue // 게시판이 없으면 스킵
                    }
                    print("✅ 게시판 데이터 로드 성공: \(boardData.keys.sorted())")
                    
                    let boardTitle = boardData["title"] as? String ?? "알 수 없는 게시판"
                    let isActive = boardData["isActive"] as? Bool ?? false
                    
                    // Firebase에서 실제 사진 개수 조회 (students/{studentId}/uploads 서브컬렉션에서)
                    var photoCount = 0
                    do {
                        print("📸 StudentService - \(student.name) 사진 개수 조회 시작")
                        print("🔍 쿼리 경로: students/\(student.id)/uploads")
                        
                        let photoSnapshot = try await db.collection("students")
                            .document(student.id)  // student.id는 document ID (UUID)
                            .collection("uploads")
                            .getDocuments()
                        
                        photoCount = photoSnapshot.documents.count
                        print("📊 StudentService - \(student.name) 사진 개수: \(photoCount)개")
                        
                        if photoCount == 0 {
                            print("🔍 디버깅: students/\(student.id)/uploads 서브컬렉션이 비어있음")
                        } else {
                            print("📷 업로드된 사진들:")
                            for doc in photoSnapshot.documents {
                                let data = doc.data()
                                print("   사진 \(doc.documentID): \(data["title"] as? String ?? "제목없음")")
                            }
                        }
                        
                    } catch {
                        print("⚠️ 학생 \(student.name)의 사진 개수 조회 실패: \(error)")
                        photoCount = 0
                    }
                    
                    // 임시: 최근 활동 시간도 비활성화
                    let lastActivity: Date? = nil
                    
                    let participation = StudentParticipation(
                        id: student.id,
                        boardId: student.boardId,
                        boardTitle: boardTitle,
                        studentName: student.name,
                        studentId: student.studentId,
                        joinedAt: student.joinedAt,
                        photoCount: photoCount,
                        lastActivity: lastActivity,
                        isActive: isActive
                    )
                    
                    participations.append(participation)
                    
                } catch {
                    // 개별 학생 데이터 파싱 오류는 로그만 남기고 계속 진행
                    print("Warning: Failed to process student participation for document \(studentDoc.documentID): \(error)")
                }
            }
            
            // 클라이언트에서 joinedAt 기준으로 내림차순 정렬 (최신순)
            let sortedParticipations = participations.sorted { $0.joinedAt > $1.joinedAt }
            print("✅ 클라이언트 정렬 완료: \(sortedParticipations.count)개 참여")
            
            return sortedParticipations
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func getStudentPhotos(boardId: String, studentId: String) async throws -> [Photo] {
        // 입력 데이터 유효성 검증
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        print("📸 StudentService.getStudentPhotos 시작")
        print("🔍 전달받은 studentId: \(studentId), 게시판ID: \(boardId)")
        
        do {
            var studentDocId: String
            var actualStudentId: String
            
            // studentId가 UUID 형식인지 확인 (36자리, UUID 패턴)
            let uuidPattern = "^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$"
            let uuidRegex = try NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive)
            let isUUID = uuidRegex.firstMatch(in: studentId, range: NSRange(location: 0, length: studentId.count)) != nil
            
            if isUUID {
                print("📋 UUID 형식으로 인식: student document ID로 직접 조회")
                // studentId가 UUID인 경우: document ID로 직접 접근
                studentDocId = studentId
                
                // student 문서에서 실제 studentId 조회
                let studentDoc = try await db.collection("students").document(studentDocId).getDocument()
                guard studentDoc.exists, let data = studentDoc.data() else {
                    print("❌ UUID \(studentId)에 해당하는 학생 문서를 찾을 수 없음")
                    return []
                }
                
                actualStudentId = data["studentId"] as? String ?? "알 수 없음"
                let studentName = data["name"] as? String ?? "알 수 없음"
                print("✅ 학생 문서 발견: \(studentName) (학번: \(actualStudentId))")
                
            } else {
                print("🎓 학번으로 인식: studentId 필드로 조회")
                // studentId가 학번인 경우: studentId 필드로 검색
                let studentsQuery = try await db.collection("students")
                    .whereField("studentId", isEqualTo: studentId)
                    .whereField("boardId", isEqualTo: boardId)
                    .getDocuments()
                
                guard let studentDoc = studentsQuery.documents.first else {
                    print("❌ 학번 \(studentId)에 해당하는 학생을 찾을 수 없음 (boardId: \(boardId))")
                    return []
                }
                
                studentDocId = studentDoc.documentID
                actualStudentId = studentId
                let studentName = studentDoc.data()["name"] as? String ?? "알 수 없음"
                print("✅ 학생 문서 발견: \(studentName) (문서ID: \(studentDocId))")
            }
            
            // 2단계: students/{studentDocId}/uploads 서브컬렉션에서 사진 조회
            print("🔍 쿼리 경로: students/\(studentDocId)/uploads")
            let querySnapshot = try await db.collection("students")
                .document(studentDocId)
                .collection("uploads")
                .order(by: "uploadedAt", descending: true)
                .getDocuments()
            
            print("📊 StudentService - \(studentDocId) 서브컬렉션 결과: \(querySnapshot.documents.count)개 문서")
            
            var photos: [Photo] = []
            
            for document in querySnapshot.documents {
                do {
                    let data = document.data()
                    print("🔍 문서 \(document.documentID) 데이터: \(data)")
                    
                    // 필수 필드 확인
                    if let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue() {
                        
                        let photo = Photo(
                            id: document.documentID,
                            title: data["title"] as? String ?? "",
                            studentId: actualStudentId, // 실제 학번 사용
                            boardId: boardId,
                            imageUrl: data["imageUrl"] as? String,
                            uploadedAt: uploadedAt,
                            isVisible: data["isVisible"] as? Bool ?? true
                        )
                        photos.append(photo)
                        print("✅ 사진 변환 성공: \(photo.title) - \(photo.imageUrl ?? "No URL")")
                        print("🔍 사진 상세 정보:")
                        print("   ID: \(photo.id)")
                        print("   Title: \(photo.title)")
                        print("   StudentId: \(photo.studentId)")
                        print("   BoardId: \(photo.boardId)")
                        print("   ImageUrl: \(photo.imageUrl ?? "nil")")
                        print("   UploadedAt: \(photo.uploadedAt)")
                        print("   IsVisible: \(photo.isVisible)")
                    } else {
                        print("❌ 사진 데이터 파싱 실패 - 필수 필드 누락")
                        print("   uploadedAt: \(data["uploadedAt"] != nil ? "존재" : "nil")")
                    }
                } catch {
                    print("❌ 개별 사진 파싱 실패 for document \(document.documentID): \(error)")
                }
            }
            
            return photos
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func uploadPhoto(boardId: String, studentId: String, imageData: Data) async throws {
        // 입력 데이터 유효성 검증
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !imageData.isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            // Create new photo document
            let photoId = UUID().uuidString
            let photo = Photo(
                id: photoId,
                studentId: studentId,
                boardId: boardId,
                imageUrl: nil // Will be set after upload
            )
            
            // Save photo metadata to Firestore first
            let photoData: [String: Any] = [
                "studentId": photo.studentId,
                "boardId": photo.boardId,
                "uploadedAt": Timestamp(date: photo.uploadedAt),
                "isVisible": photo.isVisible,
                "title": photo.title
            ]
            
            try await db.collection("photos").document(photoId).setData(photoData)
            
            // TODO: Upload imageData to Firebase Storage and update photo document with imageUrl
            // For now, we'll just save the metadata
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func deletePhoto(boardId: String, photoId: String) async throws {
        // 입력 데이터 유효성 검증
        guard !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !photoId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        do {
            // 사진이 존재하는지 확인
            let photoDoc = try await db.collection("photos").document(photoId).getDocument()
            guard photoDoc.exists else {
                throw WallyError.photoNotFound
            }
            
            // 게시판 ID 일치 확인
            if let photoData = photoDoc.data(),
               let photoBoardId = photoData["boardId"] as? String,
               photoBoardId != boardId {
                throw WallyError.unauthorized
            }
            
            // 사진 삭제
            try await db.collection("photos").document(photoId).delete()
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    // MARK: - 새로 추가된 메서드들
    
    public func getAllStudents() async throws -> [Student] {
        do {
            let querySnapshot = try await db.collection("students")
                .order(by: "name", descending: false)
                .getDocuments()
            
            var students: [Student] = []
            
            for document in querySnapshot.documents {
                do {
                    let student = try decodeStudentFromFirestore(document.data(), id: document.documentID)
                    students.append(student)
                } catch {
                    // 개별 학생 데이터 파싱 오류는 로그만 남기고 계속 진행
                    print("Warning: Failed to decode student data for document \(document.documentID): \(error)")
                }
            }
            
            return students
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func addStudentToBoard(studentId: String, boardId: String) async throws {
        // 입력 데이터 유효성 검증
        guard !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        // 학생이 존재하는지 확인
        guard let student = try await getStudent(id: studentId) else {
            throw WallyError.studentNotFound
        }
        
        // 게시판 존재 여부 확인
        try await validateBoardExists(boardId: boardId)
        
        // 이미 같은 게시판에 참여하고 있는지 확인
        if student.boardId == boardId {
            print("⚠️ 학생 \(student.name)은 이미 게시판 \(boardId)에 참여 중")
            throw WallyError.duplicateStudentId // 이미 같은 게시판에 참여 중
        }
        
        // 다른 게시판에 참여 중인 경우 로그 출력
        if !student.boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("⚠️ 학생 \(student.name)이 다른 게시판(\(student.boardId))에서 새 게시판(\(boardId))으로 이동")
        }
        
        do {
            print("🔄 학생 \(student.name)을 게시판 \(boardId)에 추가 중...")
            
            // 학생의 boardId 필드를 업데이트
            try await db.collection("students").document(studentId).updateData([
                "boardId": boardId
            ])
            
            print("✅ 학생 \(student.name)이 게시판에 성공적으로 추가됨")
            
        } catch {
            print("❌ 학생 추가 실패: \(error)")
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func removeStudentFromBoard(studentId: String, boardId: String) async throws {
        // 입력 데이터 유효성 검증
        guard !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !boardId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WallyError.invalidInput
        }
        
        // 학생이 존재하는지 확인
        guard let student = try await getStudent(id: studentId) else {
            throw WallyError.studentNotFound
        }
        
        // 학생이 해당 게시판에 참여하고 있는지 확인
        guard student.boardId == boardId else {
            print("⚠️ 학생 \(student.name)은 게시판 \(boardId)에 참여하지 않음 (현재 게시판: \(student.boardId))")
            throw WallyError.studentNotInBoard
        }
        
        do {
            print("🔄 학생 \(student.name)을 게시판 \(boardId)에서 제거 중...")
            
            // 학생의 boardId 필드를 빈 문자열로 업데이트 (게시판에서 제거)
            try await db.collection("students").document(studentId).updateData([
                "boardId": ""
            ])
            
            print("✅ 학생 \(student.name)이 게시판에서 성공적으로 제거됨")
            
        } catch {
            print("❌ 학생 제거 실패: \(error)")
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func validateBoardExists(boardId: String) async throws {
        print("🔍 게시판 존재 여부 확인: \(boardId)")
        
        // 먼저 모든 게시판 목록을 확인 (디버깅용)
        let allBoardsQuery = try await db.collection("boards").getDocuments()
        print("📋 전체 게시판 수: \(allBoardsQuery.documents.count)")
        for doc in allBoardsQuery.documents {
            let data = doc.data()
            let title = data["title"] as? String ?? "제목 없음"
            print("  📄 게시판 ID: \(doc.documentID), 제목: \(title)")
        }
        
        let document = try await db.collection("boards").document(boardId).getDocument()
        
        guard document.exists else {
            print("❌ 게시판을 찾을 수 없음: \(boardId)")
            throw WallyError.boardNotFound
        }
        
        print("✅ 게시판 발견: \(boardId)")
        
        // 게시판이 활성 상태인지 확인
        if let data = document.data(),
           let isActive = data["isActive"] as? Bool,
           !isActive {
            print("⚠️ 게시판이 비활성 상태: \(boardId)")
            throw WallyError.boardNotActive
        }
        
        print("✅ 게시판이 활성 상태임")
    }
    
    private func validateStudentIdUnique(studentId: String, boardId: String, excludeStudentId: String? = nil) async throws {
        print("🔍 중복 학번 체크 시작 - studentId: \(studentId), boardId: \(boardId)")
        
        do {
            let query = db.collection("students")
                .whereField("boardId", isEqualTo: boardId)
                .whereField("studentId", isEqualTo: studentId)
            
            print("📋 복합 쿼리 실행: students where boardId=\(boardId) AND studentId=\(studentId)")
            let querySnapshot = try await query.getDocuments()
            print("📊 중복 체크 결과: \(querySnapshot.documents.count)개 문서")
            
            // 업데이트의 경우 자기 자신은 제외
            let duplicateStudents = querySnapshot.documents.filter { document in
                if let excludeId = excludeStudentId {
                    return document.documentID != excludeId
                }
                return true
            }
            
            if !duplicateStudents.isEmpty {
                print("❌ 중복 학번 발견: \(duplicateStudents.count)개")
                throw WallyError.duplicateStudentId
            }
            
            print("✅ 중복 학번 체크 완료 - 중복 없음")
            
        } catch {
            print("❌ 중복 학번 체크 실패: \(error)")
            throw error
        }
    }
    
    private func encodeStudentForFirestore(_ student: Student) throws -> [String: Any] {
        return [
            "name": student.name,
            "studentId": student.studentId,
            "boardId": student.boardId,
            "joinedAt": Timestamp(date: student.joinedAt)
        ]
    }
    
    private func decodeStudentFromFirestore(_ data: [String: Any], id: String) throws -> Student {
        guard let name = data["name"] as? String,
              let studentId = data["studentId"] as? String,
              let boardId = data["boardId"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
            throw WallyError.dataCorruption
        }
        
        let student = Student(
            id: id,
            name: name,
            studentId: studentId,
            boardId: boardId,
            joinedAt: joinedAtTimestamp.dateValue()
        )
        
        // 데이터 유효성 검증
        try student.validate()
        
        return student
    }
    
    private func decodePhotoFromFirestore(_ data: [String: Any], id: String) throws -> Photo {
        guard let title = data["title"] as? String,
              let studentId = data["studentId"] as? String,
              let boardId = data["boardId"] as? String,
              let uploadedAtTimestamp = data["uploadedAt"] as? Timestamp else {
            throw WallyError.dataCorruption
        }
        
        let photo = Photo(
            id: id,
            title: title,
            studentId: studentId,
            boardId: boardId,
            imageUrl: data["imageUrl"] as? String,
            uploadedAt: uploadedAtTimestamp.dateValue(),
            isVisible: data["isVisible"] as? Bool ?? true
        )
        
        return photo
    }
    
    // MARK: - 학생 인증 관련 메서드들
    
    public func registerStudent(name: String, studentId: String, password: String) async throws -> Student {
        // 입력 검증
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !studentId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              password.count >= 6 else {
            throw WallyError.invalidInput
        }
        
        do {
            // 기존 학생 확인 (같은 학번이 있는지)
            print("🔍 중복 학번 체크: \(studentId)")
            
            // 모든 학생 데이터 확인 (디버깅용)
            let allStudentsQuery = try await db.collection("students").getDocuments()
            print("📋 전체 학생 수: \(allStudentsQuery.documents.count)")
            for doc in allStudentsQuery.documents {
                let data = doc.data()
                print("  🎓 ID: \(doc.documentID), 이름: \(data["name"] ?? "없음"), 학번: \(data["studentId"] ?? "없음")")
            }
            
            let existingStudentQuery = try await db.collection("students")
                .whereField("studentId", isEqualTo: studentId)
                .getDocuments()
            
            print("📊 기존 학생 수: \(existingStudentQuery.documents.count)")
            
            if !existingStudentQuery.documents.isEmpty {
                print("⚠️ 중복된 학번 발견:")
                for doc in existingStudentQuery.documents {
                    let data = doc.data()
                    print("  - 이름: \(data["name"] ?? "없음"), 학번: \(data["studentId"] ?? "없음")")
                }
                throw WallyError.duplicateStudentId
            }
            
            // 비밀번호 해시화 (간단한 예시, 실제로는 더 강력한 해시 사용)
            let passwordHash = hashPassword(password)
            
            // 새 학생 생성
            let student = Student(
                name: name,
                studentId: studentId,
                boardId: "", // 아직 게시판에 참여하지 않음
                passwordHash: passwordHash
            )
            
            // Firestore에 저장
            let studentData = try encodeStudentWithAuthForFirestore(student)
            try await db.collection("students").document(student.id).setData(studentData)
            
            // 학생 등록 활동 추적
            await trackStudentActivity(
                type: .studentRegistered,
                student: student,
                description: "\(student.name) 학생이 등록되었습니다"
            )
            
            return student
            
        } catch {
            if error is WallyError {
                throw error
            } else {
                throw WallyError.networkError
            }
        }
    }
    
    public func loginStudent(name: String, studentId: String, password: String) async throws -> Student {
        // 입력 검증
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStudentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty,
              !trimmedStudentId.isEmpty,
              !password.isEmpty else {
            print("❌ 입력 검증 실패: 이름='\(trimmedName)', 학번='\(trimmedStudentId)', 비밀번호 길이=\(password.count)")
            throw WallyError.invalidInput
        }
        
        do {
            print("🔍 학생 로그인 시도: 이름='\(trimmedName)', 학번='\(trimmedStudentId)'")
            
            // 먼저 모든 학생 데이터를 확인 (디버깅용)
            let allStudentsQuery = try await db.collection("students").getDocuments()
            print("📋 전체 학생 수: \(allStudentsQuery.documents.count)")
            for doc in allStudentsQuery.documents {
                let data = doc.data()
                let docName = data["name"] as? String ?? "없음"
                let docStudentId = data["studentId"] as? String ?? "없음"
                print("  🎓 ID: \(doc.documentID), 이름: '\(docName)', 학번: '\(docStudentId)'")
            }
            
            // 이름으로만 먼저 검색
            let nameQuery = try await db.collection("students")
                .whereField("name", isEqualTo: trimmedName)
                .getDocuments()
            
            print("📊 이름 '\(trimmedName)'으로 찾은 학생 수: \(nameQuery.documents.count)")
            
            // 학번으로만 검색
            let studentIdQuery = try await db.collection("students")
                .whereField("studentId", isEqualTo: trimmedStudentId)
                .getDocuments()
            
            print("📊 학번 '\(trimmedStudentId)'으로 찾은 학생 수: \(studentIdQuery.documents.count)")
            
            // 이름과 학번 모두로 검색
            let querySnapshot = try await db.collection("students")
                .whereField("name", isEqualTo: trimmedName)
                .whereField("studentId", isEqualTo: trimmedStudentId)
                .getDocuments()
            
            print("📊 이름과 학번 모두로 찾은 학생 수: \(querySnapshot.documents.count)")
            
            guard let document = querySnapshot.documents.first else {
                print("❌ 일치하는 학생을 찾을 수 없음")
                throw WallyError.authenticationFailed
            }
            
            print("✅ 학생 문서 발견: \(document.documentID)")
            let data = document.data()
            print("📄 학생 데이터: \(data)")
            
            // 학생 데이터 디코딩
            let student = try decodeStudentWithAuthFromFirestore(data, id: document.documentID)
            print("✅ 학생 데이터 디코딩 성공: \(student.name)")
            
            // 비밀번호 확인
            guard let storedHash = student.passwordHash,
                  verifyPassword(password, hash: storedHash) else {
                print("❌ 비밀번호 검증 실패")
                throw WallyError.authenticationFailed
            }
            
            print("✅ 비밀번호 검증 성공")
            
            // 학생 로그인 활동 추적
            await trackStudentActivity(
                type: .studentLogin,
                student: student,
                description: "\(student.name) 학생이 로그인했습니다"
            )
            
            return student
            
        } catch {
            print("❌ 학생 로그인 중 오류 발생: \(error)")
            if error is WallyError {
                throw error
            } else {
                throw WallyError.authenticationFailed
            }
        }
    }
    
    public func joinBoardWithPassword(name: String, studentId: String, password: String, boardId: String) async throws -> Student {
        // 입력 검증
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStudentId = studentId.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty,
              !trimmedStudentId.isEmpty,
              trimmedPassword.count >= 6 else {
            throw WallyError.invalidInput
        }
        
        do {
            print("🔥 QR 회원가입 시작: 이름='\(trimmedName)', 학번='\(trimmedStudentId)', 게시판='\(boardId)'")
            
            // 1. 게시판 존재 및 활성 상태 확인
            try await validateBoardExists(boardId: boardId)
            
            // 2. 같은 게시판에서 학번 중복 체크
            try await validateStudentIdUnique(studentId: trimmedStudentId, boardId: boardId)
            
            // 3. 새 학생 생성 (비밀번호 포함)
            let passwordHash = hashPassword(trimmedPassword)
            let student = Student(
                name: trimmedName,
                studentId: trimmedStudentId,
                boardId: boardId,
                passwordHash: passwordHash
            )
            
            // 4. Firebase에 저장
            let studentData = try encodeStudentWithAuthForFirestore(student)
            try await db.collection("students").document(student.id).setData(studentData)
            
            // QR 회원가입 활동 추적 (등록 + 게시판 참여)
            await trackStudentActivity(
                type: .studentRegistered,
                student: student,
                description: "\(student.name) 학생이 QR코드로 등록 및 게시판 참여했습니다"
            )
            
            print("✅ QR 회원가입 완료: 학생 ID='\(student.id)', 게시판='\(boardId)'")
            return student
            
        } catch {
            print("❌ QR 회원가입 실패: \(error)")
            throw error
        }
    }
    
    public func getStudentByCredentials(name: String, studentId: String) async throws -> Student? {
        do {
            let querySnapshot = try await db.collection("students")
                .whereField("name", isEqualTo: name)
                .whereField("studentId", isEqualTo: studentId)
                .getDocuments()
            
            guard let document = querySnapshot.documents.first else {
                return nil
            }
            
            return try decodeStudentWithAuthFromFirestore(document.data(), id: document.documentID)
            
        } catch {
            throw WallyError.networkError
        }
    }
    
    // MARK: - 비밀번호 관련 헬퍼 메서드들
    
    private func hashPassword(_ password: String) -> String {
        // 실제로는 bcrypt, scrypt 등 강력한 해시 함수를 사용해야 함
        // 여기서는 간단한 예시로 SHA256 사용
        let data = Data(password.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func verifyPassword(_ password: String, hash: String) -> Bool {
        let passwordHash = hashPassword(password)
        return passwordHash == hash
    }
    
    private func encodeStudentWithAuthForFirestore(_ student: Student) throws -> [String: Any] {
        var data: [String: Any] = [
            "name": student.name,
            "studentId": student.studentId,
            "boardId": student.boardId,
            "joinedAt": Timestamp(date: student.joinedAt),
            "createdAt": Timestamp(date: student.createdAt)
        ]
        
        if let passwordHash = student.passwordHash {
            data["passwordHash"] = passwordHash
        }
        
        return data
    }
    
    private func decodeStudentWithAuthFromFirestore(_ data: [String: Any], id: String) throws -> Student {
        guard let name = data["name"] as? String,
              let studentId = data["studentId"] as? String,
              let boardId = data["boardId"] as? String,
              let joinedAtTimestamp = data["joinedAt"] as? Timestamp else {
            throw WallyError.dataCorruption
        }
        
        let createdAtTimestamp = data["createdAt"] as? Timestamp
        let passwordHash = data["passwordHash"] as? String
        
        let student = Student(
            id: id,
            name: name,
            studentId: studentId,
            boardId: boardId,
            joinedAt: joinedAtTimestamp.dateValue(),
            passwordHash: passwordHash,
            createdAt: createdAtTimestamp?.dateValue() ?? Date()
        )
        
        try student.validate()
        return student
    }
    
    public func getStudentsForUser(userId: String) async throws -> [Student] {
        print("🔍 사용자 \(userId)의 학생 계정들 검색 시작...")
        
        // 현재 사용자가 생성한 학생 계정들을 찾기
        // 임시로 학번과 사용자명이 연결된 방식으로 검색
        // 실제 구현에서는 User-Student 관계 테이블이 있어야 하지만,
        // 현재는 학생 이름으로 연결 가정
        
        let studentsRef = db.collection("students")
        let snapshot = try await studentsRef.getDocuments()
        
        var userStudents: [Student] = []
        
        for document in snapshot.documents {
            let data = document.data()
            
            // 학생 데이터 파싱
            guard let name = data["name"] as? String,
                  let studentId = data["studentId"] as? String,
                  let boardId = data["boardId"] as? String,
                  let joinedAtTimestamp = data["joinedAt"] as? Timestamp,
                  let createdAtTimestamp = data["createdAt"] as? Timestamp else {
                print("⚠️ 학생 데이터 파싱 실패: \(document.documentID)")
                continue
            }
            
            let passwordHash = data["passwordHash"] as? String
            
            let student = Student(
                id: document.documentID,
                name: name,
                studentId: studentId,
                boardId: boardId,
                joinedAt: joinedAtTimestamp.dateValue(),
                passwordHash: passwordHash,
                createdAt: createdAtTimestamp.dateValue()
            )
            
            userStudents.append(student)
            print("✅ 학생 발견: \(student.name) (학번: \(student.studentId), 게시판: \(student.boardId))")
        }
        
        print("📚 총 \(userStudents.count)개 학생 계정 발견")
        return userStudents.sorted { $0.name < $1.name }
    }
    
    // MARK: - Activity Tracking Implementation
    
    /// 학생 활동 추적
    private func trackStudentActivity(type: StudentActivity.StudentActivityType, student: Student, description: String) async {
        do {
            // 게시판 정보 조회 (boardId가 있는 경우)
            var boardTitle: String? = nil
            if !student.boardId.isEmpty {
                do {
                    let boardDoc = try await db.collection("boards").document(student.boardId).getDocument()
                    if boardDoc.exists, let data = boardDoc.data() {
                        boardTitle = data["title"] as? String
                    }
                } catch {
                    print("⚠️ 게시판 정보 조회 실패 (활동 추적용): \(error)")
                }
            }
            
            let activity = StudentActivity(
                id: UUID().uuidString,
                type: type,
                studentId: student.studentId,
                studentName: student.name,
                boardId: student.boardId.isEmpty ? nil : student.boardId,
                boardTitle: boardTitle,
                description: description,
                timestamp: Date()
            )
            
            let activityData: [String: Any] = [
                "id": activity.id,
                "type": type.description,
                "studentId": activity.studentId,
                "studentName": activity.studentName,
                "boardId": activity.boardId as Any,
                "boardTitle": activity.boardTitle as Any,
                "description": activity.description,
                "timestamp": activity.timestamp.timeIntervalSince1970,
                "createdAt": Date().timeIntervalSince1970
            ]
            
            try await db.collection("studentActivities").document(activity.id).setData(activityData)
            print("✅ 학생 활동 추적 저장: \(description)")
            
        } catch {
            print("❌ 학생 활동 추적 실패: \(error)")
            // 활동 추적 실패는 메인 기능에 영향을 주지 않도록 함
        }
    }
    
    /// 최근 학생 활동 조회
    public func getRecentStudentActivities() async throws -> [StudentActivity] {
        print("📋 최근 학생 활동 조회")
        
        do {
            let snapshot = try await db.collection("studentActivities")
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            var activities: [StudentActivity] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let id = data["id"] as? String,
                      let typeString = data["type"] as? String,
                      let studentId = data["studentId"] as? String,
                      let studentName = data["studentName"] as? String,
                      let description = data["description"] as? String,
                      let timestamp = data["timestamp"] as? TimeInterval else {
                    continue
                }
                
                // StudentActivityType을 문자열로부터 복원
                let type: StudentActivity.StudentActivityType
                switch typeString {
                case "학생 등록": type = .studentRegistered
                case "게시판 참여": type = .studentJoinedBoard
                case "학생 로그인": type = .studentLogin
                case "사진 업로드": type = .photoUploaded
                default: continue
                }
                
                let boardId = data["boardId"] as? String
                let boardTitle = data["boardTitle"] as? String
                
                let activity = StudentActivity(
                    id: id,
                    type: type,
                    studentId: studentId,
                    studentName: studentName,
                    boardId: boardId,
                    boardTitle: boardTitle,
                    description: description,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
                
                activities.append(activity)
            }
            
            print("✅ 최근 학생 활동 조회 성공: \(activities.count)개")
            return activities
            
        } catch {
            print("❌ 최근 학생 활동 조회 실패: \(error)")
            throw error
        }
    }
}