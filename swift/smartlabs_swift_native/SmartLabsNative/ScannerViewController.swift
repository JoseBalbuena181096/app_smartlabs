//
//  ScannerViewController.swift
//  SmartLabsNative
//
//  Created by SmartLabs Team
//  Copyright © 2024 SmartLabs. All rights reserved.
//

import UIKit
import AVFoundation
import Foundation

class ScannerViewController: UIViewController {
    
    // MARK: - Properties
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var isProcessing = false
    private var isToolsMode = false // false = equipos, true = herramientas
    private var lastScannedCode: String?
    private var lastScanTime: Date?
    
    // MARK: - UI Elements
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        return view
    }()
    
    private let userInfoLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    private let modeSwitch: UISwitch = {
        let switchControl = UISwitch()
        switchControl.onTintColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        return switchControl
    }()
    
    private let equiposLabel: UILabel = {
        let label = UILabel()
        label.text = "Herramientas"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        return label
    }()
    
    private let herramientasLabel: UILabel = {
        let label = UILabel()
        label.text = "Equipos"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        return label
    }()
    
    private let scannerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private let scanAreaView: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0).cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 12
        view.backgroundColor = .clear
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Apunta la cámara hacia el código QR"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
        setupUserInfo()
        requestCameraPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startScanning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopScanning()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        title = "SmartLabs Scanner"
        
        // Configurar navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Salir",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        
        // Agregar subvistas
        [headerView, scannerContainerView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [userInfoLabel, equiposLabel, modeSwitch, herramientasLabel].forEach {
            headerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        [overlayView, scanAreaView, instructionLabel].forEach {
            scannerContainerView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header View
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 120),
            
            // User Info Label
            userInfoLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 16),
            userInfoLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            userInfoLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            
            // Mode Controls
            equiposLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            equiposLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            modeSwitch.leadingAnchor.constraint(equalTo: equiposLabel.trailingAnchor, constant: 16),
            modeSwitch.centerYAnchor.constraint(equalTo: equiposLabel.centerYAnchor),
            
            herramientasLabel.leadingAnchor.constraint(equalTo: modeSwitch.trailingAnchor, constant: 16),
            herramientasLabel.centerYAnchor.constraint(equalTo: equiposLabel.centerYAnchor),
            
            // Scanner Container
            scannerContainerView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            scannerContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            scannerContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            scannerContainerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            // Overlay View
            overlayView.topAnchor.constraint(equalTo: scannerContainerView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: scannerContainerView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: scannerContainerView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: scannerContainerView.bottomAnchor),
            
            // Scan Area
            scanAreaView.centerXAnchor.constraint(equalTo: scannerContainerView.centerXAnchor),
            scanAreaView.centerYAnchor.constraint(equalTo: scannerContainerView.centerYAnchor),
            scanAreaView.widthAnchor.constraint(equalToConstant: 250),
            scanAreaView.heightAnchor.constraint(equalToConstant: 250),
            
            // Instruction Label
            instructionLabel.topAnchor.constraint(equalTo: scanAreaView.bottomAnchor, constant: 24),
            instructionLabel.leadingAnchor.constraint(equalTo: scannerContainerView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: scannerContainerView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        modeSwitch.addTarget(self, action: #selector(modeSwitchChanged), for: .valueChanged)
    }
    
    private func setupUserInfo() {
        guard let user = UserManager.shared.currentUser else { return }
        
        userInfoLabel.text = "Bienvenido, \(user.name)\nCorreo: \(user.email)\nMatrícula: \(user.registration)"
        updateModeLabels()
    }
    
    private func updateModeLabels() {
        let azulTec = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        
        if isToolsMode {
            equiposLabel.textColor = .systemGray
            equiposLabel.font = UIFont.systemFont(ofSize: 16)
            herramientasLabel.textColor = azulTec
            herramientasLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        } else {
            equiposLabel.textColor = azulTec
            equiposLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            herramientasLabel.textColor = .systemGray
            herramientasLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }
    
    // MARK: - Camera Setup
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showCameraPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            showCameraPermissionAlert()
        @unknown default:
            break
        }
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            showAlert(title: "Error", message: "No se pudo acceder a la cámara")
            return
        }
        
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            showAlert(title: "Error", message: "Error al configurar la cámara")
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            showAlert(title: "Error", message: "No se pudo configurar la entrada de video")
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            showAlert(title: "Error", message: "No se pudo configurar la salida de metadatos")
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = scannerContainerView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        scannerContainerView.layer.insertSublayer(previewLayer, at: 0)
        
        // Crear máscara para el área de escaneo
        createScanAreaMask()
    }
    
    private func createScanAreaMask() {
        let maskLayer = CAShapeLayer()
        let path = UIBezierPath(rect: overlayView.bounds)
        
        // Crear agujero en el centro
        let scanRect = CGRect(
            x: (overlayView.bounds.width - 250) / 2,
            y: (overlayView.bounds.height - 250) / 2,
            width: 250,
            height: 250
        )
        
        let scanPath = UIBezierPath(roundedRect: scanRect, cornerRadius: 12)
        path.append(scanPath.reversing())
        
        maskLayer.path = path.cgPath
        overlayView.layer.mask = maskLayer
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let previewLayer = previewLayer {
            previewLayer.frame = scannerContainerView.bounds
            createScanAreaMask()
        }
    }
    
    private func startScanning() {
        if captureSession?.isRunning == false {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.startRunning()
            }
        }
    }
    
    private func stopScanning() {
        if captureSession?.isRunning == true {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession?.stopRunning()
            }
        }
    }
    
    // MARK: - Actions
    @objc private func modeSwitchChanged() {
        isToolsMode = modeSwitch.isOn
        updateModeLabels()
        print("Switch cambiado - isToolsMode: \(isToolsMode), switch.isOn: \(modeSwitch.isOn)")
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(
            title: "Cerrar Sesión",
            message: "¿Estás seguro de que quieres cerrar sesión?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Cerrar Sesión", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        
        present(alert, animated: true)
    }
    
    private func performLogout() {
        UserManager.shared.logout()
        
        let loginVC = LoginViewController()
        let navController = UINavigationController(rootViewController: loginVC)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - QR Processing
    private func processQRCode(_ code: String) {
        // Evitar procesamiento duplicado
        let now = Date()
        if let lastTime = lastScanTime, let lastCode = lastScannedCode,
           lastCode == code && now.timeIntervalSince(lastTime) < 2.0 {
            return
        }
        
        lastScannedCode = code
        lastScanTime = now
        isProcessing = true
        
        print("QR procesado: \(code), isToolsMode: \(isToolsMode)")
        
        guard let user = UserManager.shared.currentUser else {
            showAlert(title: "Error", message: "Usuario no encontrado")
            isProcessing = false
            return
        }
        
        if isToolsMode {
            print("Ejecutando modo HERRAMIENTAS")
            handleToolsMode(user: user, qrCode: code)
        } else {
            print("Ejecutando modo EQUIPOS")
            handleEquipmentMode(user: user, qrCode: code)
        }
    }
    
    private func handleToolsMode(user: User, qrCode: String) {
        print("Iniciando handleToolsMode para QR: \(qrCode)")
        Task {
            do {
                print("Llamando a getLoanStatus()...")
                let loanStatus = try await APIService.shared.getLoanStatus()
                print("Respuesta de getLoanStatus: \(loanStatus)")
                
                DispatchQueue.main.async {
                    if loanStatus.success {
                        let loanData = loanStatus.data
                        let sessionActive = loanData.sessionActive
                        let action = sessionActive ? 0 : 1
                        let userName = loanData.user ?? "Usuario"
                        
                        print("Estado session_active: \(sessionActive)")
                        print("Acción determinada: \(action) (\(action == 0 ? "Devolución" : "Préstamo"))")
                        print("Mostrando diálogo de confirmación para: \(action == 0 ? "devolver" : "prestar")")
                        
                        self.showToolsConfirmationDialog(
                            qrCode: qrCode,
                            sessionActive: sessionActive,
                            action: action,
                            userName: userName,
                            user: user
                        )
                    } else {
                        print("Error en respuesta de getLoanStatus: success = false")
                        self.showAlert(title: "Error", message: "Error al obtener estado de préstamo")
                        self.resetScanner()
                    }
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error en handleToolsMode: \(error)")
                    print("Tipo de error: \(type(of: error))")
                    self.showAlert(title: "Error", message: "Error de conexión: Verifique que esté conectado a la red local")
                    self.resetScanner()
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func handleEquipmentMode(user: User, qrCode: String) {
        Task {
            do {
                let deviceStatus = try await APIService.shared.getDeviceStatus(qrCode)
                
                DispatchQueue.main.async {
                    if deviceStatus.success, let deviceData = deviceStatus.data {
                        let currentState = deviceData.state
                        let newAction = currentState ? 0 : 1
                        let deviceAlias = deviceData.device_alias
                        
                        print("Estado actual del dispositivo \(qrCode): \(currentState ? "Encendido" : "Apagado"), acción a realizar: \(newAction == 1 ? "Encender" : "Apagar")")
                        
                        self.showEquipmentConfirmationDialog(
                            qrCode: qrCode,
                            currentState: currentState,
                            action: newAction,
                            deviceAlias: deviceAlias,
                            user: user
                        )
                    } else {
                        let errorMessage = deviceStatus.message ?? "Error al obtener estado del dispositivo"
                        self.showAlert(title: "Error", message: errorMessage)
                        self.resetScanner()
                    }
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error en handleEquipmentMode: \(error)")
                    self.showAlert(title: "Error", message: "Error de conexión: Verifique que esté conectado a la red local")
                    self.resetScanner()
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Confirmation Dialogs
    private func showToolsConfirmationDialog(qrCode: String, sessionActive: Bool, action: Int, userName: String, user: User) {
        let actionText = action == 1 ? "Tomar Herramienta" : "Devolver Herramienta"
        let message = sessionActive ? "Sesión activa para: \(userName)" : "No hay sesión activa"
        
        let alert = UIAlertController(
            title: actionText,
            message: "\(message)\n\n¿Deseas \(actionText.lowercased())?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.resetScanner()
        })
        
        alert.addAction(UIAlertAction(title: "Confirmar", style: .default) { [weak self] _ in
            self?.executeToolsAction(user: user, qrCode: qrCode, action: action)
        })
        
        present(alert, animated: true)
    }
    
    private func showEquipmentConfirmationDialog(qrCode: String, currentState: Bool, action: Int, deviceAlias: String, user: User) {
        let actionText = action == 1 ? "Encender Equipo" : "Apagar Equipo"
        let currentStateText = currentState ? "Encendido" : "Apagado"
        
        let alert = UIAlertController(
            title: actionText,
            message: "Dispositivo: \(deviceAlias)\nEstado actual: \(currentStateText)\n\n¿Deseas \(actionText.lowercased())?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { [weak self] _ in
            self?.resetScanner()
        })
        
        alert.addAction(UIAlertAction(title: "Confirmar", style: .default) { [weak self] _ in
            self?.executeEquipmentAction(user: user, qrCode: qrCode, action: action, deviceAlias: deviceAlias)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - API Actions
    private func executeToolsAction(user: User, qrCode: String, action: Int) {
        Task {
            do {
                print("Ejecutando controlLoan - QR: \(qrCode), Action: \(action), User: \(user.registration)")
                
                let controlResponse = try await APIService.shared.controlLoan(
                    user.registration,
                    deviceSerie: qrCode,
                    action: action
                )
                
                print("Respuesta del servidor: \(controlResponse)")
                
                DispatchQueue.main.async {
                    if controlResponse.success {
                        let actionText = action == 1 ? "Préstamo realizado" : "Devolución realizada"
                        let userName = user.name
                        
                        print("Operación exitosa: \(actionText)")
                        
                        self.showSuccessAlert(
                            title: "Control de Herramienta",
                            message: "\(actionText)\nUsuario: \(userName)"
                        )
                    } else {
                        print("Error en operación: \(controlResponse.message ?? "Error desconocido")")
                        self.showAlert(title: "Error", message: controlResponse.message ?? "Error al controlar préstamo")
                    }
                    self.resetScanner()
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error en executeToolsAction: \(error)")
                    self.showAlert(title: "Error", message: "Error de conexión: Verifique que esté conectado a la red local")
                    self.resetScanner()
                }
            }
        }
    }
    
    private func executeEquipmentAction(user: User, qrCode: String, action: Int, deviceAlias: String) {
        Task {
            do {
                let controlResponse = try await APIService.shared.controlDevice(
                    user.registration,
                    deviceSerie: qrCode,
                    action: action
                )
                
                DispatchQueue.main.async {
                    if controlResponse.success {
                        let actionText = action == 1 ? "Equipo encendido" : "Equipo apagado"
                        let newStatus = action == 1 ? "Encendido" : "Apagado"
                        
                        print("Operación exitosa: \(actionText)")
                        
                        // Usar información de la respuesta si está disponible
                        let deviceName = controlResponse.data?.device_name ?? controlResponse.data?.device ?? deviceAlias
                        let userName = controlResponse.data?.user?.name ?? user.name
                        
                        self.showSuccessAlert(
                            title: "Control de Equipo",
                            message: "Dispositivo: \(deviceName)\nUsuario: \(userName)\nEstado: \(newStatus)"
                        )
                    } else {
                        let errorMessage = controlResponse.message ?? controlResponse.error ?? "Error al controlar equipo"
                        print("Error en operación: \(errorMessage)")
                        self.showAlert(title: "Error", message: errorMessage)
                    }
                    self.resetScanner()
                }
            } catch {
                DispatchQueue.main.async {
                    print("Error en executeEquipmentAction: \(error)")
                    self.showAlert(title: "Error", message: "Error de conexión: Verifique que esté conectado a la red local")
                    self.resetScanner()
                }
            }
        }
    }
    
    private func resetScanner() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isProcessing = false
            self?.lastScannedCode = nil
            self?.lastScanTime = nil
        }
    }
    
    // MARK: - Helper Methods
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showCameraPermissionAlert() {
        let alert = UIAlertController(
            title: "Permiso de Cámara",
            message: "Esta aplicación necesita acceso a la cámara para escanear códigos QR. Por favor, habilita el permiso en Configuración.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Configuración", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        present(alert, animated: true)
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        guard !isProcessing,
              let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        // Vibración háptica
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        processQRCode(stringValue)
    }
}
