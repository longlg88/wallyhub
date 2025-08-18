import Foundation
import FirebaseStorage
import FirebaseFirestore
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif


public protocol PhotoService {
    #if canImport(UIKit)
    func uploadPhoto(image: UIImage, studentId: String, boardId: String, title: String) async throws -> Photo
    #endif
    #if canImport(AppKit)
    func uploadPhoto(image: NSImage, studentId: String, boardId: String, title: String) async throws -> Photo
    #endif
    func uploadPhoto(imageData: Data, studentId: String, boardId: String, title: String) async throws -> Photo
    func deletePhoto(photoId: String, studentId: String) async throws
    func getPhotosForBoard(boardId: String) async throws -> [Photo]
    func getPhotosForStudent(studentId: String, boardId: String) async throws -> [Photo]
    func updatePhotoVisibility(photoId: String, isVisible: Bool, studentId: String) async throws
    func getAllPhotos() async throws -> [Photo]
}

public class FirebasePhotoService: PhotoService, ObservableObject {
    @Published var photos: [Photo] = []
    
    private let storage = Storage.storage()
    private lazy var firestore: Firestore = {
        print("🔥 PhotoService Firestore 초기화: 데이터베이스 wallydb")
        let firestore = Firestore.firestore(database: "wallydb")
        print("✅ PhotoService Firestore 연결 완료: wallydb 데이터베이스")
        return firestore
    }()
    
    // MARK: - Image Compression Settings
    private let maxImageSize: CGFloat = 1024 // Maximum width/height in pixels
    private let compressionQuality: CGFloat = 0.8 // JPEG compression quality
    private let maxFileSizeBytes: Int = 5 * 1024 * 1024 // 5MB limit
    
    // MARK: - Photo Upload
    #if canImport(UIKit)
    public func uploadPhoto(image: UIImage, studentId: String, boardId: String, title: String) async throws -> Photo {
        // Validate input parameters (imageUrl은 nil로 전달 - 업로드 전이므로 유효한 상태)
        try Photo.validateForUpload(studentId: studentId, boardId: boardId, imageUrl: nil)
        
        // Compress and optimize image
        let compressedImageData = try compressImage(image)
        
        // Generate unique photo ID and storage path
        let photoId = UUID().uuidString
        let storagePath = "boards/\(boardId)/photos/\(photoId).jpg"
        let storageRef = storage.reference().child(storagePath)
        
        do {
            // Upload image to Firebase Storage
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.customMetadata = [
                "studentId": studentId,
                "boardId": boardId,
                "uploadedBy": "student"
            ]
            
            let _ = try await storageRef.putDataAsync(compressedImageData, metadata: metadata)
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Create photo object
            let photo = Photo(
                id: photoId,
                title: title,
                studentId: studentId,
                boardId: boardId,
                imageUrl: downloadURL.absoluteString,
                uploadedAt: Date(),
                isVisible: true
            )
            
            // Save photo metadata to Firestore
            try await savePhotoMetadata(photo)
            
            return photo
            
        } catch {
            // Clean up storage if Firestore save fails
            try? await storageRef.delete()
            throw WallyError.photoUploadFailed
        }
    }
    
    public func uploadPhoto(imageData: Data, studentId: String, boardId: String, title: String) async throws -> Photo {
        // Validate input parameters (imageUrl은 nil로 전달 - 업로드 전이므로 유효한 상태)
        try Photo.validateForUpload(studentId: studentId, boardId: boardId, imageUrl: nil)
        
        // Validate file size
        guard imageData.count <= maxFileSizeBytes else {
            throw WallyError.photoUploadFailed
        }
        
        // Generate unique photo ID and storage path
        let photoId = UUID().uuidString
        let storagePath = "boards/\(boardId)/photos/\(photoId).jpg"
        let storageRef = storage.reference().child(storagePath)
        
        do {
            // Upload image to Firebase Storage
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            metadata.customMetadata = [
                "studentId": studentId,
                "boardId": boardId,
                "uploadedBy": "student"
            ]
            
            let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            
            // Create photo object
            let photo = Photo(
                id: photoId,
                title: title,
                studentId: studentId,
                boardId: boardId,
                imageUrl: downloadURL.absoluteString,
                uploadedAt: Date(),
                isVisible: true
            )
            
            // Save photo metadata to Firestore
            try await savePhotoMetadata(photo)
            
            return photo
            
        } catch {
            // Clean up storage if Firestore save fails
            try? await storageRef.delete()
            throw WallyError.photoUploadFailed
        }
    }
    #endif
    
    #if canImport(AppKit)
    public func uploadPhoto(image: NSImage, studentId: String, boardId: String) async throws -> Photo {
        // Validate input parameters
        try Photo.validateForUpload(studentId: studentId, boardId: boardId, imageUrl: nil)
        
        // Convert NSImage to Data
        guard let imageData = compressNSImage(image) else {
            throw WallyError.photoUploadFailed
        }
        
        // Use the existing imageData upload method
        return try await uploadPhoto(imageData: imageData, studentId: studentId, boardId: boardId)
    }
    #endif
    
    // MARK: - Photo Deletion
    public func deletePhoto(photoId: String, studentId: String) async throws {
        do {
            print("🗑️ PhotoService.deletePhoto 시작 - photoId: \(photoId), studentId: \(studentId)")
            
            // 1단계: studentId(학번)로 실제 student 문서 찾기
            let studentsQuery = try await firestore.collection("students")
                .whereField("studentId", isEqualTo: studentId)
                .limit(to: 1)
                .getDocuments()
            
            guard let studentDoc = studentsQuery.documents.first else {
                print("❌ 학번 \(studentId)에 해당하는 학생을 찾을 수 없음")
                throw WallyError.studentNotFound
            }
            
            let studentDocId = studentDoc.documentID
            print("✅ 학생 문서 발견: \(studentDocId)")
            
            // 2단계: students/{studentDocId}/uploads/{photoId}에서 사진 메타데이터 조회
            let photoDoc = try await firestore.collection("students")
                .document(studentDocId)
                .collection("uploads")
                .document(photoId)
                .getDocument()
            
            guard photoDoc.exists,
                  let photoData = photoDoc.data(),
                  let photoStudentId = photoData["studentId"] as? String,
                  let boardId = photoData["boardId"] as? String else {
                print("❌ 사진 메타데이터를 찾을 수 없음: \(photoId)")
                throw WallyError.photoNotFound
            }
            
            // 3단계: 권한 검증 - 본인이 업로드한 사진만 삭제 가능
            guard photoStudentId == studentId else {
                print("❌ 권한 없음: 다른 학생의 사진")
                throw WallyError.insufficientPermissions
            }
            
            print("✅ 권한 검증 완료 - boardId: \(boardId)")
            
            // 4단계: Firebase Storage에서 이미지 파일 삭제
            let storagePath = "boards/\(boardId)/photos/\(photoId).jpg"
            let storageRef = storage.reference().child(storagePath)
            
            print("🗂️ Storage 파일 삭제 중: \(storagePath)")
            try await storageRef.delete()
            print("✅ Storage 파일 삭제 완료")
            
            // 5단계: Firestore에서 메타데이터 삭제
            try await firestore.collection("students")
                .document(studentDocId)
                .collection("uploads")
                .document(photoId)
                .delete()
            
            print("✅ Firestore 메타데이터 삭제 완료")
            print("🎉 사진 삭제 성공: \(photoId)")
            
        } catch let error as WallyError {
            print("❌ PhotoService.deletePhoto WallyError: \(error)")
            throw error
        } catch {
            print("❌ PhotoService.deletePhoto 네트워크 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
    // MARK: - Photo Retrieval
    public func getPhotosForBoard(boardId: String) async throws -> [Photo] {
        do {
            print("📸 PhotoService.getPhotosForBoard 시작 - boardId: \(boardId)")
            
            // 1단계: 해당 게시판의 모든 학생 찾기
            let studentsQuery = try await firestore.collection("students")
                .whereField("boardId", isEqualTo: boardId)
                .getDocuments()
            
            print("📊 게시판 \(boardId)의 학생 수: \(studentsQuery.documents.count)")
            
            var allPhotos: [Photo] = []
            
            // 2단계: 각 학생의 uploads 서브컬렉션에서 사진 조회
            for studentDoc in studentsQuery.documents {
                let studentId = studentDoc.documentID
                let studentData = studentDoc.data()
                let studentName = studentData["name"] as? String ?? "알 수 없음"
                
                print("🔍 학생 \(studentName) (\(studentId))의 사진 조회 중...")
                
                let uploadsQuery = try await firestore.collection("students")
                    .document(studentId)
                    .collection("uploads")
                    .getDocuments()
                
                print("   📷 \(studentName)의 사진 수: \(uploadsQuery.documents.count)")
                
                for uploadDoc in uploadsQuery.documents {
                    let data = uploadDoc.data()
                    
                    if let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue() {
                        let photo = Photo(
                            id: uploadDoc.documentID,
                            title: data["title"] as? String ?? "",
                            studentId: studentData["studentId"] as? String ?? "알 수 없음", // 학번
                            boardId: boardId,
                            imageUrl: data["imageUrl"] as? String,
                            uploadedAt: uploadedAt,
                            isVisible: data["isVisible"] as? Bool ?? true
                        )
                        
                        // isVisible이 true인 사진만 포함
                        if photo.isVisible {
                            allPhotos.append(photo)
                        }
                    }
                }
            }
            
            print("📊 총 조회된 사진 수: \(allPhotos.count)")
            
            // 업로드 시간 기준으로 정렬 (최신순)
            return allPhotos.sorted { $0.uploadedAt > $1.uploadedAt }
            
        } catch {
            print("❌ getPhotosForBoard 실패: \(error)")
            throw WallyError.networkError
        }
    }
    
    public func getPhotosForStudent(studentId: String, boardId: String) async throws -> [Photo] {
        do {
            print("📸 PhotoService.getPhotosForStudent 시작 - studentId: \(studentId), boardId: \(boardId)")
            
            // 1단계: studentId(학번)로 실제 student 문서 찾기
            let studentsQuery = try await firestore.collection("students")
                .whereField("studentId", isEqualTo: studentId)
                .whereField("boardId", isEqualTo: boardId)
                .getDocuments()
            
            guard let studentDoc = studentsQuery.documents.first else {
                print("❌ 학번 \(studentId)에 해당하는 학생을 찾을 수 없음 (boardId: \(boardId))")
                return []
            }
            
            let studentDocId = studentDoc.documentID
            let studentData = studentDoc.data()
            let studentName = studentData["name"] as? String ?? "알 수 없음"
            
            print("✅ 학생 문서 발견: \(studentName) (\(studentDocId))")
            
            // 2단계: students/{studentDocId}/uploads 서브컬렉션에서 사진 조회
            let uploadsQuery = try await firestore.collection("students")
                .document(studentDocId)
                .collection("uploads")
                .getDocuments()
            
            print("📊 \(studentName)의 사진 수: \(uploadsQuery.documents.count)")
            
            let photos = uploadsQuery.documents.compactMap { document -> Photo? in
                let data = document.data()
                
                guard let uploadedAt = (data["uploadedAt"] as? Timestamp)?.dateValue() else {
                    print("❌ Photo 디코딩 실패: uploadedAt 누락 - 문서 ID: \(document.documentID)")
                    return nil
                }
                
                return Photo(
                    id: document.documentID,
                    title: data["title"] as? String ?? "",
                    studentId: studentId, // 학번 사용
                    boardId: boardId,
                    imageUrl: data["imageUrl"] as? String,
                    uploadedAt: uploadedAt,
                    isVisible: data["isVisible"] as? Bool ?? true
                )
            }
            
            print("📊 조회된 사진 수: \(photos.count)")
            
            // 업로드 시간 기준으로 정렬 (최신순)
            return photos.sorted { $0.uploadedAt > $1.uploadedAt }
            
        } catch {
            print("❌ getPhotosForStudent 실패: \(error)")
            throw WallyError.networkError
        }
    }
    
    // MARK: - Photo Visibility Management
    public func updatePhotoVisibility(photoId: String, isVisible: Bool, studentId: String) async throws {
        do {
            // Get photo metadata from Firestore
            let photoDoc = try await firestore.collection("photos").document(photoId).getDocument()
            
            guard photoDoc.exists,
                  let photoData = photoDoc.data(),
                  let photoStudentId = photoData["studentId"] as? String else {
                throw WallyError.boardNotFound
            }
            
            // Verify permission - only the student who uploaded can modify visibility
            guard photoStudentId == studentId else {
                throw WallyError.insufficientPermissions
            }
            
            // Update visibility
            try await firestore.collection("photos").document(photoId).updateData([
                "isVisible": isVisible
            ])
            
        } catch let error as WallyError {
            throw error
        } catch {
            throw WallyError.networkError
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func savePhotoMetadata(_ photo: Photo) async throws {
        do {
            try photo.validate()
            
            // 학생 문서 찾기 (studentId는 학생의 학번이므로 실제 Firestore document ID를 찾아야 함)
            let studentsQuery = try await firestore.collection("students")
                .whereField("studentId", isEqualTo: photo.studentId)
                .limit(to: 1)
                .getDocuments()
            
            guard let studentDoc = studentsQuery.documents.first else {
                print("❌ 학생 문서를 찾을 수 없습니다: studentId = \(photo.studentId)")
                throw WallyError.dataCorruption
            }
            
            let studentDocId = studentDoc.documentID
            print("📝 사진 메타데이터 저장: students/\(studentDocId)/uploads/\(photo.id)")
            
            // students/{docId}/uploads/{photoId}에 저장
            try await firestore.collection("students")
                .document(studentDocId)
                .collection("uploads")
                .document(photo.id)
                .setData([
                    "id": photo.id,
                    "title": photo.title,
                    "studentId": photo.studentId,
                    "boardId": photo.boardId,
                    "imageUrl": photo.imageUrl ?? "",
                    "uploadedAt": Timestamp(date: photo.uploadedAt),
                    "isVisible": photo.isVisible
                ])
        } catch {
            print("❌ 사진 메타데이터 저장 실패: \(error)")
            throw WallyError.dataCorruption
        }
    }
    
    #if canImport(UIKit)
    private func compressImage(_ image: UIImage) throws -> Data {
        // Calculate target size maintaining aspect ratio
        let targetSize = calculateTargetSize(for: image.size)
        
        // Resize image
        let resizedImage = resizeImage(image, to: targetSize)
        
        // Compress to JPEG
        guard let compressedData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw WallyError.photoUploadFailed
        }
        
        // Check if compressed data is within size limit
        guard compressedData.count <= maxFileSizeBytes else {
            // Try with lower compression quality
            guard let furtherCompressedData = resizedImage.jpegData(compressionQuality: 0.5) else {
                throw WallyError.photoUploadFailed
            }
            
            guard furtherCompressedData.count <= maxFileSizeBytes else {
                throw WallyError.photoUploadFailed
            }
            
            return furtherCompressedData
        }
        
        return compressedData
    }
    
    private func calculateTargetSize(for originalSize: CGSize) -> CGSize {
        let maxDimension = maxImageSize
        
        if originalSize.width <= maxDimension && originalSize.height <= maxDimension {
            return originalSize
        }
        
        let aspectRatio = originalSize.width / originalSize.height
        
        if originalSize.width > originalSize.height {
            // Landscape
            return CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            // Portrait or square
            return CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
    }
    
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    #endif
    
    #if canImport(AppKit)
    private func compressNSImage(_ image: NSImage) -> Data? {
        // Calculate target size maintaining aspect ratio
        let targetSize = calculateTargetSize(for: image.size)
        
        // Resize image
        let resizedImage = resizeNSImage(image, to: targetSize)
        
        // Convert to JPEG data
        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality]) else {
            return nil
        }
        
        // Check if compressed data is within size limit
        if jpegData.count <= maxFileSizeBytes {
            return jpegData
        }
        
        // Try with lower compression quality
        guard let furtherCompressedData = bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) else {
            return nil
        }
        
        return furtherCompressedData.count <= maxFileSizeBytes ? furtherCompressedData : nil
    }
    
    private func resizeNSImage(_ image: NSImage, to targetSize: CGSize) -> NSImage {
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(in: CGRect(origin: .zero, size: targetSize))
        newImage.unlockFocus()
        return newImage
    }
    #endif
    
    // MARK: - Get All Photos
    
    public func getAllPhotos() async throws -> [Photo] {
        print("📸 PhotoService.getAllPhotos 시작 - 전체 사진 조회")
        
        do {
            // 모든 학생의 업로드 서브컬렉션을 조회하기 위해 두 단계로 진행
            // 1단계: 모든 학생 문서 조회
            let studentsSnapshot = try await firestore.collection("students").getDocuments()
            print("📊 전체 학생 수: \(studentsSnapshot.documents.count)")
            
            var allPhotos: [Photo] = []
            
            // 2단계: 각 학생의 uploads 서브컬렉션에서 사진 조회
            for studentDoc in studentsSnapshot.documents {
                let studentId = studentDoc.documentID
                let studentData = studentDoc.data()
                let studentName = studentData["name"] as? String ?? "알 수 없음"
                let boardId = studentData["boardId"] as? String ?? ""
                
                print("🔍 학생 \(studentName)의 사진 조회 중...")
                
                do {
                    let photosSnapshot = try await firestore.collection("students")
                        .document(studentId)
                        .collection("uploads")
                        .order(by: "uploadedAt", descending: true)
                        .getDocuments()
                    
                    print("📷 \(studentName): \(photosSnapshot.documents.count)개 사진 발견")
                    
                    for photoDoc in photosSnapshot.documents {
                        do {
                            let photoData = photoDoc.data()
                            
                            // 필수 필드 확인
                            guard let uploadedAtTimestamp = photoData["uploadedAt"] as? Timestamp else {
                                print("⚠️ 사진 \(photoDoc.documentID): uploadedAt 필드 누락")
                                continue
                            }
                            
                            let photo = Photo(
                                id: photoDoc.documentID,
                                title: photoData["title"] as? String ?? "",
                                studentId: studentData["studentId"] as? String ?? "", // 실제 학번 사용
                                boardId: boardId,
                                imageUrl: photoData["imageUrl"] as? String,
                                uploadedAt: uploadedAtTimestamp.dateValue(),
                                isVisible: photoData["isVisible"] as? Bool ?? true
                            )
                            
                            allPhotos.append(photo)
                            
                        } catch {
                            print("❌ 사진 파싱 실패 (\(photoDoc.documentID)): \(error)")
                        }
                    }
                } catch {
                    print("⚠️ 학생 \(studentName)의 사진 조회 실패: \(error)")
                }
            }
            
            // 업로드 시간순으로 정렬 (최신순)
            let sortedPhotos = allPhotos.sorted { $0.uploadedAt > $1.uploadedAt }
            
            print("✅ 전체 사진 조회 완료: \(sortedPhotos.count)개")
            return sortedPhotos
            
        } catch {
            print("❌ getAllPhotos 오류: \(error)")
            throw WallyError.networkError
        }
    }
    
}
