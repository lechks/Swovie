//
//  RegistrationViewController.swift
//  swovie
//
//  Created by Екатерина Максаева on 05.07.2025.
//

import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseMessaging

class AuthViewController: UIViewController {
    
    private let segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Вход", "Регистрация"])
        control.selectedSegmentIndex = 0
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.keyboardType = .emailAddress
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Пароль"
        tf.isSecureTextEntry = true
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let actionButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Войти", for: .normal)
        btn.backgroundColor = .systemBlue
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(handleAuth), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    private func setupViews() {
        // Градиентный фон
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [
            AppColors.canvas.cgColor,
            AppColors.slate.withAlphaComponent(0.2).cgColor,
            AppColors.canvas.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Подложка для формы
        let formContainer = UIView()
        formContainer.backgroundColor = AppColors.white
        formContainer.layer.cornerRadius = 24
        formContainer.layer.shadowColor = AppColors.charcoal.cgColor
        formContainer.layer.shadowOpacity = 0.1
        formContainer.layer.shadowOffset = CGSize(width: 0, height: 10)
        formContainer.layer.shadowRadius = 20
        formContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(formContainer)
        
        // Логотип приложения
        let logoImageView = UIImageView(image: UIImage(systemName: "film.fill"))
        logoImageView.tintColor = AppColors.slate
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoImageView)
        
        // Настройка segmented control
        segmentedControl.selectedSegmentTintColor = AppColors.slate
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: AppColors.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .semibold)
        ], for: .selected)
        
        segmentedControl.setTitleTextAttributes([
            .foregroundColor: AppColors.slate,
            .font: UIFont.systemFont(ofSize: 16, weight: .medium)
        ], for: .normal)
        
        // Настройка текстовых полей
        [emailTextField, passwordTextField].forEach {
            $0.backgroundColor = AppColors.canvas
            $0.layer.cornerRadius = 12
            $0.layer.borderWidth = 1
            $0.layer.borderColor = AppColors.slate.withAlphaComponent(0.2).cgColor
            $0.font = UIFont.systemFont(ofSize: 16)
            $0.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: $0.frame.height))
            $0.leftViewMode = .always
        }
        
        // Настройка кнопки
        actionButton.backgroundColor = AppColors.slate
        actionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        actionButton.layer.shadowColor = AppColors.slate.cgColor
        actionButton.layer.shadowOpacity = 0.3
        actionButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        actionButton.layer.shadowRadius = 8
        
        // Стек формы
        let stackView = UIStackView(arrangedSubviews: [
            segmentedControl,
            emailTextField,
            passwordTextField,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        formContainer.addSubview(stackView)
        
        // Подложка (красивый низ экрана)
        let footerDecoration = UIView()
        footerDecoration.backgroundColor = AppColors.slate
        footerDecoration.layer.cornerRadius = 30
        footerDecoration.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        footerDecoration.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(footerDecoration, belowSubview: formContainer)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Логотип
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.bottomAnchor.constraint(equalTo: formContainer.topAnchor, constant: -40),
            logoImageView.widthAnchor.constraint(equalToConstant: 80),
            logoImageView.heightAnchor.constraint(equalToConstant: 60),
            
            // Форма
            formContainer.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            formContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            formContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            // Элементы формы
            stackView.topAnchor.constraint(equalTo: formContainer.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: formContainer.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: formContainer.trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: formContainer.bottomAnchor, constant: -40),
            
            // Высота элементов
            emailTextField.heightAnchor.constraint(equalToConstant: 50),
            passwordTextField.heightAnchor.constraint(equalToConstant: 50),
            actionButton.heightAnchor.constraint(equalToConstant: 56),
            segmentedControl.heightAnchor.constraint(equalToConstant: 40),
            
            // Подложка
            footerDecoration.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            footerDecoration.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footerDecoration.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            footerDecoration.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.15)
        ])
        
        // Анимация появления
        [logoImageView, formContainer].forEach {
            $0.alpha = 0
            $0.transform = CGAffineTransform(translationX: 0, y: 20)
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.1, options: .curveEaseOut, animations: {
            logoImageView.alpha = 1
            logoImageView.transform = .identity
        })
        
        UIView.animate(withDuration: 0.6, delay: 0.3, options: .curveEaseOut, animations: {
            formContainer.alpha = 1
            formContainer.transform = .identity
        })
    }
    
    @objc private func segmentChanged() {
        let title = segmentedControl.selectedSegmentIndex == 0 ? "Войти" : "Зарегистрироваться"
        actionButton.setTitle(title, for: .normal)
    }
    
    @objc private func handleAuth() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Ошибка", message: "Заполните все поля")
            return
        }
        
        if segmentedControl.selectedSegmentIndex == 0 {
            // Вход
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(title: "Ошибка входа", message: error.localizedDescription)
                } else {
                    self?.checkUserProfileExists()
                }
            }
        } else {
            // Регистрация
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                if let error = error {
                    self?.showAlert(title: "Ошибка регистрации", message: error.localizedDescription)
                    return
                }
                
                guard let userId = result?.user.uid else { return }
                
                // Создаем документ пользователя
                let userData: [String: Any] = [
                    "email": email,
                    "name": email.components(separatedBy: "@").first ?? "User",
                    "avatarName": "systemBlue",
                    "createdAt": Timestamp(date: Date())
                ]
                
                Firestore.firestore().collection("users").document(userId).setData(userData) { error in
                    if let error = error {
                        print("Ошибка создания профиля: \(error.localizedDescription)")
                    }
                    self?.showMainScreen()
                }
            }
        }
    }
    
    private func showMainScreen() {
        let mainVC = MainTabBarController()
        navigationController?.setViewControllers([mainVC], animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func checkUserProfileExists() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        Firestore.firestore().collection("users").document(userId).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("Ошибка проверки профиля: \(error.localizedDescription)")
            }
            
            if snapshot?.exists ?? false {
                self?.showMainScreen()
            } else {
                self?.createDefaultProfile()
            }
        }
    }
    
    private func createDefaultProfile() {
        guard let user = Auth.auth().currentUser else { return }
        
        let userData: [String: Any] = [
            "email": user.email ?? "",
            "name": user.email?.components(separatedBy: "@").first ?? "User",
            "avatarName": "systemBlue",
            "createdAt": Timestamp(date: Date())
        ]
        
        Firestore.firestore().collection("users").document(user.uid).setData(userData) { [weak self] error in
            if let error = error {
                print("Ошибка создания профиля: \(error.localizedDescription)")
            }
            self?.showMainScreen()
        }
    }
    
}
