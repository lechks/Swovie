import UIKit

class MatchViewController: UIViewController {
    
    private var users: [User] = []
    private let knownUsersDB: [User] = [
        User(id: "123", name: "Алиса", avatarName: .systemPink),
        User(id: "1234", name: "Боб", avatarName: .systemBlue),
        User(id: "12345", name: "Чарли", avatarName: .systemGreen)
    ]
    
    private let stackView = UIStackView()
    private let matchButton = UIButton(type: .system)
    private let addIdButton = UIButton(type: .system)
    private var idTextFields: [UITextField] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Добавь пользователей"
        
        setupStackView()
        setupAddIdButton()
        setupMatchButton()
    }
    
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupAddIdButton() {
        addIdButton.setTitle("➕ Добавить ID", for: .normal)
        addIdButton.translatesAutoresizingMaskIntoConstraints = false
        addIdButton.addTarget(self, action: #selector(addIdField), for: .touchUpInside)
        view.addSubview(addIdButton)
        
        NSLayoutConstraint.activate([
            addIdButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            addIdButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    private func setupMatchButton() {
        matchButton.setTitle("🚀 Начать мэтчинг", for: .normal)
        matchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        matchButton.translatesAutoresizingMaskIntoConstraints = false
        matchButton.addTarget(self, action: #selector(startMatching), for: .touchUpInside)
        view.addSubview(matchButton)
        
        NSLayoutConstraint.activate([
            matchButton.topAnchor.constraint(equalTo: addIdButton.bottomAnchor, constant: 20),
            matchButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    @objc private func addIdField() {
        let textField = UITextField()
        textField.placeholder = "Введите ID пользователя"
        textField.borderStyle = .roundedRect
        idTextFields.append(textField)
        stackView.addArrangedSubview(textField)
    }
    
    @objc private func startMatching() {
        users.removeAll()
                for textField in idTextFields {
                    guard let id = textField.text, !id.isEmpty else { continue }
                    if let user = knownUsersDB.first(where: { $0.id == id }) {
                        users.append(user)
                    }
                }
                
                if users.isEmpty {
                    let alert = UIAlertController(title: "Ошибка", message: "Не найдено пользователей с такими ID", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ок", style: .default))
                    present(alert, animated: true)
                } else {
                    showSwipeViewController()
                }
            }
            
    private func showSwipeViewController() {
        let swipeVC = SwipeViewController()
        navigationController?.pushViewController(swipeVC, animated: true)
    }
}

