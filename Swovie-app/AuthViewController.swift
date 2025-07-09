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
        view.backgroundColor = .systemBackground
        
        let stackView = UIStackView(arrangedSubviews: [
            segmentedControl,
            emailTextField,
            passwordTextField,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
