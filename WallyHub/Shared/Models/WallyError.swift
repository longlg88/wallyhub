import Foundation

public enum WallyError: Error, LocalizedError {
    case authenticationFailed
    case signUpFailed
    case emailAlreadyInUse
    case weakPassword
    case invalidQRCode
    case networkError
    case photoUploadFailed
    case photoNotFound
    case insufficientPermissions
    case unauthorized
    case boardNotFound
    case boardNotActive
    case studentRegistrationFailed
    case studentNotFound
    case studentUpdateFailed
    case duplicateStudentId
    case studentNotInBoard
    case dataCorruption
    case invalidInput
    case unknownError
    case configurationError
    
    // 데이터 검증 관련 세부 오류
    case invalidUsername
    case invalidEmail
    case invalidBoardTitle
    case invalidStudentName
    case invalidStudentId
    case invalidTeacherName
    case invalidImageUrl
    case invalidBackgroundColor
    case invalidFontFamily
    
    // QR 스캐너 관련 오류
    case cameraPermissionDenied
    case cameraUnavailable
    case qrScanningFailed
    
    public var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "로그인에 실패했습니다. 허용된 이메일(.env 설정 또는 korea.kr 도메인)과 비밀번호를 확인해주세요."
        case .signUpFailed:
            return "회원가입에 실패했습니다. 허용된 이메일(.env 설정 또는 korea.kr 도메인)과 입력 정보를 확인해주세요."
        case .emailAlreadyInUse:
            return "이미 사용 중인 이메일입니다. 다른 이메일을 사용해주세요."
        case .weakPassword:
            return "비밀번호가 너무 약합니다. 6자 이상의 강한 비밀번호를 사용해주세요."
        case .invalidQRCode:
            return "유효하지 않은 QR 코드입니다. 다시 스캔해주세요."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .photoUploadFailed:
            return "사진 업로드에 실패했습니다. 다시 시도해주세요."
        case .photoNotFound:
            return "사진을 찾을 수 없습니다."
        case .insufficientPermissions:
            return "이 작업을 수행할 권한이 없습니다."
        case .unauthorized:
            return "이 작업을 수행할 권한이 없습니다."
        case .boardNotFound:
            return "게시판을 찾을 수 없습니다."
        case .boardNotActive:
            return "비활성화된 게시판입니다."
        case .studentRegistrationFailed:
            return "학생 등록에 실패했습니다. 입력 정보를 확인해주세요."
        case .studentNotFound:
            return "학생을 찾을 수 없습니다."
        case .studentUpdateFailed:
            return "학생 정보 업데이트에 실패했습니다."
        case .duplicateStudentId:
            return "이미 등록된 학번입니다."
        case .studentNotInBoard:
            return "학생이 해당 게시판에 참여하지 않습니다."
        case .dataCorruption:
            return "데이터가 손상되었습니다."
        case .invalidInput:
            return "입력된 정보가 올바르지 않습니다."
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다."
        case .configurationError:
            return "앱 설정에 문제가 있습니다. 환경 설정 파일을 확인해주세요."
        case .invalidUsername:
            return "사용자명이 올바르지 않습니다. 3-50자의 영문, 숫자, 언더스코어만 사용 가능합니다."
        case .invalidEmail:
            return "이메일 형식이 올바르지 않습니다."
        case .invalidBoardTitle:
            return "게시판 제목이 올바르지 않습니다. 1-100자 이내로 입력해주세요."
        case .invalidStudentName:
            return "학생 이름이 올바르지 않습니다. 1-50자의 한글 또는 영문만 사용 가능합니다."
        case .invalidStudentId:
            return "학번이 올바르지 않습니다. 1-20자의 영문, 숫자, 하이픈만 사용 가능합니다."
        case .invalidTeacherName:
            return "교사 이름이 올바르지 않습니다. 1-50자의 한글 또는 영문만 사용 가능합니다."
        case .invalidImageUrl:
            return "이미지 URL이 올바르지 않습니다."
        case .invalidBackgroundColor:
            return "배경색이 올바르지 않습니다. HEX 색상 코드를 사용해주세요."
        case .invalidFontFamily:
            return "폰트 패밀리가 올바르지 않습니다."
        case .cameraPermissionDenied:
            return "카메라 권한이 거부되었습니다."
        case .cameraUnavailable:
            return "카메라를 사용할 수 없습니다."
        case .qrScanningFailed:
            return "QR 코드 스캔에 실패했습니다."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .authenticationFailed:
            return "허용된 이메일(.env 파일에 설정된 이메일 또는 korea.kr 도메인)과 비밀번호를 다시 확인하고 시도해주세요."
        case .signUpFailed:
            return "허용된 이메일(.env 파일에 설정된 이메일 또는 korea.kr 도메인)로 회원가입을 시도해주세요."
        case .emailAlreadyInUse:
            return "다른 이메일 주소를 사용하거나 로그인을 시도해주세요."
        case .weakPassword:
            return "최소 6자 이상의 비밀번호를 사용해주세요."
        case .invalidQRCode:
            return "QR 코드를 다시 스캔하거나 관리자에게 문의하세요."
        case .networkError:
            return "인터넷 연결을 확인하고 다시 시도해주세요."
        case .photoUploadFailed:
            return "네트워크 상태를 확인하고 다시 업로드해주세요."
        case .photoNotFound:
            return "사진이 삭제되었거나 존재하지 않습니다. 새로고침 후 다시 시도해주세요."
        case .insufficientPermissions:
            return "관리자에게 권한을 요청하세요."
        case .unauthorized:
            return "해당 작업에 대한 권한이 없습니다. 관리자에게 문의하세요."
        case .boardNotFound:
            return "올바른 QR 코드인지 확인하거나 관리자에게 문의하세요."
        case .boardNotActive:
            return "관리자에게 게시판 활성화를 요청하세요."
        case .studentRegistrationFailed:
            return "이름과 학번을 정확히 입력했는지 확인해주세요."
        case .studentNotFound:
            return "학생 정보를 다시 확인하거나 관리자에게 문의하세요."
        case .studentUpdateFailed:
            return "네트워크 상태를 확인하고 다시 시도해주세요."
        case .duplicateStudentId:
            return "다른 학번을 사용하거나 관리자에게 문의하세요."
        case .studentNotInBoard:
            return "학생이 해당 게시판에 참여했는지 확인하거나 관리자에게 문의하세요."
        case .dataCorruption:
            return "앱을 다시 시작하거나 관리자에게 문의하세요."
        case .invalidInput:
            return "모든 필수 항목을 올바르게 입력해주세요."
        case .unknownError:
            return "앱을 다시 시작하거나 관리자에게 문의하세요."
        case .configurationError:
            return ".env 파일이 Resources 폴더에 포함되어 있는지 확인하고, ADMIN_EMAIL과 TEACHER_EMAIL이 설정되어 있는지 확인하세요."
        case .invalidUsername:
            return "3자 이상 50자 이하의 영문, 숫자, 언더스코어로 구성된 사용자명을 입력해주세요."
        case .invalidEmail:
            return "올바른 이메일 주소를 입력해주세요. (예: user@example.com)"
        case .invalidBoardTitle:
            return "1자 이상 100자 이하의 게시판 제목을 입력해주세요."
        case .invalidStudentName:
            return "1자 이상 50자 이하의 한글 또는 영문 이름을 입력해주세요."
        case .invalidStudentId:
            return "1자 이상 20자 이하의 영문, 숫자, 하이픈으로 구성된 학번을 입력해주세요."
        case .invalidTeacherName:
            return "1자 이상 50자 이하의 한글 또는 영문 이름을 입력해주세요."
        case .invalidImageUrl:
            return "올바른 이미지 URL을 제공해주세요."
        case .invalidBackgroundColor:
            return "#FFFFFF 형식의 HEX 색상 코드를 입력해주세요."
        case .invalidFontFamily:
            return "올바른 폰트 패밀리 이름을 입력해주세요."
        case .cameraPermissionDenied:
            return "설정에서 카메라 권한을 허용해주세요."
        case .cameraUnavailable:
            return "기기의 카메라 상태를 확인해주세요."
        case .qrScanningFailed:
            return "QR 코드를 다시 스캔해주세요."
        }
    }
}

// MARK: - Error Handling Utilities
extension WallyError {
    /// 오류를 사용자 친화적인 메시지로 변환합니다
    static func userFriendlyMessage(for error: Error) -> String {
        print("🔵 WallyError.userFriendlyMessage 호출됨")
        print("🔵 입력 오류: \(error)")
        print("🔵 오류 타입: \(type(of: error))")
        
        if let wallyError = error as? WallyError {
            print("🔵 WallyError로 인식됨: \(wallyError)")
            let message = wallyError.errorDescription ?? "알 수 없는 오류가 발생했습니다."
            print("🔵 반환할 메시지: \(message)")
            return message
        }
        
        // 시스템 오류를 Wally 오류로 매핑
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
            print("🔵 네트워크 오류로 매핑됨")
            return WallyError.networkError.errorDescription ?? "네트워크 오류가 발생했습니다."
        }
        
        let message = "오류가 발생했습니다: \(error.localizedDescription)"
        print("🔵 기본 오류 메시지 반환: \(message)")
        return message
    }
    
    /// 복구 제안을 포함한 완전한 오류 메시지를 반환합니다
    var fullErrorMessage: String {
        var message = errorDescription ?? "알 수 없는 오류가 발생했습니다."
        
        if let suggestion = recoverySuggestion {
            message += "\n\n해결 방법: \(suggestion)"
        }
        
        return message
    }
    
    /// 오류 로깅을 위한 상세 정보를 반환합니다
    var debugDescription: String {
        return """
        WallyError: \(self)
        Description: \(errorDescription ?? "No description")
        Recovery Suggestion: \(recoverySuggestion ?? "No suggestion")
        """
    }
}

// MARK: - Validation Result
/// 검증 결과를 나타내는 열거형
public enum ValidationResult {
    case valid
    case invalid(WallyError)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var error: WallyError? {
        switch self {
        case .valid:
            return nil
        case .invalid(let error):
            return error
        }
    }
}

// MARK: - Validation Utilities
public struct ValidationUtils {
    /// 문자열이 비어있지 않은지 검증합니다
    public static func validateNotEmpty(_ string: String, error: WallyError = .invalidInput) -> ValidationResult {
        guard !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .invalid(error)
        }
        return .valid
    }
    
    /// 문자열 길이를 검증합니다
    public static func validateLength(_ string: String, min: Int = 0, max: Int = Int.max, error: WallyError = .invalidInput) -> ValidationResult {
        let length = string.count
        guard length >= min && length <= max else {
            return .invalid(error)
        }
        return .valid
    }
    
    /// 정규식 패턴을 검증합니다
    public static func validatePattern(_ string: String, pattern: String, error: WallyError = .invalidInput) -> ValidationResult {
        let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
        guard predicate.evaluate(with: string) else {
            return .invalid(error)
        }
        return .valid
    }
    
    /// 여러 검증 결과를 결합합니다
    public static func combineValidations(_ validations: [ValidationResult]) -> ValidationResult {
        for validation in validations {
            if case .invalid(let error) = validation {
                return .invalid(error)
            }
        }
        return .valid
    }
}