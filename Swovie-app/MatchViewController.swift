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
<<<<<<< HEAD
        title = "Управление группой"
        
        ref = Database.database().reference()
=======
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        title = "Добавь пользователей"
>>>>>>> develop-design
        
        setupJoinGroupUI()
        setupCreateGroupUI()
        setupOrLabel()
        setupConstraints()
    }
    
<<<<<<< HEAD
    private func setupJoinGroupUI() {
        joinGroupStackView.axis = .vertical
        joinGroupStackView.spacing = 16
        joinGroupStackView.alignment = .fill
        joinGroupStackView.distribution = .fillEqually
=======
    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layer.cornerRadius = 8
        stackView.layer.borderWidth = 1
        stackView.layer.borderColor = UIColor.systemBlue.cgColor
        stackView.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        stackView.isLayoutMarginsRelativeArrangement = true
        view.addSubview(stackView)
>>>>>>> develop-design
        
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
    
<<<<<<< HEAD
    private func setupCreateGroupUI() {
        createGroupStackView.axis = .vertical
        createGroupStackView.spacing = 16
        createGroupStackView.alignment = .fill
        createGroupStackView.distribution = .fillEqually
=======
    private func setupAddIdButton() {
        addIdButton.setTitle("➕ Добавить ID", for: .normal)
        addIdButton.translatesAutoresizingMaskIntoConstraints = false
        addIdButton.addTarget(self, action: #selector(addIdField), for: .touchUpInside)
        addIdButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        addIdButton.layer.cornerRadius = 8
        addIdButton.setTitleColor(.systemBlue, for: .normal)
        addIdButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        view.addSubview(addIdButton)
>>>>>>> develop-design
        
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
    
<<<<<<< HEAD
    private func setupConstraints() {
        joinGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        createGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        orLabel.translatesAutoresizingMaskIntoConstraints = false
=======
    private func setupMatchButton() {
        matchButton.setTitle("🚀 Начать мэтчинг", for: .normal)
        matchButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        matchButton.translatesAutoresizingMaskIntoConstraints = false
        matchButton.addTarget(self, action: #selector(startMatching), for: .touchUpInside)
        matchButton.backgroundColor = UIColor.systemBlue
        matchButton.setTitleColor(.white, for: .normal)
        matchButton.layer.cornerRadius = 8
        matchButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        view.addSubview(matchButton)
>>>>>>> develop-design
        
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
    
<<<<<<< HEAD
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
=======
    @objc private func addIdField() {
        let textField = UITextField()
        textField.placeholder = "Введите ID пользователя"
        textField.borderStyle = .roundedRect
        textField.backgroundColor = UIColor.white
        textField.layer.borderColor = UIColor.systemBlue.cgColor
        textField.layer.borderWidth = 1
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeToRemove(_:)))
        swipeGesture.direction = .left
        textField.addGestureRecognizer(swipeGesture)
        textField.isUserInteractionEnabled = true
        idTextFields.append(textField)
        stackView.addArrangedSubview(textField)
    }
    
    @objc private func handleSwipeToRemove(_ gesture: UISwipeGestureRecognizer) {
        if let textField = gesture.view as? UITextField,
           let index = idTextFields.firstIndex(of: textField) {
            idTextFields.remove(at: index)
            textField.removeFromSuperview()
        }
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
>>>>>>> develop-design
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
