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
        guard let groupId = groupIdTextField.text?.trimmingCharacters(in: .whitespaces),
              !groupId.isEmpty else {
            showAlert(title: "Ошибка", message: "Введите ID группы")
            return
        }
        
        let db = Firestore.firestore()
        let groupRef = db.collection("groups").document(groupId)
        
        groupRef.getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Ошибка", message: "Ошибка подключения: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                self.showAlert(title: "Ошибка", message: "Группа с ID \(groupId) не найдена")
                return
            }
            
            // Дальнейшая обработка существующей группы
            self.processExistingGroup(snapshot: snapshot)
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
                self.groupIdToNavigate = groupRef.documentID
                self.showGroupCreatedAlert(groupId: groupRef.documentID, password: password)
            }
        }
    }

    // Добавляем свойство для хранения ID группы
    private var groupIdToNavigate: String?
    
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
    
    private func processExistingGroup(snapshot: DocumentSnapshot) {
        guard let data = snapshot.data(),
              let password = data["password"] as? String,
              let membersCount = data["membersCount"] as? Int,
              var currentMembers = data["currentMembers"] as? [String: Bool],
              let creator = data["creator"] as? String else {
            showAlert(title: "Ошибка", message: "Некорректная структура группы")
            return
        }
        
        // Проверка пароля
        if passwordTextField.text != password {
            showAlert(title: "Ошибка", message: "Неверный пароль")
            return
        }
        
        // Проверка свободных мест
        if currentMembers.count >= membersCount {
            showAlert(title: "Ошибка", message: "Группа уже заполнена")
            return
        }
        
        // Добавление пользователя
        guard let userId = Auth.auth().currentUser?.uid else {
            showAlert(title: "Ошибка", message: "Необходима авторизация")
            return
        }
        
        currentMembers[userId] = true
        
        // Обновление группы
        snapshot.reference.updateData(["currentMembers": currentMembers]) { [weak self] error in
            if let error = error {
                self?.showAlert(title: "Ошибка", message: "Ошибка вступления: \(error.localizedDescription)")
            } else {
                self?.showAlert(title: "Успех", message: "Вы успешно вступили в группу!") {
                    self?.navigateToSwipeScreen(groupId: snapshot.documentID)
                }
            }
        }
    }
    
    private func showGroupCreatedAlert(groupId: String, password: String) {
        // Создаем обычный UIViewController вместо UIAlertController
        let alertViewController = UIViewController()
        alertViewController.view.backgroundColor = .systemBackground
        
        // Настройка контейнера
        let containerView = UIView()
        containerView.backgroundColor = .secondarySystemBackground
        containerView.layer.cornerRadius = 12
        containerView.translatesAutoresizingMaskIntoConstraints = false
        alertViewController.view.addSubview(containerView)
        
        // Настройка заголовка
        let titleLabel = UILabel()
        titleLabel.text = "Группа создана"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Настройка текста с ID и паролем
        let infoLabel = UILabel()
        infoLabel.text = "ID: \(groupId)\nПароль: \(password)"
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(infoLabel)
        
        // Кнопка копирования
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Копировать", for: .normal)
        copyButton.backgroundColor = .systemBlue
        copyButton.layer.cornerRadius = 8
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        containerView.addSubview(copyButton)
        
        // Кнопка OK
        let okButton = UIButton(type: .system)
        okButton.setTitle("OK", for: .normal)
        okButton.backgroundColor = .systemGreen
        okButton.layer.cornerRadius = 8
        okButton.setTitleColor(.white, for: .normal)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.addTarget(self, action: #selector(okButtonTapped), for: .touchUpInside)
        containerView.addSubview(okButton)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: alertViewController.view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: alertViewController.view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 270),
            
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            copyButton.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 20),
            copyButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            copyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            copyButton.heightAnchor.constraint(equalToConstant: 44),
            
            okButton.topAnchor.constraint(equalTo: copyButton.bottomAnchor, constant: 8),
            okButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            okButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            okButton.heightAnchor.constraint(equalToConstant: 44),
            okButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
        
        // Сохраняем данные для копирования
        objc_setAssociatedObject(alertViewController, &AssociatedKeys.groupInfo, "ID: \(groupId)\nПароль: \(password)", .OBJC_ASSOCIATION_RETAIN)
        
        // Показываем как модальное окно
        alertViewController.modalPresentationStyle = .overCurrentContext
        alertViewController.modalTransitionStyle = .crossDissolve
        self.present(alertViewController, animated: true)
    }

    // Ключ для ассоциативного объекта
    private struct AssociatedKeys {
        static var groupInfo = "groupInfo"
    }

    // Обработчики кнопок
    @objc private func copyButtonTapped(sender: UIButton) {
        if let alertVC = presentedViewController,
           let textToCopy = objc_getAssociatedObject(alertVC, &AssociatedKeys.groupInfo) as? String {
            UIPasteboard.general.string = textToCopy
            
            // Меняем текст кнопки после копирования
            sender.setTitle("Скопировано!", for: .normal)
            sender.backgroundColor = .systemGray
            
            // Возвращаем исходный вид через 2 секунды
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                sender.setTitle("Копировать", for: .normal)
                sender.backgroundColor = .systemBlue
            }
        }
    }

    @objc private func okButtonTapped() {
        dismiss(animated: true) {
            if let groupId = self.groupIdToNavigate {
                self.navigateToSwipeScreen(groupId: groupId)
            }
        }
    }
}
