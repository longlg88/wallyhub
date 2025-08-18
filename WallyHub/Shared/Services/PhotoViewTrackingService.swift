import Foundation
import FirebaseFirestore

/// 교사의 사진 조회 기록을 추적하는 서비스 (교사 전용)
public protocol PhotoViewTrackingService {
    /// 교사가 사진을 확인했음을 기록
    func trackPhotoView(photoId: String, teacherId: String, boardId: String, sessionDuration: TimeInterval?) async throws
    
    /// 특정 사진의 조회 상태 정보 조회
    func getPhotoViewStatus(photoId: String) async throws -> PhotoViewStatus?
    
    /// 여러 사진의 조회 상태를 일괄 조회
    func getPhotoViewStatuses(photoIds: [String]) async throws -> [String: PhotoViewStatus]
    
    /// 특정 게시판의 모든 사진 조회 상태
    func getBoardPhotoViewStatuses(boardId: String) async throws -> [String: PhotoViewStatus]
    
    /// 교사의 조회 통계
    func getTeacherViewStats(teacherId: String) async throws -> TeacherViewStats
    
    /// 사진을 일괄 "확인됨" 처리
    func markPhotosAsViewed(photoIds: [String], teacherId: String, boardId: String) async throws
}

public class FirebasePhotoViewTrackingService: PhotoViewTrackingService, ObservableObject {
    
    private lazy var firestore: Firestore = {
        print("🔥 PhotoViewTrackingService Firestore 초기화: 데이터베이스 wallydb")
        let firestore = Firestore.firestore(database: "wallydb")
        print("✅ PhotoViewTrackingService Firestore 연결 완료: wallydb 데이터베이스")
        return firestore
    }()
    
    // MARK: - Photo View Tracking
    
    public func trackPhotoView(
        photoId: String,
        teacherId: String,
        boardId: String,
        sessionDuration: TimeInterval? = nil
    ) async throws {
        do {
            print("👁️ 사진 조회 기록 중: photoId=\(photoId), teacherId=\(teacherId)")
            
            let viewRecord = PhotoViewRecord(
                photoId: photoId,
                teacherId: teacherId,
                boardId: boardId,
                viewedAt: Date(),
                sessionDuration: sessionDuration
            )
            
            // 유효성 검증
            try viewRecord.validate()
            
            // photo_views 컬렉션에 조회 기록 저장
            try await firestore.collection("photo_views")
                .document(viewRecord.id)
                .setData([
                    "photoId": viewRecord.photoId,
                    "teacherId": viewRecord.teacherId,
                    "boardId": viewRecord.boardId,
                    "viewedAt": Timestamp(date: viewRecord.viewedAt),
                    "sessionDuration": viewRecord.sessionDuration ?? 0
                ])
            
            print("✅ 사진 조회 기록 저장 완료")
            
        } catch let error as WallyError {
            print("❌ trackPhotoView WallyError: \(error)")
            throw error
        } catch {
            print("❌ trackPhotoView 네트워크 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    // MARK: - Photo View Status Retrieval
    
    public func getPhotoViewStatus(photoId: String) async throws -> PhotoViewStatus? {
        do {
            print("📊 사진 조회 상태 조회: photoId=\(photoId)")
            
            // photo_views 컬렉션에서 해당 사진의 모든 조회 기록 조회
            let viewRecordsSnapshot = try await firestore.collection("photo_views")
                .whereField("photoId", isEqualTo: photoId)
                .order(by: "viewedAt", descending: true)
                .getDocuments()
            
            if viewRecordsSnapshot.documents.isEmpty {
                print("📊 미확인 사진: \(photoId)")
                return PhotoViewStatus(photoId: photoId)
            }
            
            // 조회 기록을 PhotoViewRecord로 변환
            let viewRecords: [PhotoViewRecord] = viewRecordsSnapshot.documents.compactMap { doc in
                let data = doc.data()
                guard let viewedAtTimestamp = data["viewedAt"] as? Timestamp else {
                    return nil
                }
                
                return PhotoViewRecord(
                    id: doc.documentID,
                    photoId: data["photoId"] as? String ?? "",
                    teacherId: data["teacherId"] as? String ?? "",
                    boardId: data["boardId"] as? String ?? "",
                    viewedAt: viewedAtTimestamp.dateValue(),
                    sessionDuration: data["sessionDuration"] as? TimeInterval
                )
            }
            
            // 통계 계산
            let totalViews = viewRecords.count
            let uniqueViewers = Set(viewRecords.map { $0.teacherId }).count
            let lastViewedAt = viewRecords.first?.viewedAt
            let lastViewedBy = viewRecords.first?.teacherId
            
            let status = PhotoViewStatus(
                photoId: photoId,
                totalViews: totalViews,
                uniqueViewers: uniqueViewers,
                lastViewedAt: lastViewedAt,
                lastViewedBy: lastViewedBy,
                isViewed: !viewRecords.isEmpty,
                viewRecords: viewRecords
            )
            
            print("✅ 사진 조회 상태: \(totalViews)회 조회, \(uniqueViewers)명 확인")
            return status
            
        } catch {
            print("❌ getPhotoViewStatus 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    public func getPhotoViewStatuses(photoIds: [String]) async throws -> [String: PhotoViewStatus] {
        do {
            print("📊 여러 사진 조회 상태 일괄 조회: \(photoIds.count)개")
            
            var statuses: [String: PhotoViewStatus] = [:]
            
            // Firebase 쿼리 제한으로 인해 배치 처리 (한번에 최대 10개)
            let batchSize = 10
            for i in stride(from: 0, to: photoIds.count, by: batchSize) {
                let endIndex = min(i + batchSize, photoIds.count)
                let batch = Array(photoIds[i..<endIndex])
                
                let viewRecordsSnapshot = try await firestore.collection("photo_views")
                    .whereField("photoId", in: batch)
                    .order(by: "viewedAt", descending: true)
                    .getDocuments()
                
                // photoId별로 그룹화
                var groupedRecords: [String: [PhotoViewRecord]] = [:]
                
                for doc in viewRecordsSnapshot.documents {
                    let data = doc.data()
                    guard let photoId = data["photoId"] as? String,
                          let viewedAtTimestamp = data["viewedAt"] as? Timestamp else {
                        continue
                    }
                    
                    let record = PhotoViewRecord(
                        id: doc.documentID,
                        photoId: photoId,
                        teacherId: data["teacherId"] as? String ?? "",
                        boardId: data["boardId"] as? String ?? "",
                        viewedAt: viewedAtTimestamp.dateValue(),
                        sessionDuration: data["sessionDuration"] as? TimeInterval
                    )
                    
                    if groupedRecords[photoId] == nil {
                        groupedRecords[photoId] = []
                    }
                    groupedRecords[photoId]?.append(record)
                }
                
                // 각 photoId에 대한 상태 계산
                for photoId in batch {
                    let records = groupedRecords[photoId] ?? []
                    
                    let status = PhotoViewStatus(
                        photoId: photoId,
                        totalViews: records.count,
                        uniqueViewers: Set(records.map { $0.teacherId }).count,
                        lastViewedAt: records.first?.viewedAt,
                        lastViewedBy: records.first?.teacherId,
                        isViewed: !records.isEmpty,
                        viewRecords: records
                    )
                    
                    statuses[photoId] = status
                }
            }
            
            // 조회되지 않은 사진들은 기본 상태로 설정
            for photoId in photoIds {
                if statuses[photoId] == nil {
                    statuses[photoId] = PhotoViewStatus(photoId: photoId)
                }
            }
            
            print("✅ 일괄 조회 완료: \(statuses.count)개 사진 상태")
            return statuses
            
        } catch {
            print("❌ getPhotoViewStatuses 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    public func getBoardPhotoViewStatuses(boardId: String) async throws -> [String: PhotoViewStatus] {
        do {
            print("📊 게시판 \(boardId)의 사진 조회 상태 조회")
            
            // 해당 게시판의 모든 조회 기록 조회
            let viewRecordsSnapshot = try await firestore.collection("photo_views")
                .whereField("boardId", isEqualTo: boardId)
                .order(by: "viewedAt", descending: true)
                .getDocuments()
            
            // photoId별로 그룹화
            var groupedRecords: [String: [PhotoViewRecord]] = [:]
            
            for doc in viewRecordsSnapshot.documents {
                let data = doc.data()
                guard let photoId = data["photoId"] as? String,
                      let viewedAtTimestamp = data["viewedAt"] as? Timestamp else {
                    continue
                }
                
                let record = PhotoViewRecord(
                    id: doc.documentID,
                    photoId: photoId,
                    teacherId: data["teacherId"] as? String ?? "",
                    boardId: data["boardId"] as? String ?? "",
                    viewedAt: viewedAtTimestamp.dateValue(),
                    sessionDuration: data["sessionDuration"] as? TimeInterval
                )
                
                if groupedRecords[photoId] == nil {
                    groupedRecords[photoId] = []
                }
                groupedRecords[photoId]?.append(record)
            }
            
            // 각 photoId에 대한 상태 계산
            var statuses: [String: PhotoViewStatus] = [:]
            
            for (photoId, records) in groupedRecords {
                let status = PhotoViewStatus(
                    photoId: photoId,
                    totalViews: records.count,
                    uniqueViewers: Set(records.map { $0.teacherId }).count,
                    lastViewedAt: records.first?.viewedAt,
                    lastViewedBy: records.first?.teacherId,
                    isViewed: !records.isEmpty,
                    viewRecords: records
                )
                
                statuses[photoId] = status
            }
            
            print("✅ 게시판 조회 상태 완료: \(statuses.count)개 사진")
            return statuses
            
        } catch {
            print("❌ getBoardPhotoViewStatuses 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    // MARK: - Teacher Statistics
    
    public func getTeacherViewStats(teacherId: String) async throws -> TeacherViewStats {
        do {
            print("📊 교사 \(teacherId)의 조회 통계 조회")
            
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            // 전체 조회 기록
            let allViewsSnapshot = try await firestore.collection("photo_views")
                .whereField("teacherId", isEqualTo: teacherId)
                .order(by: "viewedAt", descending: true)
                .getDocuments()
            
            // 오늘 조회 기록
            let todayViewsSnapshot = try await firestore.collection("photo_views")
                .whereField("teacherId", isEqualTo: teacherId)
                .whereField("viewedAt", isGreaterThanOrEqualTo: Timestamp(date: today))
                .whereField("viewedAt", isLessThan: Timestamp(date: tomorrow))
                .getDocuments()
            
            // 통계 계산
            let totalPhotosViewed = Set(allViewsSnapshot.documents.compactMap { 
                $0.data()["photoId"] as? String 
            }).count
            
            let todayPhotosViewed = Set(todayViewsSnapshot.documents.compactMap { 
                $0.data()["photoId"] as? String 
            }).count
            
            // 평균 조회 시간 계산 (세션 시간이 있는 기록만)
            let sessionDurations = allViewsSnapshot.documents.compactMap { doc -> TimeInterval? in
                guard let duration = doc.data()["sessionDuration"] as? TimeInterval,
                      duration > 0 else { return nil }
                return duration
            }
            
            let averageViewTime = sessionDurations.isEmpty ? 0 : 
                sessionDurations.reduce(0, +) / Double(sessionDurations.count)
            
            // 게시판별 활동 통계
            var boardsActivity: [String: Int] = [:]
            for doc in allViewsSnapshot.documents {
                if let boardId = doc.data()["boardId"] as? String {
                    boardsActivity[boardId, default: 0] += 1
                }
            }
            
            // 마지막 활동 날짜
            let lastActiveDate = allViewsSnapshot.documents.first?.data()["viewedAt"] as? Timestamp
            
            let stats = TeacherViewStats(
                teacherId: teacherId,
                totalPhotosViewed: totalPhotosViewed,
                todayPhotosViewed: todayPhotosViewed,
                averageViewTime: averageViewTime,
                lastActiveDate: lastActiveDate?.dateValue(),
                boardsActivity: boardsActivity
            )
            
            print("✅ 교사 통계: 총 \(totalPhotosViewed)개 조회, 오늘 \(todayPhotosViewed)개")
            return stats
            
        } catch {
            print("❌ getTeacherViewStats 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    // MARK: - Bulk Operations
    
    public func markPhotosAsViewed(photoIds: [String], teacherId: String, boardId: String) async throws {
        do {
            print("✅ 일괄 확인 처리: \(photoIds.count)개 사진")
            
            let batch = firestore.batch()
            let viewedAt = Date()
            
            for photoId in photoIds {
                let viewRecord = PhotoViewRecord(
                    photoId: photoId,
                    teacherId: teacherId,
                    boardId: boardId,
                    viewedAt: viewedAt,
                    sessionDuration: nil // 일괄 처리는 세션 시간 없음
                )
                
                let docRef = firestore.collection("photo_views").document(viewRecord.id)
                batch.setData([
                    "photoId": viewRecord.photoId,
                    "teacherId": viewRecord.teacherId,
                    "boardId": viewRecord.boardId,
                    "viewedAt": Timestamp(date: viewRecord.viewedAt),
                    "sessionDuration": 0
                ], forDocument: docRef)
            }
            
            try await batch.commit()
            print("✅ 일괄 확인 처리 완료")
            
        } catch {
            print("❌ markPhotosAsViewed 오류: \(error)")
            throw WallyError.networkError
        }
    }
}