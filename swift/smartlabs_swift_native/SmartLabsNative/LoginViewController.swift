//
//  LoginViewController.swift
//  SmartLabsNative
//
//  Created by SmartLabs Team
//  Copyright © 2024 SmartLabs. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    
    // MARK: - UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "SmartLabs"
        label.font = UIFont.boldSystemFont(ofSize: 32)
        label.textColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ingresa tu matrícula para acceder"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private let registrationTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Matrícula"
        textField.borderStyle = .roundedRect
        textField.autocapitalizationType = .allCharacters
        textField.autocorrectionType = .no
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.backgroundColor = .systemBackground
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        textField.leftViewMode = .always
        
        // Agregar icono de persona
        let iconImageView = UIImageView(image: UIImage(systemName: "person"))
        iconImageView.tintColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.frame = CGRect(x: 12, y: 12, width: 20, height: 20)
        textField.leftView?.addSubview(iconImageView)
        
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Acceder", for: .normal)
        button.backgroundColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor(red: 0.0, green: 0.318, blue: 0.729, alpha: 0.3).cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 1.0
        return button
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground
        
        // Configurar logo placeholder
        logoImageView.image = createLogoPlaceholder()
        
        // Agregar subvistas
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [logoImageView, titleLabel, subtitleLabel, registrationTextField, loginButton, loadingIndicator].forEach {
            contentView.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Logo
            logoImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 60),
            logoImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImageView.widthAnchor.constraint(equalToConstant: 120),
            logoImageView.heightAnchor.constraint(equalToConstant: 120),
            
            // Title
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            
            // Registration TextField
            registrationTextField.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            registrationTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            registrationTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            registrationTextField.heightAnchor.constraint(equalToConstant: 50),
            
            // Login Button
            loginButton.topAnchor.constraint(equalTo: registrationTextField.bottomAnchor, constant: 32),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Loading Indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor),
            
            // Content View Bottom
            contentView.bottomAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 60)
        ])
    }
    
    private func setupActions() {
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        // Agregar target para Return key
        registrationTextField.addTarget(self, action: #selector(registrationTextFieldReturn), for: .editingDidEndOnExit)
    }
    
    private func createLogoPlaceholder() -> UIImage? {
        let size = CGSize(width: 120, height: 120)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemBlue.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        // Agregar texto "SL"
        let text = "SL"
        let font = UIFont.boldSystemFont(ofSize: 40)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.white
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Actions
    @objc private func registrationTextFieldReturn() {
        loginButtonTapped()
    }
    
    @objc private func loginButtonTapped() {
        guard let registration = registrationTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), 
              !registration.isEmpty else {
            showAlert(title: "Error", message: "Por favor ingresa tu matrícula")
            return
        }
        
        performLogin(registration: registration)
    }
    
    // MARK: - Login Logic
    private func performLogin(registration: String) {
        setLoadingState(true)
        
        Task {
            do {
                let user = try await APIService.shared.getUserByRegistration(registration)
                
                DispatchQueue.main.async {
                    UserManager.shared.currentUser = user
                    self.navigateToScanner()
                }
            } catch {
                DispatchQueue.main.async {
                    self.setLoadingState(false)
                    let errorMessage = (error as? APIError)?.errorDescription ?? "Error de conexión: Verifique que esté conectado a la red local"
                    self.showAlert(title: "Error de Login", message: errorMessage)
                }
            }
        }
    }
    
    private func setLoadingState(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        registrationTextField.isEnabled = !isLoading
        
        if isLoading {
            loadingIndicator.startAnimating()
            loginButton.setTitle("", for: .normal)
        } else {
            loadingIndicator.stopAnimating()
            loginButton.setTitle("Acceder", for: .normal)
        }
    }
    
    private func navigateToScanner() {
        let scannerVC = ScannerViewController()
        let navController = UINavigationController(rootViewController: scannerVC)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}