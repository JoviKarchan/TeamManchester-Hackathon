import SwiftUI
import AVFoundation
import UIKit


struct CustomCameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onCapture: (UIImage) -> Void
    var onCancel: (() -> Void)?

    func makeUIViewController(context: Context) -> CustomCameraViewController {
        let vc = CustomCameraViewController()
        vc.onCapture = { image in
            isPresented = false
            onCapture(image)
        }
        vc.onCancel = {
            isPresented = false
            onCancel?()
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: CustomCameraViewController, context: Context) {}
}


final class CustomCameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    var onCapture: ((UIImage) -> Void)?
    var onCancel: (() -> Void)?

    private var captureSession: AVCaptureSession?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var flashMode: AVCaptureDevice.FlashMode = .auto

    private let sessionQueue = DispatchQueue(label: "camera.session")

    /// Prevents multiple captures and avoids broken state when session isn't ready or was interrupted.
    private var isCapturing = false

    /// When true, session is being or has been torn down; delegate and UI must not touch session/callbacks.
    private var isTornDown = false

    private var sessionInterruptedObserver: NSObjectProtocol?
    private var sessionInterruptionEndedObserver: NSObjectProtocol?

    private let previewView = UIView()

    
    private var navBar: UIView!
    private var titleLabel: UILabel!
    private var bottomPanel: UIView!
    private var galleryThumb: UIImageView!
    private var zoomLabel: UILabel!
    private var shutterButton: UIButton!
    private var flipButton: UIButton!
    private var flashButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateViewBackground()

       
        previewView.translatesAutoresizingMaskIntoConstraints = false
        previewView.isUserInteractionEnabled = false
        view.addSubview(previewView)

        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

   
        setupOverlay()
        checkPermissionAndSetupCamera()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = previewView.bounds
        updatePreviewOrientation()
        updatePreviewMirroring()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateOverlayColors()
        addSessionInterruptionObservers()
        if captureSession == nil {
            isTornDown = false
            // Brief delay so camera daemon can release device (reduces Fig -17281 / freeze)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                self?.checkPermissionAndSetupCamera()
            }
        } else {
            sessionQueue.async { [weak self] in
                guard let self else { return }
                if self.captureSession?.isRunning == false {
                    self.captureSession?.startRunning()
                }
                DispatchQueue.main.async { [weak self] in
                    self?.setShutterEnabledIfReady()
                }
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isTornDown = true
        removeSessionInterruptionObservers()
        tearDownCaptureSession()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateViewBackground()
            updateOverlayColors()
        }
    }


    private func updateViewBackground() {
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .systemBackground
    }

    private func updateOverlayColors() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        navBar?.backgroundColor = isDark ? .black : .systemBackground
        bottomPanel?.backgroundColor = isDark ? .black : .systemBackground
        titleLabel?.textColor = isDark ? .white : .label
        zoomLabel?.textColor = isDark ? .white : .label
        flipButton?.tintColor = isDark ? .white : .label
        flashButton?.tintColor = isDark ? .white : .label
        shutterButton?.layer.borderColor = (isDark ? UIColor.white : UIColor.label).cgColor
        shutterInnerView?.backgroundColor = isDark ? .white : .label
        galleryThumb?.backgroundColor = (isDark ? UIColor.white : UIColor.label).withAlphaComponent(0.15)
    }

    private var shutterInnerView: UIView? { shutterButton?.subviews.first }

    private func setupOverlay() {
        let navHeight: CGFloat = 56
        navBar = UIView()
        navBar.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .systemBackground
        navBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navBar)

        titleLabel = UILabel()
        titleLabel.text = "Photo search"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = traitCollection.userInterfaceStyle == .dark ? .white : .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        navBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            navBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navBar.heightAnchor.constraint(equalToConstant: navHeight),
            titleLabel.centerXAnchor.constraint(equalTo: navBar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: navBar.centerYAnchor),
        ])
        
        let glassView = CameraGlassOverlayView(onBack: { [weak self] in self?.onCancel?() }, bottomPanelHeight: 158)
        let hosting = UIHostingController(rootView: glassView)
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(hosting)
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        hosting.didMove(toParent: self)

        bottomPanel = UIView()
        bottomPanel.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .systemBackground
        bottomPanel.layer.cornerRadius = 24
        bottomPanel.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomPanel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.isUserInteractionEnabled = true
        view.addSubview(bottomPanel)

        galleryThumb = UIImageView()
        galleryThumb.backgroundColor = (traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.label).withAlphaComponent(0.15)
        galleryThumb.layer.cornerRadius = 8
        galleryThumb.clipsToBounds = true
        galleryThumb.contentMode = .scaleAspectFill
        galleryThumb.translatesAutoresizingMaskIntoConstraints = false
        galleryThumb.isUserInteractionEnabled = true
        bottomPanel.addSubview(galleryThumb)

        zoomLabel = UILabel()
        zoomLabel.text = "1.0x"
        zoomLabel.font = .systemFont(ofSize: 15, weight: .medium)
        zoomLabel.textColor = .white
        zoomLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomPanel.addSubview(zoomLabel)

        shutterButton = UIButton(type: .custom)
        shutterButton.backgroundColor = .clear
        shutterButton.layer.cornerRadius = 36
        shutterButton.layer.borderWidth = 4
        shutterButton.layer.borderColor = UIColor.white.cgColor
        shutterButton.translatesAutoresizingMaskIntoConstraints = false
        shutterButton.isUserInteractionEnabled = true
        shutterButton.isEnabled = false // enabled only when session is ready (avoids silent no-op taps)
        shutterButton.addTarget(self, action: #selector(shutterTapped), for: .touchUpInside)
        bottomPanel.addSubview(shutterButton)

        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.layer.cornerRadius = 28
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        shutterButton.addSubview(innerCircle)

        flipButton = UIButton(type: .system)
        flipButton.setImage(UIImage(systemName: "camera.rotate"), for: .normal)
        flipButton.tintColor = .white
        flipButton.translatesAutoresizingMaskIntoConstraints = false
        flipButton.isUserInteractionEnabled = true
        flipButton.addTarget(self, action: #selector(flipTapped), for: .touchUpInside)
        bottomPanel.addSubview(flipButton)

        flashButton = UIButton(type: .system)
        flashButton.setImage(UIImage(systemName: "bolt.badge.automatic"), for: .normal)
        flashButton.tintColor = .white
        flashButton.translatesAutoresizingMaskIntoConstraints = false
        flashButton.isUserInteractionEnabled = true
        flashButton.addTarget(self, action: #selector(flashTapped), for: .touchUpInside)
        bottomPanel.addSubview(flashButton)

        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: shutterButton.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 56),
            innerCircle.heightAnchor.constraint(equalToConstant: 56),
        ])

        NSLayoutConstraint.activate([
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPanel.heightAnchor.constraint(equalToConstant: 134),

            galleryThumb.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 24),
            galleryThumb.centerYAnchor.constraint(equalTo: bottomPanel.centerYAnchor, constant: -17),
            galleryThumb.widthAnchor.constraint(equalToConstant: 44),
            galleryThumb.heightAnchor.constraint(equalToConstant: 44),

            zoomLabel.leadingAnchor.constraint(equalTo: galleryThumb.trailingAnchor, constant: 16),
            zoomLabel.centerYAnchor.constraint(equalTo: galleryThumb.centerYAnchor),

            shutterButton.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            shutterButton.centerYAnchor.constraint(equalTo: galleryThumb.centerYAnchor),
            shutterButton.widthAnchor.constraint(equalToConstant: 72),
            shutterButton.heightAnchor.constraint(equalToConstant: 72),

            flipButton.trailingAnchor.constraint(equalTo: flashButton.leadingAnchor, constant: -20),
            flipButton.centerYAnchor.constraint(equalTo: galleryThumb.centerYAnchor),
            flipButton.widthAnchor.constraint(equalToConstant: 44),
            flipButton.heightAnchor.constraint(equalToConstant: 44),

            flashButton.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -24),
            flashButton.centerYAnchor.constraint(equalTo: galleryThumb.centerYAnchor),
            flashButton.widthAnchor.constraint(equalToConstant: 44),
            flashButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func checkPermissionAndSetupCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        self?.showCameraDenied()
                    }
                }
            }
        default:
            showCameraDenied()
        }
    }

    private func showCameraDenied() {
        let alert = UIAlertController(
            title: "Camera Access",
            message: "Findly needs camera access to search by photo. Enable it in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.onCancel?()
        })
        present(alert, animated: true)
    }


    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard !self.isTornDown else { return }

            let session = AVCaptureSession()
            session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else {
                DispatchQueue.main.async { self.showCameraDenied() }
                return
            }

            let photoOut = AVCapturePhotoOutput()

            session.beginConfiguration()
            if session.canAddInput(input) { session.addInput(input) }
            if session.canAddOutput(photoOut) { session.addOutput(photoOut) }
            session.commitConfiguration()

            self.captureSession = session
            self.photoOutput = photoOut

            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: session)
                preview.videoGravity = .resizeAspectFill
                preview.frame = self.previewView.bounds

                
                self.previewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
                self.previewView.layer.addSublayer(preview)
                self.previewLayer = preview

                self.updatePreviewOrientation()
                self.updatePreviewMirroring()
                self.updateFlashAvailabilityUI()
            }

            session.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.setShutterEnabledIfReady()
            }
        }
    }

    /// Call on main only. Enables shutter only when session is running and we're not already capturing.
    private func setShutterEnabledIfReady() {
        let ready = photoOutput != nil && (captureSession?.isRunning == true) && !isCapturing
        shutterButton?.isEnabled = ready
        shutterButton?.alpha = ready ? 1.0 : 0.5
    }

    private func addSessionInterruptionObservers() {
        sessionInterruptedObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureSession.wasInterruptedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, note.object as? AVCaptureSession === self.captureSession else { return }
            self.setShutterEnabledIfReady()
        }
        sessionInterruptionEndedObserver = NotificationCenter.default.addObserver(
            forName: AVCaptureSession.interruptionEndedNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, note.object as? AVCaptureSession === self.captureSession else { return }
            self.sessionQueue.async { [weak self] in
                guard let self, self.captureSession?.isRunning == false else { return }
                self.captureSession?.startRunning()
                DispatchQueue.main.async { self.setShutterEnabledIfReady() }
            }
        }
    }

    private func removeSessionInterruptionObservers() {
        if let o = sessionInterruptedObserver {
            NotificationCenter.default.removeObserver(o)
            sessionInterruptedObserver = nil
        }
        if let o = sessionInterruptionEndedObserver {
            NotificationCenter.default.removeObserver(o)
            sessionInterruptionEndedObserver = nil
        }
    }

    /// Fully tears down the capture session so the camera device is released. Prevents "device in use"
    /// and Fig/capture daemon errors (-17281) when the camera is shown again.
    private func tearDownCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            guard let session = self.captureSession else {
                DispatchQueue.main.async { [weak self] in self?.setShutterEnabledIfReady() }
                return
            }
            if session.isRunning {
                session.stopRunning()
            }
            session.beginConfiguration()
            for input in session.inputs {
                session.removeInput(input)
            }
            for output in session.outputs {
                session.removeOutput(output)
            }
            session.commitConfiguration()
            self.captureSession = nil
            self.photoOutput = nil
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.previewLayer?.session = nil
                self.previewLayer?.removeFromSuperlayer()
                self.previewLayer = nil
                self.setShutterEnabledIfReady()
            }
        }
    }


    private func updatePreviewOrientation() {
        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else { return }
        connection.videoOrientation = .portrait
    }

  
    private func updatePreviewMirroring() {
        guard let connection = previewLayer?.connection, connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = (currentCameraPosition == .front)
    }

    private func updateFlashAvailabilityUI() {
        let hasFlash = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition)?.hasFlash ?? false
        flashButton.isEnabled = hasFlash
        flashButton.alpha = hasFlash ? 1.0 : 0.35

        if !hasFlash {
            flashMode = .off
            flashButton.setImage(UIImage(systemName: "bolt.slash"), for: .normal)
        } else {
            updateFlashIcon()
        }
    }

    private func updateFlashIcon() {
        let name: String
        switch flashMode {
        case .auto: name = "bolt.badge.automatic"
        case .on: name = "bolt.fill"
        case .off: name = "bolt.slash"
        @unknown default: name = "bolt"
        }
        flashButton.setImage(UIImage(systemName: name), for: .normal)
    }


    @objc private func shutterTapped() {
        guard let photoOutput,
              captureSession?.isRunning == true,
              !isCapturing else { return }
        isCapturing = true
        setShutterEnabledIfReady()

        let settings = AVCapturePhotoSettings()
        let hasFlash = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition)?.hasFlash ?? false
        settings.flashMode = hasFlash ? flashMode : .off

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @objc private func flipTapped() {
        sessionQueue.async { [weak self] in
            guard let self, let session = self.captureSession else { return }

            let newPosition: AVCaptureDevice.Position = (self.currentCameraPosition == .back) ? .front : .back

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let input = try? AVCaptureDeviceInput(device: device) else { return }

            session.beginConfiguration()

            for oldInput in session.inputs {
                if let devInput = oldInput as? AVCaptureDeviceInput, devInput.device.hasMediaType(.video) {
                    session.removeInput(oldInput)
                }
            }

            if session.canAddInput(input) {
                session.addInput(input)
                self.currentCameraPosition = newPosition
            }

            session.commitConfiguration()

            DispatchQueue.main.async {
                self.updatePreviewOrientation()
                self.updatePreviewMirroring()
                self.updateFlashAvailabilityUI()
            }
        }
    }

    @objc private func flashTapped() {
        guard flashButton.isEnabled else { return }

        switch flashMode {
        case .auto: flashMode = .on
        case .on: flashMode = .off
        case .off: flashMode = .auto
        @unknown default: flashMode = .auto
        }
        updateFlashIcon()
    }


    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isTornDown else { return }
            self.isCapturing = false
            self.setShutterEnabledIfReady()
        }
        if let error {
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.isTornDown else { return }
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else { return }

        let finalImage = (currentCameraPosition == .front) ? mirrorImage(image) : image

        DispatchQueue.main.async { [weak self] in
            guard let self, !self.isTornDown else { return }
            self.onCapture?(finalImage)
        }
    }

    private func mirrorImage(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        ctx.translateBy(x: image.size.width, y: 0)
        ctx.scaleBy(x: -1.0, y: 1.0)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let mirrored = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mirrored ?? image
    }
}
