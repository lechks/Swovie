//
//  LoginViewController.swift
//  swovie
//
//  Created by Екактерина Максаева on 05.07.2025.
//

import Foundation
import UIKit
import FirebaseAuth

class MainViewController: UIViewController {
    
    private lazy var welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Добро пожаловать в Swovie!"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = Auth.auth().currentUser?.email
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    private lazy var logoutButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Выйти", for: .normal)
        btn.backgroundColor = .systemRed
        btn.tintColor = .white
        btn.layer.cornerRadius = 8
        btn.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        return btn
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Главная"
        navigationItem.hidesBackButton = true
        
        view.addSubview(welcomeLabel)
        view.addSubview(emailLabel)
        view.addSubview(logoutButton)
    }
    
    private func setupConstraints() {
        [welcomeLabel, emailLabel, logoutButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            welcomeLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            emailLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 16),
            emailLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emailLabel.widthAnchor.constraint(equalTo: welcomeLabel.widthAnchor),
            
            logoutButton.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 40),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoutButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.6),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func handleLogout() {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch {
            showAlert(title: "Ошибка", message: error.localizedDescription)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
