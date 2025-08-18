import RIBs
import SwiftUI
import UIKit
import AVFoundation

final class QRScannerViewController: UIViewController, QRScannerPresentable, QRScannerViewControllable {

    weak var listener: QRScannerPresentableListener?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var metadataOutput: AVCaptureMetadataOutput?
    private var scanResult: (boardId: String, boardName: String)?
    private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    private var hostingController: UIHostingController<QRScannerViewContent>?

    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraPermission()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if cameraPermissionStatus == .authorized {
            startScanning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 🚨 CRITICAL: 즉시 동기적으로 delegate 제거하여 순환 참조 방지
        metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
        
        // 세션 즉시 중단
        captureSession?.stopRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // 완전히 사라진 후 추가 정리
        if isBeingDismissed || isMovingFromParent {
            cleanupCamera()
        }
    }
    
    deinit {
        print("🗑️ QRScannerViewController: deinit 호출됨")
        
        // 🚨 CRITICAL: 즉시 동기적으로 delegate 제거 (순환 참조 해제)
        metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
        
        // 세션 즉시 정지
        captureSession?.stopRunning()
        
        // 모든 참조 즉시 해제
        metadataOutput = nil
        previewLayer?.removeFromSuperlayer()
        previewLayer = nil
        captureSession = nil
        
        // 호스팅 컨트롤러 즉시 정리
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        
        print("✅ QRScannerViewController: deinit 완료")
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if cameraPermissionStatus == .authorized {
            setupCamera()
        }
    }
    
    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionStatus = granted ? .authorized : .denied
                if granted {
                    self?.setupCamera()
                }
                self?.updateUI()
            }
        }
    }
    
    private func setupCamera() {
        guard cameraPermissionStatus == .authorized else { return }
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let output = AVCaptureMetadataOutput()
            metadataOutput = output
            captureSession?.addOutput(output)
            
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
            
            // 스캔 영역을 중앙 프레임으로 제한 (250x250 영역에 해당)
            // rectOfInterest는 0.0~1.0 비율이며, 좌표계가 회전되어 있음 (landscape 기준)
            // 화면 중앙의 약 40% 영역으로 설정
            let scanFrame = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)
            output.rectOfInterest = scanFrame
            
            print("📱 QR 스캔 영역 설정: \(scanFrame)")
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.frame = view.layer.bounds
            view.layer.insertSublayer(previewLayer!, at: 0)
            
        } catch {
            showError(message: "카메라 설정 중 오류가 발생했습니다.")
        }
    }
    
    private func setupUI() {
        updateUI()
    }
    
    private func updateUI() {
        // Remove existing hosting controller
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        
        let qrScannerView = QRScannerViewContent(
            cameraPermissionStatus: cameraPermissionStatus,
            onCancelTapped: { [weak self] in
                self?.listener?.didTapCancel()
            },
            onJoinTapped: { [weak self] in
                if let result = self?.scanResult {
                    self?.listener?.didTapJoinBoard(boardId: result.boardId)
                }
            },
            onRequestPermission: { [weak self] in
                self?.requestCameraPermission()
            },
            onOpenSettings: { [weak self] in
                self?.openAppSettings()
            },
            scanResult: scanResult
        )
        
        let newHostingController = UIHostingController(rootView: qrScannerView)
        self.hostingController = newHostingController
        
        addChild(newHostingController)
        view.addSubview(newHostingController.view)
        
        newHostingController.view.backgroundColor = .clear
        newHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newHostingController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            newHostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newHostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newHostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        newHostingController.didMove(toParent: self)
    }
    
    private func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func startScanning() {
        // AVCaptureSession을 백그라운드 스레드에서 실행하여 UI 무응답 방지
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    private func stopScanning() {
        // ⚡️ 동기적으로 즉시 정지 (메모리 해제를 위해)
        captureSession?.stopRunning()
    }
    
    private func cleanupCamera() {
        print("🧹 QRScannerViewController: 간단한 카메라 정리")
        
        // 🚨 CRITICAL: 동기적으로 즉시 delegate 제거 (순환 참조 방지)
        metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
        
        // 즉시 세션 정지
        captureSession?.stopRunning()
        
        print("✅ QRScannerViewController: 카메라 정리 완료")
    }
    
    // MARK: - QRScannerPresentable
    
    func showScanResult(boardId: String, boardName: String) {
        scanResult = (boardId, boardName)
        updateUI()
    }
    
    func showError(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate

extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        // 🚨 스캔 완료 시 즉시 delegate 제거하여 추가 호출 방지
        metadataOutput?.setMetadataObjectsDelegate(nil, queue: nil)
        
        // 스캔 결과를 한 번만 처리하도록
        stopScanning()
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        // weak self로 순환 참조 방지
        DispatchQueue.main.async { [weak self] in
            self?.listener?.didScanQRCode(content: stringValue)
        }
    }
}

// MARK: - SwiftUI Content

struct QRScannerViewContent: View {
    let cameraPermissionStatus: AVAuthorizationStatus
    let onCancelTapped: () -> Void
    let onJoinTapped: () -> Void
    let onRequestPermission: () -> Void
    let onOpenSettings: () -> Void
    let scanResult: (boardId: String, boardName: String)?
    @State private var animateFrame = false
    
    var body: some View {
        ZStack {
            // Background color based on permission status
            Color.black.opacity(cameraPermissionStatus == .authorized ? 0.1 : 0.9)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: onCancelTapped) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                            Text("취소")
                        }
                        .foregroundColor(.white)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Content based on camera permission status
                switch cameraPermissionStatus {
                case .notDetermined:
                    requestCameraPermissionView
                case .denied, .restricted:
                    cameraPermissionDeniedView
                case .authorized:
                    authorizedCameraView
                @unknown default:
                    cameraPermissionDeniedView
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Camera Permission Views
    
    private var requestCameraPermissionView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("카메라 권한이 필요합니다")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("QR 코드를 스캔하기 위해\n카메라 접근 권한을 허용해주세요.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: onRequestPermission) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("카메라 권한 요청")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var cameraPermissionDeniedView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "camera.fill.badge.xmark")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                VStack(spacing: 8) {
                    Text("카메라 권한이 거부되었습니다")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("QR 코드를 스캔하려면\n설정에서 카메라 권한을 허용해주세요.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: onOpenSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("설정으로 이동")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var authorizedCameraView: some View {
        VStack(spacing: 24) {
            if let result = scanResult {
                // Scan Result View
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("보드를 찾았습니다!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 4) {
                            Text("보드 이름")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(result.boardName)
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Button(action: onJoinTapped) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("게시판 참여하기")
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.green, Color.mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .scaleEffect(animateFrame ? 1.02 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: animateFrame
                    )
                }
                .padding(.horizontal, 20)
                .transition(.scale.combined(with: .opacity))
            } else {
                // Scanning Guide View with transparent background for camera
                ZStack {
                    // Semi-transparent overlay with scan area cutout
                    Rectangle()
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .frame(width: 250, height: 250)
                                .blendMode(.destinationOut)
                        )
                        .compositingGroup()
                        .ignoresSafeArea()
                    
                    VStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Text("QR 코드 스캔")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("게시판 QR 코드를 프레임 안에 맞춰주세요")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        
                        // Animated Scan Frame
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 3)
                                .frame(width: 250, height: 250)
                            
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.green, Color.cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .frame(
                                    width: animateFrame ? 240 : 220,
                                    height: animateFrame ? 240 : 220
                                )
                                .scaleEffect(animateFrame ? 1.02 : 0.98)
                                .animation(
                                    .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                    value: animateFrame
                                )
                            
                            // Corner indicators
                            ForEach(0..<4, id: \.self) { corner in
                                CornerIndicator()
                                    .rotationEffect(.degrees(Double(corner * 90)))
                            }
                        }
                        .onAppear {
                            animateFrame = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Corner Indicator

struct CornerIndicator: View {
    var body: some View {
        VStack {
            HStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 20, height: 3)
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 100, height: 3)
            }
            Rectangle()
                .fill(Color.white)
                .frame(width: 3, height: 20)
            Spacer()
        }
        .frame(width: 125, height: 125)
    }
}