# Firebase 설정 가이드

## 📱 GoogleService-Info.plist 설정

### 1. Firebase Console에서 설정 파일 다운로드
1. [Firebase Console](https://console.firebase.google.com) 접속
2. `wally-b635c` 프로젝트 선택
3. 프로젝트 설정 → 일반 → iOS 앱 → `GoogleService-Info.plist` 다운로드

### 2. 로컬 개발 환경 설정
```bash
# 다운로드한 파일을 적절한 위치에 복사
cp ~/Downloads/GoogleService-Info.plist "WallyHub/Supporting Files/"
```

### 3. 환경별 관리 (선택사항)
```bash
# 개발환경용
cp GoogleService-Info.plist GoogleService-Info-Development.plist

# 운영환경용 (다른 Firebase 프로젝트 사용 시)
cp GoogleService-Info-Production.plist GoogleService-Info.plist
```

## 🔐 보안 설정

### Firebase Console 보안 설정
1. **Authentication → Sign-in method**
   - 승인된 도메인만 설정
   
2. **Project Settings → General**
   - Bundle ID 정확히 설정: `com.wallyhub.app`
   
3. **Firestore Database → Rules**
   - 적절한 보안 규칙 설정

### iOS 번들 ID 확인
- Xcode → WallyHub Target → General → Bundle Identifier
- `com.wallyhub.app`와 일치해야 함

## 🚨 중요 사항

### Git 관리
- `GoogleService-Info.plist`: 실제 파일 (`.gitignore`에서 관리)
- `GoogleService-Info.plist.template`: 템플릿 (Git에 포함)

### API 키 보안
Firebase API 키는 클라이언트 사이드에서 사용되도록 설계되었으므로 공개되어도 상대적으로 안전합니다. 하지만 다음 보안 조치를 권장합니다:

1. **도메인/앱 제한**: Firebase Console에서 특정 도메인/앱에서만 사용 가능하도록 제한
2. **Firestore 규칙**: 데이터베이스 접근 권한 엄격히 관리
3. **API 사용량 모니터링**: 비정상적인 사용 패턴 감지

## 🔄 CI/CD 배포

### GitHub Actions 설정 예시
```yaml
- name: Setup Firebase Config  
  run: |
    echo '${{ secrets.GOOGLE_SERVICE_INFO_PLIST }}' | base64 -d > \
      "WallyHub/Supporting Files/GoogleService-Info.plist"
```

GitHub Secrets에 base64 인코딩된 plist 파일 저장:
```bash
base64 -i GoogleService-Info.plist | pbcopy
# GitHub → Settings → Secrets → GOOGLE_SERVICE_INFO_PLIST에 붙여넣기
```