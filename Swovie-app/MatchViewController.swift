import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth

class MatchViewController: UIViewController {
    
    // Элементы UI для вступления в группу
    let joinGroupStackView = UIStackView()
    let groupIdTextField = UITextField()
    let passwordTextField = UITextField()
    let joinButton = UIButton()
    
    // Элементы UI для создания группы
    let createGroupStackView = UIStackView()
    let membersCountTextField = UITextField()
    let createPasswordTextField = UITextField()
    let createButton = UIButton()
    
    // Разделитель
    let orLabel = UILabel()
    
    // Ссылка на базу данных Firebase
    var ref: DatabaseReference!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Управление группой"
        
        ref = Database.database().reference()
        
        setupJoinGroupUI()
        setupCreateGroupUI()
        setupOrLabel()
        setupConstraints()
    }
    
    private func setupJoinGroupUI() {
        joinGroupStackView.axis = .vertical
        joinGroupStackView.spacing = 16
        joinGroupStackView.alignment = .fill
        joinGroupStackView.distribution = .fillEqually
        
        groupIdTextField.placeholder = "ID группы"
        groupIdTextField.borderStyle = .roundedRect
        groupIdTextField.autocapitalizationType = .none
        groupIdTextField.autocorrectionType = .no
        
        passwordTextField.placeholder = "Пароль доступа"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        
        joinButton.setTitle("Вступить в группу", for: .normal)
        joinButton.backgroundColor = .systemBlue
        joinButton.layer.cornerRadius = 8
        joinButton.addTarget(self, action: #selector(joinGroupTapped), for: .touchUpInside)
        
        joinGroupStackView.addArrangedSubview(groupIdTextField)
        joinGroupStackView.addArrangedSubview(passwordTextField)
        joinGroupStackView.addArrangedSubview(joinButton)
        
        view.addSubview(joinGroupStackView)
    }
    
    private func setupCreateGroupUI() {
        createGroupStackView.axis = .vertical
        createGroupStackView.spacing = 16
        createGroupStackView.alignment = .fill
        createGroupStackView.distribution = .fillEqually
        
        membersCountTextField.placeholder = "Количество участников (2-10)"
        membersCountTextField.borderStyle = .roundedRect
        membersCountTextField.keyboardType = .numberPad
        
        createPasswordTextField.placeholder = "Придумайте пароль (мин. 6 символов)"
        createPasswordTextField.borderStyle = .roundedRect
        createPasswordTextField.isSecureTextEntry = true
        
        createButton.setTitle("Создать группу", for: .normal)
        createButton.backgroundColor = .systemGreen
        createButton.layer.cornerRadius = 8
        createButton.addTarget(self, action: #selector(createGroupTapped), for: .touchUpInside)
        
        createGroupStackView.addArrangedSubview(membersCountTextField)
        createGroupStackView.addArrangedSubview(createPasswordTextField)
        createGroupStackView.addArrangedSubview(createButton)
        
        view.addSubview(createGroupStackView)
    }
    
    private func setupOrLabel() {
        orLabel.text = "или"
        orLabel.textAlignment = .center
        orLabel.textColor = .secondaryLabel
        view.addSubview(orLabel)
    }
    
    private func setupConstraints() {
        joinGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        createGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            joinGroupStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            joinGroupStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            joinGroupStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            joinGroupStackView.heightAnchor.constraint(equalToConstant: 180),
            
            orLabel.topAnchor.constraint(equalTo: joinGroupStackView.bottomAnchor, constant: 16),
            orLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            orLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            createGroupStackView.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 16),
            createGroupStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            createGroupStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            createGroupStackView.heightAnchor.constraint(equalToConstant: 180)
        ])
    }
    
    @objc private func joinGroupTapped() {
        guard let groupId = groupIdTextField.text, !groupId.isEmpty,
              let password = passwordTextField.text, !password.isEmpty,
              let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Ошибка", message: "Заполните все поля")
            return
        }
        
        let groupRef = ref.child("groups").child(groupId)
        
        groupRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self,
                  snapshot.exists(),
                  let groupData = snapshot.value as? [String: Any],
                  let groupPassword = groupData["password"] as? String,
                  let membersCount = groupData["membersCount"] as? Int,
                  var currentMembers = groupData["currentMembers"] as? [String: Bool] else {
                self?.showAlert(title: "Ошибка", message: "Группа не найдена")
                return
            }
            
            // Проверка пароля
            guard groupPassword == password else {
                self.showAlert(title: "Ошибка", message: "Неверный пароль")
                return
            }
            
            // Проверка свободных мест
            guard currentMembers.count < membersCount else {
                self.showAlert(title: "Ошибка", message: "Группа заполнена")
                return
            }
            
            // Добавление пользователя (как словарь!)
            currentMembers[userId] = true
            
            // Обновляем только подузел currentMembers
            groupRef.child("currentMembers").setValue(currentMembers) { error, _ in
                if let error = error {
                    self.showAlert(title: "Ошибка", message: error.localizedDescription)
                } else {
                    self.showAlert(title: "Успех", message: "Вы в группе!") {
                        self.navigateToSwipeScreen(groupId: groupId)
                    }
                }
            }
        }
    }
    
    @objc private func createGroupTapped() {
        guard let membersCount = Int(membersCountTextField.text ?? ""),
              membersCount >= 2 && membersCount <= 10,
              let password = createPasswordTextField.text,
              password.count >= 6,
              let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Ошибка", message: "Проверьте введенные данные")
            return
        }

        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document()
        
        let groupData: [String: Any] = [
            "id": groupRef.documentID,
            "password": password,
            "membersCount": membersCount,
            "currentMembers": [userId: true],
            "createdAt": FieldValue.serverTimestamp(),
            "creator": userId
        ]
        
        groupRef.setData(groupData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Ошибка", message: error.localizedDescription)
            } else {
                let alert = UIAlertController(
                    title: "Группа создана",
                    message: "ID: \(groupRef.documentID)\nПароль: \(password)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.navigateToSwipeScreen(groupId: groupRef.documentID)
                })
                self.present(alert, animated: true)
            }
        }
    }
    
    private func navigateToSwipeScreen(groupId: String) {
        let swipeVC = SwipeViewController()
        swipeVC.groupId = groupId
        navigationController?.pushViewController(swipeVC, animated: true)
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
