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
    
    private let topLeftCircle = UIView()
    private let bottomRightCircle = UIView()
    
    // Элементы UI для создания группы
    let createGroupStackView = UIStackView()
    let membersCountTextField = UITextField()
    let createPasswordTextField = UITextField()
    let createButton = UIButton()
    
    // Разделитель
    let orLabel = UILabel()
    
    // Ссылка на базу данных Firebase
    var ref: DatabaseReference!
    
    // Для хранения ID созданной группы
    private var groupIdToNavigate: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Управление группой"
        
        ref = Database.database().reference()
        
        setupBackgroundElements()
        setupJoinGroupUI()
        setupCreateGroupUI()
        setupOrLabel()
        setupConstraints()
    }
    
    private func setupBackgroundElements() {
        // Большой круг в левом верхнем углу
        topLeftCircle.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.1)
        topLeftCircle.layer.cornerRadius = 150
        topLeftCircle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(topLeftCircle)
            
        // Меньший круг в правом нижнем углу
        bottomRightCircle.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.1)
        bottomRightCircle.layer.cornerRadius = 100
        bottomRightCircle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomRightCircle)
        
        // Констрейнты для декоративных элементов
        NSLayoutConstraint.activate([
            topLeftCircle.widthAnchor.constraint(equalToConstant: 300),
            topLeftCircle.heightAnchor.constraint(equalToConstant: 300),
            topLeftCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: -150),
            topLeftCircle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -150),
            
            bottomRightCircle.widthAnchor.constraint(equalToConstant: 200),
            bottomRightCircle.heightAnchor.constraint(equalToConstant: 200),
            bottomRightCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100),
            bottomRightCircle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 100)
        ])
    }

    private func setupJoinGroupUI() {
        joinGroupStackView.axis = .vertical
        joinGroupStackView.spacing = 20
        joinGroupStackView.alignment = .fill
        joinGroupStackView.distribution = .fillEqually
        
        // Настройка текстовых полей
        groupIdTextField.placeholder = "ID группы"
        groupIdTextField.backgroundColor = .white
        groupIdTextField.layer.cornerRadius = 12
        groupIdTextField.layer.borderWidth = 1
        groupIdTextField.layer.borderColor = UIColor.systemGray5.cgColor
        groupIdTextField.font = UIFont.systemFont(ofSize: 16)
        groupIdTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: groupIdTextField.frame.height))
        groupIdTextField.leftViewMode = .always
        groupIdTextField.autocapitalizationType = .none
        groupIdTextField.autocorrectionType = .no
        
        passwordTextField.placeholder = "Пароль доступа"
        passwordTextField.backgroundColor = .white
        passwordTextField.layer.cornerRadius = 12
        passwordTextField.layer.borderWidth = 1
        passwordTextField.layer.borderColor = UIColor.systemGray5.cgColor
        passwordTextField.font = UIFont.systemFont(ofSize: 16)
        passwordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: passwordTextField.frame.height))
        passwordTextField.leftViewMode = .always
        passwordTextField.isSecureTextEntry = true
            
        // Настройка кнопки
        joinButton.setTitle("Вступить в группу", for: .normal)
        joinButton.backgroundColor = UIColor.systemBlue
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        joinButton.layer.cornerRadius = 12
        joinButton.layer.shadowColor = UIColor.systemBlue.cgColor
        joinButton.layer.shadowOpacity = 0.2
        joinButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        joinButton.layer.shadowRadius = 8
        joinButton.addTarget(self, action: #selector(joinGroupTapped), for: .touchUpInside)
        
        joinGroupStackView.addArrangedSubview(groupIdTextField)
        joinGroupStackView.addArrangedSubview(passwordTextField)
        joinGroupStackView.addArrangedSubview(joinButton)
        
        view.addSubview(joinGroupStackView)
    }

    private func setupCreateGroupUI() {
        createGroupStackView.axis = .vertical
        createGroupStackView.spacing = 20
        createGroupStackView.alignment = .fill
        createGroupStackView.distribution = .fillEqually
        
        // Настройка текстовых полей
        membersCountTextField.placeholder = "Количество участников (2-10)"
        membersCountTextField.backgroundColor = .white
        membersCountTextField.layer.cornerRadius = 12
        membersCountTextField.layer.borderWidth = 1
        membersCountTextField.layer.borderColor = UIColor.systemGray5.cgColor
        membersCountTextField.font = UIFont.systemFont(ofSize: 16)
        membersCountTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: membersCountTextField.frame.height))
        membersCountTextField.leftViewMode = .always
        membersCountTextField.keyboardType = .numberPad
        
        createPasswordTextField.placeholder = "Придумайте пароль (мин. 6 символов)"
        createPasswordTextField.backgroundColor = .white
        createPasswordTextField.layer.cornerRadius = 12
        createPasswordTextField.layer.borderWidth = 1
        createPasswordTextField.layer.borderColor = UIColor.systemGray5.cgColor
        createPasswordTextField.font = UIFont.systemFont(ofSize: 16)
        createPasswordTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: createPasswordTextField.frame.height))
        createPasswordTextField.leftViewMode = .always
        createPasswordTextField.isSecureTextEntry = true
        
        // Настройка кнопки
        createButton.setTitle("Создать группу", for: .normal)
        createButton.backgroundColor = UIColor.systemTeal
        createButton.setTitleColor(.white, for: .normal)
        createButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        createButton.layer.cornerRadius = 12
        createButton.layer.shadowColor = UIColor.systemTeal.cgColor
        createButton.layer.shadowOpacity = 0.2
        createButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        createButton.layer.shadowRadius = 8
        createButton.addTarget(self, action: #selector(createGroupTapped), for: .touchUpInside)
        
        createGroupStackView.addArrangedSubview(membersCountTextField)
        createGroupStackView.addArrangedSubview(createPasswordTextField)
        createGroupStackView.addArrangedSubview(createButton)
        
        view.addSubview(createGroupStackView)
    }
    
    private func setupOrLabel() {
        orLabel.text = "ИЛИ"
        orLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        orLabel.textColor = .systemTeal
        orLabel.textAlignment = .center
        orLabel.backgroundColor = .systemGray6
        orLabel.layer.cornerRadius = 12
        orLabel.clipsToBounds = true
        view.addSubview(orLabel)
    }
    
    private func setupConstraints() {
        joinGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        createGroupStackView.translatesAutoresizingMaskIntoConstraints = false
        orLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            joinGroupStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            joinGroupStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            joinGroupStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            joinGroupStackView.heightAnchor.constraint(equalToConstant: 200),
            
            orLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            orLabel.topAnchor.constraint(equalTo: joinGroupStackView.bottomAnchor, constant: 16),
            orLabel.widthAnchor.constraint(equalToConstant: 80),
            orLabel.heightAnchor.constraint(equalToConstant: 24),
            
            createGroupStackView.topAnchor.constraint(equalTo: orLabel.bottomAnchor, constant: 16),
            createGroupStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            createGroupStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            createGroupStackView.heightAnchor.constraint(equalToConstant: 200)
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
    
    // MARK: - Custom Alert for Group Creation
    
    private func showGroupCreatedAlert(groupId: String, password: String) {
        let alertViewController = UIViewController()
        alertViewController.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        
        // Контейнер для содержимого
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        alertViewController.view.addSubview(containerView)
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = "Группа создана!"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .systemTeal
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(titleLabel)
        
        // Информация о группе
        let infoLabel = UILabel()
        infoLabel.text = "ID: \(groupId)\nПароль: \(password)"
        infoLabel.numberOfLines = 0
        infoLabel.textAlignment = .center
        infoLabel.font = UIFont.systemFont(ofSize: 16)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(infoLabel)
        
        // Кнопка копирования
        let copyButton = UIButton(type: .system)
        copyButton.setTitle("Копировать", for: .normal)
        copyButton.backgroundColor = .systemBlue
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        copyButton.layer.cornerRadius = 8
        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.addTarget(self, action: #selector(copyButtonTapped), for: .touchUpInside)
        containerView.addSubview(copyButton)
        
        // Кнопка OK
        let okButton = UIButton(type: .system)
        okButton.setTitle("OK", for: .normal)
        okButton.backgroundColor = .systemTeal
        okButton.setTitleColor(.white, for: .normal)
        okButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        okButton.layer.cornerRadius = 8
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
