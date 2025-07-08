import UIKit
import Firebase
import FirebaseMessaging
import FirebaseAuth

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
    private var invitedUserIds: Set<String> = []
    
    
    private let db = Firestore.firestore()
    private var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
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
        textField.delegate = self
        idTextFields.append(textField)
        stackView.addArrangedSubview(textField)
    }
    
    @objc private func startMatching() {
        users.removeAll()
        invitedUserIds.removeAll()
        
        for textField in idTextFields {
            guard let id = textField.text, !id.isEmpty else { continue }
            invitedUserIds.insert(id)
        }
        
        if invitedUserIds.isEmpty {
            showAlert(title: "Ошибка", message: "Не найдено пользователей с такими ID")
        } else {
            verifyUsersExist { [weak self] allExist in
                if allExist {
                    self?.createGroupAndSendInvitations()
                } else {
                    self?.showAlert(title: "Ошибка", message: "Некоторые пользователи не найдены")
                }
            }
        }
    }
    
    private func createGroupAndSendInvitations() {
        guard let currentUserId = currentUserId else {
            showAlert(title: "Ошибка", message: "Пользователь не авторизован")
                return
        }
        
        let groupId = UUID().uuidString
        let groupName = "Группа \(Date().formatted())"
            
        // Добавляем текущего пользователя в приглашенные, если его ID был введен
        var allInvitedUsers = Array(invitedUserIds)
        if invitedUserIds.contains(currentUserId) {
            allInvitedUsers.append(currentUserId)
        }
        
        let groupData: [String: Any] = [
            "id": groupId,
            "name": groupName,
            "adminId": currentUserId,
            "memberIds": [currentUserId], // Админ сразу становится участником
            "pendingInvitations": allInvitedUsers, // Все приглашенные, включая админа
            "createdAt": Timestamp(date: Date())
        ]
        
        // Создаем группу в Firestore
        db.collection("groups").document(groupId).setData(groupData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.showAlert(title: "Ошибка", message: error.localizedDescription)
                return
            }
            
            // Отправляем уведомления всем приглашенным пользователям
            self.sendInvitationsToUsers(groupId: groupId, groupName: groupName)
            
            // Переходим к свайпу
            self.showSwipeViewController(groupId: groupId)
        }
    }
    
    private func sendInvitationsToUsers(groupId: String, groupName: String) {
        guard let currentUserId = currentUserId else { return }
        
        // Получаем данные текущего пользователя (админа группы)
        db.collection("users").document(currentUserId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let adminData = snapshot?.data(),
                  let adminName = adminData["name"] as? String else { return }
            
            // Для каждого приглашенного пользователя
            for userId in self.invitedUserIds {
                // 1. Добавляем уведомление в коллекцию пользователя
                self.db.collection("notifications")
                    .document(userId)
                    .collection("pending")
                    .addDocument(data: [
                        "type": "group_invitation",
                        "groupId": groupId,
                        "groupName": groupName,
                        "inviterId": currentUserId,
                        "inviterName": adminName,
                        "timestamp": Timestamp(date: Date()),
                        "isRead": false
                    ])
                
                // 2. Отправляем push-уведомление
                self.sendPushNotification(to: userId, groupId: groupId, groupName: groupName, inviterName: adminName)
            }
        }
    }
    
    private func sendPushNotification(to userId: String, groupId: String, groupName: String, inviterName: String) {
        // Получаем FCM токен пользователя
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let userData = snapshot?.data(),
                  let fcmToken = userData["fcmToken"] as? String else { return }
            
            // Отправляем push-уведомление
            let message: [String: Any] = [
                "to": fcmToken,
                "notification": [
                    "title": "Приглашение в группу",
                    "body": "\(inviterName) приглашает вас в группу \(groupName)",
                    "sound": "default"
                ],
                "data": [
                    "type": "group_invitation",
                    "groupId": groupId,
                    "inviterId": self.currentUserId ?? ""
                ]
            ]
            
            // Здесь должна быть реализация отправки уведомления через FCM
            // Например, через Cloud Functions или напрямую к FCM API
            self.sendFCMNotification(message: message)
        }
    }
    
    private func sendFCMNotification(message: [String: Any]) {
        // Реализация отправки уведомления через URLSession
        // Требуется серверный ключ из Firebase Console
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=AIzaSyBcYQxGyuU5sJkyBb8JCoCAP0H81QBqWFE", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: message, options: [])
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    print("Notification sent: \(String(data: data, encoding: .utf8) ?? "")")
                }
            }
            task.resume()
        } catch {
            print("Error creating notification JSON: \(error.localizedDescription)")
        }
    }
    
    private func showSwipeViewController(groupId: String) {
        let swipeVC = SwipeViewController()
        swipeVC.groupId = groupId
        navigationController?.pushViewController(swipeVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func verifyUsersExist(completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        var allExist = true
        
        for userId in invitedUserIds {
            dispatchGroup.enter()
            db.collection("users").document(userId).getDocument { snapshot, error in
                defer { dispatchGroup.leave() }
                
                if error != nil || snapshot?.exists != true {
                    allExist = false
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(allExist)
        }
    }
}

extension MatchViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let id = textField.text, !id.isEmpty else { return }
        
        // Можно добавить проверку существования пользователя в реальной базе
        // db.collection("users").document(id).getDocument { ... }
    }
}
