import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

public protocol AuthenticationService {
    func login(username: String, password: String) async throws -> User
    func signUp(username: String, email: String, password: String) async throws -> User
    func logout() async throws
    func getCurrentUser() -> User?
    func getCurrentAdmin() -> Administrator? // 하위 호환성을 위해 유지
    func isLoggedIn() -> Bool
    func checkAuthState() async -> User?
    
    // 자동 로그인 관리
    func setAutoLoginEnabled(_ enabled: Bool)
    func isAutoLoginEnabled() -> Bool
    
    // 학생 직접 접근 (Firebase Auth 없이)
    func setStudentAccess(student: User) async
    
    // 사용자 정보 조회
    func getUserById(_ userId: String) async throws -> User?
    func getAllUsers() async throws -> [User]
    
    // 이메일 인증 시스템
    func sendEmailVerification(to email: String) async throws -> String
    func verifyEmailCode(email: String, code: String, verificationId: String) async throws -> Bool
    
    // 활동 추적
    func getRecentAuthActivities() async throws -> [AuthActivity]
}

// MARK: - Activity Tracking Models

public struct AuthActivity {
    let id: String
    let type: AuthActivityType
    let userId: String
    let username: String
    let userRole: UserRole
    let description: String
    let timestamp: Date
    
    public enum AuthActivityType {
        case userLogin
        case userSignUp
        case userLogout
        case studentLogin
        case teacherLogin
        case adminLogin
        
        var description: String {
            switch self {
            case .userLogin: return "사용자 로그인"
            case .userSignUp: return "사용자 가입"
            case .userLogout: return "사용자 로그아웃"
            case .studentLogin: return "학생 로그인"
            case .teacherLogin: return "교사 로그인"
            case .adminLogin: return "관리자 로그인"
            }
        }
    }
}


public class FirebaseAuthenticationService: AuthenticationService, ObservableObject {
    @Published public var currentUser: User?
    @Published public var currentAdmin: Administrator? // 하위 호환성을 위해 유지
    @Published public var isAuthenticated: Bool = false
    
    // 자동 로그인 설정
    private let autoLoginKey = "AutoLoginEnabled"
    @Published public var autoLoginEnabled: Bool = true
    
    // Remote Config Service
    private let remoteConfigService: RemoteConfigService
    
    private lazy var db: Firestore = {
        print("🔥 Firestore 초기화 시작: 프로젝트 wally-b635c, 데이터베이스: wallydb")
        
        // wallydb 데이터베이스 사용
        let firestore = Firestore.firestore(database: "wallydb")
        
        // Firestore 설정은 이미 구성되어 있을 수 있으므로 설정하지 않음
        // 필요한 경우 앱 시작 시 한 번만 구성해야 함
        
        print("✅ Firestore 연결 완료: wallydb 데이터베이스")
        return firestore
    }()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    public init(remoteConfigService: RemoteConfigService) {
        // RemoteConfigService 의존성 주입
        self.remoteConfigService = remoteConfigService
        // 저장된 자동 로그인 설정 로드
        self.autoLoginEnabled = UserDefaults.standard.bool(forKey: autoLoginKey)
        if UserDefaults.standard.object(forKey: autoLoginKey) == nil {
            // 처음 실행 시 기본값을 true로 설정
            self.autoLoginEnabled = true
            UserDefaults.standard.set(true, forKey: autoLoginKey)
        }
        
        // Firebase 초기화 완료를 기다린 후 Auth 리스너 설정
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.setupAuthStateListener()
        }
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Authentication Methods
    
    public func login(username: String, password: String) async throws -> User {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        // Remote Config 로딩 확인 (블로킹하지 않음)
        print("🔄 Remote Config 상태 확인 중...")
        
        // 백그라운드에서 Remote Config 새로고침 (로그인 블로킹하지 않음)
        Task.detached { [weak self] in
            try? await self?.remoteConfigService.loadConfiguration()
        }
        
        // 현재 로드된 상태로 진행 (캐시된 값 사용)
        if !remoteConfigService.isConfigurationLoaded {
            print("⚠️ Remote Config 아직 로드되지 않음 - 기본값 사용")
        }
        print("✅ Remote Config 상태 확인 완료")
        
        // 입력 검증
        try validateLoginInput(username: username, password: password)
        
        // 제한된 이메일 접근 검증 (이메일 형식으로 변환 후)
        let email = formatUsernameAsEmail(username)
        try validateRestrictedEmailAccess(email: email, isLogin: true)
        
        do {
            // Firebase Auth에서는 이메일을 사용하므로 username을 이메일 형식으로 변환
            let email = formatUsernameAsEmail(username)
            
            print("🔑 Firebase 로그인 시도: \(email)")
            
            // Firebase Auth로 로그인
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            print("✅ Firebase 인증 성공: \(authResult.user.uid)")
            
            // Firestore에서 사용자 정보 조회 또는 생성
            // 이메일에서 유효한 사용자명 추출
            let extractedUsername = email.components(separatedBy: "@").first ?? "user"
            let user = try await fetchOrCreateUserFromFirestore(
                uid: authResult.user.uid,
                email: email,
                username: extractedUsername
            )
            
            // 교사/관리자만 로그인 허용
            guard user.role == .teacher || user.role == .administrator else {
                print("❌ 학생은 로그인할 수 없습니다: \(user.role)")
                // Firebase에서 로그아웃
                try Auth.auth().signOut()
                throw WallyError.authenticationFailed
            }
            
            // 현재 사용자 설정 (메모리 안전)
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                print("🔄 로그인 성공 - 인증 상태 업데이트 시작")
                print("🔄 이전 상태: isAuthenticated = \(self.isAuthenticated), currentUser = \(self.currentUser?.username ?? "없음")")
                
                self.currentUser = user
                self.currentAdmin = user.toAdministrator() // 하위 호환성
                self.isAuthenticated = true
                
                print("🔄 새 상태: isAuthenticated = \(self.isAuthenticated), currentUser = \(self.currentUser?.username ?? "없음")")
                print("🔄 objectWillChange.send() 호출")
                self.objectWillChange.send()
            }
            
            print("✅ 로그인 완료: \(user.username) (\(user.role.displayName))")
            
            // 로그인 활동 추적
            await trackAuthActivity(
                type: getLoginActivityType(for: user.role),
                user: user,
                description: "\(user.username) \(user.role.displayName) 로그인"
            )
            
            return user
            
        } catch let error as NSError {
            print("❌ 로그인 실패: \(error.localizedDescription)")
            // Firebase Auth 오류를 WallyError로 변환 (로그인)
            throw mapFirebaseAuthError(error, isSignUp: false)
        }
    }
    
    public func logout() async throws {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        do {
            // 로그아웃 전에 현재 사용자 정보 저장
            let currentUser = self.currentUser
            
            try Auth.auth().signOut()
            await MainActor.run {
                self.currentUser = nil
                self.currentAdmin = nil
                self.isAuthenticated = false
            }
            
            // 로그아웃 활동 추적
            if let user = currentUser {
                await trackAuthActivity(
                    type: .userLogout,
                    user: user,
                    description: "\(user.username) \(user.role.displayName) 로그아웃"
                )
            }
        } catch {
            throw WallyError.authenticationFailed
        }
    }
    
    public func signOut() async throws {
        try await logout()
    }
    
    public func getCurrentUser() -> User? {
        return currentUser
    }
    
    public func getCurrentAdmin() -> Administrator? {
        return currentAdmin
    }
    
    public func isLoggedIn() -> Bool {
        guard FirebaseApp.app() != nil else { return false }
        return currentUser != nil && Auth.auth().currentUser != nil
    }
    
    /// 학생 직접 접근 (Firebase Auth 없이)
    public func setStudentAccess(student: User) async {
        await MainActor.run {
            print("🎓 학생 직접 접근: \(student.username)")
            self.currentUser = student
            self.currentAdmin = nil
            self.isAuthenticated = true
            self.objectWillChange.send()
        }
        
        // 학생 로그인 활동 추적
        await trackAuthActivity(
            type: .studentLogin,
            user: student,
            description: "\(student.username) 학생 로그인"
        )
    }
    
    public func checkAuthState() async -> User? {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else { return nil }
        
        guard let firebaseUser = Auth.auth().currentUser else {
            await MainActor.run {
                self.currentUser = nil
                self.currentAdmin = nil
            }
            return nil
        }
        
        do {
            let user = try await fetchUserFromFirestore(uid: firebaseUser.uid)
            await MainActor.run {
                self.currentUser = user
                self.currentAdmin = user?.toAdministrator()
            }
            return user
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.currentAdmin = nil
            }
            return nil
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func setupAuthStateListener() {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            // Firebase가 초기화되지 않았으면 잠시 후 다시 시도
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.setupAuthStateListener()
            }
            return
        }
        
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            // Capture only what's needed up front to avoid unsafe concurrent self capture
            guard let self else { return }
            let autoLoginEnabled = self.autoLoginEnabled
            let fetchUser = self.fetchUserFromFirestore
            let updateUser: (User?) -> Void = { [weak self] user in
                self?.currentUser = user
                self?.currentAdmin = user?.toAdministrator()
                self?.isAuthenticated = (user != nil)
            }

            Task {
                if let firebaseUser {
                    // 자동 로그인이 비활성화된 경우 로그아웃 처리
                    guard autoLoginEnabled else {
                        print("🔐 자동 로그인이 비활성화되어 있어 세션을 종료합니다")
                        try? Auth.auth().signOut()
                        return
                    }

                    // 사용자가 로그인된 상태
                    do {
                        let user = try await fetchUser(firebaseUser.uid)
                        await MainActor.run {
                            print("👤 현재 사용자 변경: \(user?.username ?? "없음")")
                            updateUser(user)
                        }
                    } catch {
                        await MainActor.run {
                            print("❌ 사용자 정보 로드 실패 - 로그아웃 처리")
                            updateUser(nil)
                        }
                    }
                } else {
                    // 사용자가 로그아웃된 상태
                    await MainActor.run {
                        print("🔓 사용자 로그아웃됨")
                        updateUser(nil)
                    }
                }
            }
        }
    }
    
    private func validateLoginInput(username: String, password: String) throws {
        // 사용자명 빈 값 검증 - 명확한 오류 메시지 사용
        let usernameValidation = ValidationUtils.validateNotEmpty(username, error: .invalidInput)
        let passwordValidation = ValidationUtils.validateNotEmpty(password, error: .authenticationFailed)
        
        // 이메일 형식 검증 - 모든 계정은 유효한 이메일이어야 함
        if !username.contains("@") {
            throw WallyError.invalidEmail
        }
        
        let combinedValidation = ValidationUtils.combineValidations([usernameValidation, passwordValidation])
        
        if case .invalid(let error) = combinedValidation {
            throw error
        }
    }
    
    /// 제한된 이메일만 로그인/회원가입 허용
    private func validateRestrictedEmailAccess(email: String, isLogin: Bool) throws {
        // Remote Config에서 이메일 정보 로드
        let adminEmail = remoteConfigService.getAdminEmail()
        let teacherEmail = remoteConfigService.getTeacherEmail()
        let allowedDomain = remoteConfigService.getAllowedDomain()
        
        // Remote Config가 로드되지 않았거나 값이 비어있으면 오류
        if !remoteConfigService.isConfigurationLoaded {
            print("❌ Remote Config가 로드되지 않았습니다")
            throw WallyError.configurationError
        }
        
        if adminEmail.isEmpty && teacherEmail.isEmpty {
            print("❌ Remote Config에서 이메일 설정을 찾을 수 없습니다")
            throw WallyError.configurationError
        }
        
        let allowedEmails = [adminEmail, teacherEmail]
            .filter { !$0.isEmpty }
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        let lowercaseEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🔍 Remote Config에서 로드된 허용 이메일: \(allowedEmails)")
        print("🔍 허용된 도메인: @\(allowedDomain)")
        print("🔍 입력된 이메일: \(lowercaseEmail)")
        
        // 1. 허용된 개별 이메일 체크
        if allowedEmails.contains(lowercaseEmail) {
            print("✅ 허용된 개별 이메일: \(email)")
            return
        }
        
        // 2. 허용된 도메인 체크
        if lowercaseEmail.hasSuffix("@\(allowedDomain.lowercased())") {
            print("✅ 허용된 \(allowedDomain) 도메인: \(email)")
            return
        }
        
        // 3. 허용되지 않은 이메일
        print("❌ 허용되지 않은 이메일: \(email)")
        print("📋 허용된 이메일 목록: \(allowedEmails)")
        print("📋 허용된 도메인: @\(allowedDomain)")
        if isLogin {
            throw WallyError.authenticationFailed
        } else {
            throw WallyError.signUpFailed
        }
    }
    
    private func validateSignUpInput(username: String, email: String, password: String) throws {
        let usernameValidation = ValidationUtils.validateNotEmpty(username, error: .invalidUsername)
        let emailValidation = ValidationUtils.validateNotEmpty(email, error: .invalidEmail)
        let passwordValidation = ValidationUtils.validateLength(password, min: 6, error: .authenticationFailed)
        
        // 이메일 형식 검증 (회원가입 시 반드시 이메일 형식이어야 함)
        let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailFormatValidation = ValidationUtils.validatePattern(email, pattern: emailPattern, error: .invalidEmail)
        
        // 회원가입 시에는 반드시 유효한 이메일 주소여야 함
        guard email.contains("@") && email.contains(".") else {
            throw WallyError.invalidEmail
        }
        
        let combinedValidation = ValidationUtils.combineValidations([
            usernameValidation, emailValidation, passwordValidation, emailFormatValidation
        ])
        
        if case .invalid(let error) = combinedValidation {
            throw error
        }
    }
    
    private func formatUsernameAsEmail(_ username: String) -> String {
        // 이미 이메일 형식인 경우 그대로 반환
        if username.contains("@") {
            return username
        }
        
        // 이메일 형식이 아닌 경우 오류 발생하도록 함
        
        // 일반 사용자의 경우 입력값을 그대로 사용 (이메일 형식이어야 함)
        // 이메일 형식이 아닌 경우 오류가 발생하도록 함
        return username
    }
    
    // MARK: - Sign Up Method
    
    public func signUp(username: String, email: String, password: String) async throws -> User {
        print("🚀 회원가입 시작: \(username), \(email)")
        
        // Firebase 초기화 확인 및 런타임 초기화 시도
        if FirebaseApp.app() == nil {
            print("❌ Firebase가 초기화되지 않음 - 런타임 초기화 시도")
            
            // 런타임에 Firebase 초기화 시도
            if Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
                print("🔄 런타임 Firebase 초기화 시도")
                FirebaseApp.configure()
                
                if FirebaseApp.app() != nil {
                    print("✅ 런타임 Firebase 초기화 성공")
                } else {
                    print("❌ 런타임 Firebase 초기화 실패")
                    throw WallyError.signUpFailed
                }
            } else {
                print("❌ GoogleService-Info.plist 파일이 없음")
                throw WallyError.signUpFailed
            }
        } else {
            print("✅ Firebase 초기화 확인됨")
        }
        
        // 입력 검증
        do {
            try validateSignUpInput(username: username, email: email, password: password)
            print("✅ 입력 검증 통과")
        } catch {
            print("❌ 입력 검증 실패: \(error)")
            throw error
        }
        
        // 제한된 이메일 접근 검증
        do {
            try validateRestrictedEmailAccess(email: email, isLogin: false)
            print("✅ 제한된 이메일 접근 검증 통과")
        } catch {
            print("❌ 제한된 이메일 접근 검증 실패: \(error)")
            throw error
        }
        
        do {
            print("📝 Firebase 회원가입 시도: \(email)")
            
            // Firebase Auth로 회원가입
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            print("✅ Firebase 계정 생성 성공: \(authResult.user.uid)")
            
            // 역할 자동 판별
            let role = UserRole.detectRole(from: email)
            
            // 교사만 회원가입 허용
            guard role == .teacher || role == .administrator else {
                print("❌ 학생은 회원가입할 수 없습니다: \(email)")
                // Firebase Auth 계정 삭제
                try? await authResult.user.delete()
                throw WallyError.signUpFailed
            }
            
            // Firestore에 사용자 정보 저장
            let user = User(
                id: authResult.user.uid,
                role: role,
                username: username,
                email: email,
                boards: []
            )
            
            // Firestore 저장 시도 (실패해도 인증 상태는 유지)
            do {
                try await saveUserToFirestore(user)
            } catch {
                print("⚠️ Firestore 저장 실패하지만 인증은 유지: \(error)")
                // Firestore 저장 실패해도 계속 진행
            }
            
            // 현재 사용자 설정
            await MainActor.run {
                print("🔄 회원가입 성공 - 인증 상태 업데이트 시작")
                print("🔄 이전 상태: isAuthenticated = \(self.isAuthenticated), currentUser = \(self.currentUser?.username ?? "없음")")
                
                self.currentUser = user
                self.currentAdmin = user.toAdministrator() // 하위 호환성
                self.isAuthenticated = true
                
                print("🔄 새 상태: isAuthenticated = \(self.isAuthenticated), currentUser = \(self.currentUser?.username ?? "없음")")
                print("🔄 objectWillChange.send() 호출")
                self.objectWillChange.send()
            }
            
            print("✅ 회원가입 완료: \(user.username) (\(user.role.displayName))")
            
            // 회원가입 활동 추적
            await trackAuthActivity(
                type: .userSignUp,
                user: user,
                description: "\(user.username) \(user.role.displayName) 회원가입"
            )
            
            return user
            
        } catch let error as NSError {
            print("❌ 회원가입 실패 - NSError code: \(error.code), domain: \(error.domain)")
            print("❌ 원본 오류 메시지: \(error.localizedDescription)")
            let mappedError = mapFirebaseAuthError(error, isSignUp: true)
            print("❌ 매핑된 오류: \(mappedError)")
            throw mappedError
        } catch {
            print("❌ 회원가입 실패 - 기타 오류: \(error)")
            throw WallyError.signUpFailed
        }
    }
    
    private func fetchOrCreateUserFromFirestore(uid: String, email: String, username: String) async throws -> User {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        let document = try await db.collection("users").document(uid).getDocument()
        
        if document.exists, let data = document.data() {
            // 기존 사용자 정보 반환
            let roleString = data["role"] as? String ?? "teacher"
            let role = UserRole(rawValue: roleString) ?? UserRole.detectRole(from: email)
            
            // 저장된 username이 이메일 형태면 @ 앞부분만 추출
            let storedUsername = data["username"] as? String ?? username
            let rawUsername = storedUsername.contains("@") ? 
                storedUsername.components(separatedBy: "@").first ?? "user" : storedUsername
            
            // username을 정제 (한글, 영문, 숫자, 언더스코어 허용 - 공백만 제거)
            let cleanUsername = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let user = User(
                id: uid,
                role: role,
                username: cleanUsername,
                email: data["email"] as? String ?? email,
                boards: data["boards"] as? [String] ?? []
            )
            
            try user.validate()
            return user
            
        } else {
            // 새 사용자 정보 생성
            // 이메일에서 유효한 사용자명 추출 (@ 앞부분)
            let rawUsername = email.components(separatedBy: "@").first ?? "user"
            // username을 정제 (한글, 영문, 숫자, 언더스코어 허용 - 공백만 제거)
            let extractedUsername = rawUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 새 사용자 정보 생성: \(extractedUsername) (이메일: \(email))")
            
            let role = UserRole.detectRole(from: email)
            let user = User(
                id: uid,
                role: role,
                username: extractedUsername,
                email: email,
                boards: []
            )
            
            try await saveUserToFirestore(user)
            return user
        }
    }
    
    private func fetchOrCreateAdministratorFromFirestore(uid: String, email: String, username: String) async throws -> Administrator {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        let document = try await db.collection("administrators").document(uid).getDocument()
        
        if document.exists, let data = document.data() {
            // 기존 관리자 정보 반환
            // 저장된 username이 이메일 형태면 @ 앞부분만 추출
            let storedUsername = data["username"] as? String ?? username
            let rawUsername = storedUsername.contains("@") ? 
                storedUsername.components(separatedBy: "@").first ?? "admin" : storedUsername
            
            // username을 검증 패턴에 맞게 정제 (영문, 숫자, 언더스코어만 허용)
            let cleanUsername = rawUsername.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
                
            let administrator = Administrator(
                id: uid,
                username: cleanUsername,
                email: data["email"] as? String ?? email,
                boards: data["boards"] as? [String] ?? []
            )
            
            try administrator.validate()
            return administrator
            
        } else {
            // 새 관리자 정보 생성
            // 이메일에서 유효한 사용자명 추출 (@ 앞부분)
            let rawUsername = email.components(separatedBy: "@").first ?? "admin"
            // username을 검증 패턴에 맞게 정제 (영문, 숫자, 언더스코어만 허용)
            let extractedUsername = rawUsername.replacingOccurrences(of: "[^a-zA-Z0-9_]", with: "_", options: .regularExpression)
            print("📝 새 관리자 정보 생성: \(extractedUsername) (이메일: \(email))")
            
            let administrator = Administrator(
                id: uid,
                username: extractedUsername,
                email: email,
                boards: []
            )
            
            try await saveAdministratorToFirestore(administrator)
            return administrator
        }
    }
    
    private func saveUserToFirestore(_ user: User) async throws {
        print("📝 Firestore 저장 시작: \(user.username) (ID: \(user.id))")
        
        let data: [String: Any] = [
            "username": user.username,
            "email": user.email ?? "",
            "role": user.role.rawValue,
            "boards": user.boards,
            "createdAt": Date().timeIntervalSince1970,
            "updatedAt": Date().timeIntervalSince1970
        ]
        
        print("📝 저장할 데이터: \(data)")
        print("📝 Firestore 컬렉션: users, 문서 ID: \(user.id)")
        
        do {
            print("⏱️ Firestore setData 호출 시작...")
            
            // 직접 setData 호출하여 정확한 오류 확인
            try await db.collection("users").document(user.id).setData(data)
            
            print("✅ Firestore에 사용자 정보 저장 완료: \(user.role.displayName)")
            
            // 저장 확인을 위해 바로 읽어보기
            print("🔍 저장 확인 중...")
            let savedDoc = try await db.collection("users").document(user.id).getDocument()
            if savedDoc.exists {
                print("✅ 저장 확인됨: 문서 존재")
                print("✅ 저장된 데이터: \(savedDoc.data() ?? [:])")
            } else {
                print("❌ 저장 확인 실패: 문서가 존재하지 않음")
            }
        } catch {
            print("❌ Firestore 저장 실패: \(error)")
            print("❌ 오류 상세: \(error.localizedDescription)")
            if let firestoreError = error as NSError? {
                print("❌ Firestore Error Code: \(firestoreError.code)")
                print("❌ Firestore Error Domain: \(firestoreError.domain)")
                print("❌ Firestore Error UserInfo: \(firestoreError.userInfo)")
            }
            throw error
        }
    }
    
    private func fetchUserFromFirestore(uid: String) async throws -> User? {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        let document = try await db.collection("users").document(uid).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        let roleString = data["role"] as? String ?? "teacher"
        let role = UserRole(rawValue: roleString) ?? .teacher
        
        let user = User(
            id: uid,
            role: role,
            username: data["username"] as? String ?? "",
            email: data["email"] as? String,
            boards: data["boards"] as? [String] ?? []
        )
        
        try user.validate()
        return user
    }
    
    private func saveAdministratorToFirestore(_ administrator: Administrator) async throws {
        let data: [String: Any] = [
            "username": administrator.username,
            "email": administrator.email ?? "",
            "boards": administrator.boards,
            "createdAt": Date().timeIntervalSince1970,
            "updatedAt": Date().timeIntervalSince1970
        ]
        
        try await db.collection("administrators").document(administrator.id).setData(data)
        print("✅ Firestore에 관리자 정보 저장 완료")
    }
    
    private func fetchAdministratorFromFirestore(uid: String) async throws -> Administrator? {
        // Firebase 초기화 확인
        guard FirebaseApp.app() != nil else {
            throw WallyError.authenticationFailed
        }
        
        let document = try await db.collection("administrators").document(uid).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        let administrator = Administrator(
            id: uid,
            username: data["username"] as? String ?? "",
            email: data["email"] as? String,
            boards: data["boards"] as? [String] ?? []
        )
        
        try administrator.validate()
        return administrator
    }
    
    private func mapFirebaseAuthError(_ error: NSError, isSignUp: Bool = false) -> WallyError {
        guard let authErrorCode = AuthErrorCode.Code(rawValue: error.code) else {
            print("⚠️ Unknown Firebase Auth Error Code: \(error.code) - \(error.localizedDescription)")
            return isSignUp ? .signUpFailed : .authenticationFailed
        }
        
        switch authErrorCode {
        // 로그인 관련 오류
        case .userNotFound, .wrongPassword:
            return .authenticationFailed
        case .invalidCredential:
            return .authenticationFailed
        case .invalidEmail:
            return .invalidEmail
            
        // 회원가입 관련 오류
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
            
        // 네트워크 관련 오류
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .networkError
            
        // 기타 인증 관련 오류
        case .userDisabled:
            return .authenticationFailed
        case .operationNotAllowed:
            return isSignUp ? .signUpFailed : .authenticationFailed
            
        // 기타 오류
        default:
            print("⚠️ Unmapped Firebase Auth Error: \(authErrorCode) (rawValue: \(error.code)) - \(error.localizedDescription)")
            return isSignUp ? .signUpFailed : .authenticationFailed
        }
    }
    
    // MARK: - 자동 로그인 관리
    
    public func setAutoLoginEnabled(_ enabled: Bool) {
        print("🔐 자동 로그인 설정 변경: \(enabled)")
        autoLoginEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: autoLoginKey)
        
        // 자동 로그인을 비활성화하면 현재 세션도 종료
        if !enabled && isAuthenticated {
            Task {
                try? await logout()
            }
        }
    }
    
    public func isAutoLoginEnabled() -> Bool {
        return autoLoginEnabled
    }
    
    // MARK: - Email Verification System
    
    /// 이메일 인증번호 발송
    public func sendEmailVerification(to email: String) async throws -> String {
        // 6자리 인증번호 생성
        let verificationCode = String(format: "%06d", Int.random(in: 100000...999999))
        let verificationId = UUID().uuidString
        
        print("📧 이메일 인증번호 발송: \(email)")
        print("🔢 인증번호: \(verificationCode)")
        print("🆔 인증 ID: \(verificationId)")
        
        // Firestore에 인증번호 저장 (5분 후 만료)
        let expirationTime = Date().addingTimeInterval(5 * 60) // 5분
        
        let verificationData: [String: Any] = [
            "email": email,
            "code": verificationCode,
            "verificationId": verificationId,
            "expirationTime": expirationTime.timeIntervalSince1970,
            "createdAt": Date().timeIntervalSince1970,
            "isUsed": false
        ]
        
        do {
            try await db.collection("emailVerifications").document(verificationId).setData(verificationData)
            print("✅ 인증번호 Firestore 저장 완료")
            
            // 실제로는 여기서 이메일 발송 서비스를 호출해야 함
            // 현재는 콘솔에만 출력
            print("📧 [개발 모드] 인증번호를 \(email)로 발송했습니다: \(verificationCode)")
            
            return verificationId
            
        } catch {
            print("❌ 인증번호 저장 실패: \(error)")
            throw WallyError.networkError
        }
    }
    
    /// 이메일 인증번호 검증
    public func verifyEmailCode(email: String, code: String, verificationId: String) async throws -> Bool {
        print("🔍 이메일 인증번호 검증: \(email), 코드: \(code), ID: \(verificationId)")
        
        do {
            let document = try await db.collection("emailVerifications").document(verificationId).getDocument()
            
            guard document.exists, let data = document.data() else {
                print("❌ 인증번호 문서가 존재하지 않음")
                throw WallyError.invalidInput
            }
            
            // 데이터 검증
            guard let storedEmail = data["email"] as? String,
                  let storedCode = data["code"] as? String,
                  let expirationTime = data["expirationTime"] as? TimeInterval,
                  let isUsed = data["isUsed"] as? Bool else {
                print("❌ 인증번호 데이터 형식 오류")
                throw WallyError.dataCorruption
            }
            
            // 이미 사용된 코드인지 확인
            if isUsed {
                print("❌ 이미 사용된 인증번호")
                throw WallyError.invalidInput
            }
            
            // 이메일 확인
            if storedEmail.lowercased() != email.lowercased() {
                print("❌ 이메일 불일치: 저장된=\(storedEmail), 입력된=\(email)")
                throw WallyError.invalidInput
            }
            
            // 만료 시간 확인
            let currentTime = Date().timeIntervalSince1970
            if currentTime > expirationTime {
                print("❌ 인증번호 만료")
                throw WallyError.invalidInput
            }
            
            // 인증번호 확인
            if storedCode != code {
                print("❌ 인증번호 불일치: 저장된=\(storedCode), 입력된=\(code)")
                throw WallyError.invalidInput
            }
            
            // 인증번호를 사용됨으로 표시
            try await db.collection("emailVerifications").document(verificationId).updateData([
                "isUsed": true,
                "usedAt": Date().timeIntervalSince1970
            ])
            
            print("✅ 이메일 인증번호 검증 성공")
            return true
            
        } catch {
            print("❌ 인증번호 검증 실패: \(error)")
            throw error
        }
    }
    
    // MARK: - User Information Retrieval
    
    /// 사용자 ID로 사용자 정보 조회
    public func getUserById(_ userId: String) async throws -> User? {
        print("👤 사용자 정보 조회: \(userId)")
        
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard document.exists, let data = document.data() else {
                print("❌ 사용자 문서가 존재하지 않음: \(userId)")
                return nil
            }
            
            let user = User(
                id: userId,
                role: UserRole(rawValue: data["role"] as? String ?? "") ?? .teacher,
                username: data["username"] as? String ?? "",
                email: data["email"] as? String
            )
            
            print("✅ 사용자 정보 조회 성공: \(user.username)")
            return user
            
        } catch {
            print("❌ 사용자 정보 조회 실패: \(error)")
            throw error
        }
    }
    
    /// 모든 사용자 정보 조회
    public func getAllUsers() async throws -> [User] {
        print("👥 모든 사용자 정보 조회")
        
        do {
            let snapshot = try await db.collection("users").getDocuments()
            
            var users: [User] = []
            
            for document in snapshot.documents {
                let data = document.data()
                let user = User(
                    id: document.documentID,
                    role: UserRole(rawValue: data["role"] as? String ?? "") ?? .teacher,
                    username: data["username"] as? String ?? "",
                    email: data["email"] as? String
                )
                users.append(user)
            }
            
            print("✅ 모든 사용자 정보 조회 성공: \(users.count)명")
            return users
            
        } catch {
            print("❌ 모든 사용자 정보 조회 실패: \(error)")
            throw error
        }
    }
    
    // MARK: - Activity Tracking Implementation
    
    /// 인증 활동 추적
    private func trackAuthActivity(type: AuthActivity.AuthActivityType, user: User, description: String) async {
        do {
            let activity = AuthActivity(
                id: UUID().uuidString,
                type: type,
                userId: user.id,
                username: user.username,
                userRole: user.role,
                description: description,
                timestamp: Date()
            )
            
            let activityData: [String: Any] = [
                "id": activity.id,
                "type": type.description,
                "userId": activity.userId,
                "username": activity.username,
                "userRole": activity.userRole.rawValue,
                "description": activity.description,
                "timestamp": activity.timestamp.timeIntervalSince1970,
                "createdAt": Date().timeIntervalSince1970
            ]
            
            try await db.collection("authActivities").document(activity.id).setData(activityData)
            print("✅ 인증 활동 추적 저장: \(description)")
            
        } catch {
            print("❌ 인증 활동 추적 실패: \(error)")
            // 활동 추적 실패는 메인 기능에 영향을 주지 않도록 함
        }
    }
    
    /// 사용자 역할에 따른 로그인 활동 타입 반환
    private func getLoginActivityType(for role: UserRole) -> AuthActivity.AuthActivityType {
        switch role {
        case .student:
            return .studentLogin
        case .teacher:
            return .teacherLogin
        case .administrator:
            return .adminLogin
        }
    }
    
    /// 최근 인증 활동 조회
    public func getRecentAuthActivities() async throws -> [AuthActivity] {
        print("📋 최근 인증 활동 조회")
        
        do {
            let snapshot = try await db.collection("authActivities")
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            var activities: [AuthActivity] = []
            
            for document in snapshot.documents {
                let data = document.data()
                
                guard let id = data["id"] as? String,
                      let typeString = data["type"] as? String,
                      let userId = data["userId"] as? String,
                      let username = data["username"] as? String,
                      let userRoleString = data["userRole"] as? String,
                      let description = data["description"] as? String,
                      let timestamp = data["timestamp"] as? TimeInterval else {
                    continue
                }
                
                // AuthActivityType을 문자열로부터 복원
                let type: AuthActivity.AuthActivityType
                switch typeString {
                case "사용자 로그인": type = .userLogin
                case "사용자 가입": type = .userSignUp
                case "사용자 로그아웃": type = .userLogout
                case "학생 로그인": type = .studentLogin
                case "교사 로그인": type = .teacherLogin
                case "관리자 로그인": type = .adminLogin
                default: continue
                }
                
                let userRole = UserRole(rawValue: userRoleString) ?? .teacher
                
                let activity = AuthActivity(
                    id: id,
                    type: type,
                    userId: userId,
                    username: username,
                    userRole: userRole,
                    description: description,
                    timestamp: Date(timeIntervalSince1970: timestamp)
                )
                
                activities.append(activity)
            }
            
            print("✅ 최근 인증 활동 조회 성공: \(activities.count)개")
            return activities
            
        } catch {
            print("❌ 최근 인증 활동 조회 실패: \(error)")
            throw error
        }
    }
}

