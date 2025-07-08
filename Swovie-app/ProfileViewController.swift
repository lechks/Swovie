import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {
    
    private var user: User?
    private let avatarView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    private var avatarImage: UIImage? = UIImage(systemName: "person.circle.fill")
    private var collections: [MovieCollection] = [
        MovieCollection(name: "Любимые Sci-Fi", reviews: [
            MovieReview(movieId: "10", rating: 5, comment: "Великолепно!")
        ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Профиль"
        
        setupScrollView()
        setupProfileHeader()
        setupProfileInfo()
        setupLogoutButton()
        loadUserData()
    }
    
    private func loadUserData() {
            AuthService.shared.fetchUserData { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let user):
                        self?.user = user
                        self?.updateProfileUI()
                    case .failure(let error):
                        print("Ошибка загрузки данных пользователя: \(error.localizedDescription)")
                        self?.showErrorAlert(message: "Не удалось загрузить данные профиля")
                    }
                }
            }
        }
    
    private func updateProfileUI() {
        guard let user = user else { return }
        
        // Обновляем аватар
        avatarView.backgroundColor = user.avatarName
        
        // Обновляем текст
        refreshProfile()
    }
    
    private func setupLogoutButton() {
        // Создаем кнопку с иконкой выхода
        let logoutButton = UIButton(type: .system)
        logoutButton.setImage(UIImage(systemName: "rectangle.portrait.and.arrow.right"), for: .normal)
        logoutButton.tintColor = .systemRed
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        // Создаем UIBarButtonItem с кастомной view (кнопкой)
        let logoutBarButton = UIBarButtonItem(customView: logoutButton)
        
        // Устанавливаем размер кнопки
        logoutButton.widthAnchor.constraint(equalToConstant: 30).isActive = true
        logoutButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        navigationItem.rightBarButtonItem = logoutBarButton
    }
    
    @objc private func logoutTapped() {
        AuthService.shared.logout { [weak self] result in
            switch result {
            case .success:
                // После выхода показываем экран авторизации
                let authVC = AuthViewController()
                UIApplication.shared.windows.first?.rootViewController = UINavigationController(rootViewController: authVC)
                UIApplication.shared.windows.first?.makeKeyAndVisible()
            case .failure(let error):
                self?.showAlert(title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        contentView.axis = .vertical
        contentView.spacing = 24
        contentView.alignment = .fill
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func setupProfileHeader() {
        // Контейнер для аватарки и текстовой информации
        let headerStack = UIStackView()
        headerStack.axis = .horizontal
        headerStack.spacing = 16
        headerStack.alignment = .center
        
        // Аватарка
        let avatarImageView = UIImageView()
        avatarImageView.image = avatarImage
        avatarImageView.tintColor = .systemGray
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 50
        avatarImageView.clipsToBounds = true
        avatarImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        avatarImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        // Текстовая информация
        let infoStack = UIStackView()
        infoStack.axis = .vertical
        infoStack.spacing = 8
        
        let usernameLabel = UILabel()
        usernameLabel.text = user?.name
        usernameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        
        
        let idLabel = UILabel()
        idLabel.text = "ID: \(user?.id ?? "default")"
        idLabel.font = UIFont.systemFont(ofSize: 14)
        idLabel.textColor = .tertiaryLabel
        idLabel.isUserInteractionEnabled = true
        
        // Контейнер для ID
        let idContainer = UIStackView()
        idContainer.axis = .horizontal
        idContainer.spacing = 8
        idContainer.alignment = .center
        
        let copyButton = UIButton(type: .system)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.tintColor = .systemBlue
        copyButton.addTarget(self, action:#selector(copyIdTapped), for: .touchUpInside)
        
        idContainer.addArrangedSubview(idLabel)
        idContainer.addArrangedSubview(copyButton)
                
        infoStack.addArrangedSubview(usernameLabel)
        infoStack.addArrangedSubview(idContainer)
        
        headerStack.addArrangedSubview(avatarImageView)
        headerStack.addArrangedSubview(infoStack)
        
        contentView.addArrangedSubview(headerStack)
        
        
        let divider = UIView()
        divider.backgroundColor = .systemGray5
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
        contentView.addArrangedSubview(divider)
    }
    
    @objc private func copyIdTapped() {
        guard let userId = user?.id else { return }
        
        UIPasteboard.general.string = userId
        
        // Показываем всплывающее уведомление о копировании
        let alert = UIAlertController(title: "Скопировано", message: "ID пользователя скопирован в буфер обмена", preferredStyle: .alert)
        present(alert, animated: true)
        
        // Автоматически скрываем через 1 секунду
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true)
        }
    }
    
    private func setupProfileInfo() {
        let collectionsTitle = makeTitleLabel("Мои коллекции")
        contentView.addArrangedSubview(collectionsTitle)
        
        for collection in collections {
            let button = UIButton(type: .system)
            button.setTitle("📁 \(collection.name) (\(collection.reviews.count))", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(openCollection(_:)), for: .touchUpInside)
            // сохраним в tag индекс коллекции
            button.tag = collections.firstIndex(where: { $0.name == collection.name }) ?? 0
            contentView.addArrangedSubview(button)
        }
        
        let addCollectionButton = UIButton(type: .system)
        addCollectionButton.setTitle("➕ Добавить коллекцию", for: .normal)
        addCollectionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addCollectionButton.addTarget(self, action: #selector(addCollectionTapped), for: .touchUpInside)
        contentView.addArrangedSubview(addCollectionButton)
    }
    
    @objc private func openCollection(_ sender: UIButton) {
        let index = sender.tag
        let collection = collections[index]
        let detailVC = CollectionDetailViewController(collection: collection)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func addCollectionTapped() {
        let alert = UIAlertController(title: "Новая коллекция", message: "Введите название коллекции", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Например: Фильмы для осени" }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Создать", style: .default, handler: { [weak self] _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self?.collections.append(MovieCollection(name: name, reviews: []))
                self?.refreshProfile()
            }
        }))
        present(alert, animated: true)
    }
    
    private func refreshProfile() {
            guard let user = user else { return }
            
            // Обновляем аватар и текст
            if let initialsLabel = avatarView.subviews.first as? UILabel {
                initialsLabel.text = user.name.initials()
            }
            
            if let headerStack = contentView.arrangedSubviews.first as? UIStackView,
               let infoStack = headerStack.arrangedSubviews.last as? UIStackView,
               let usernameLabel = infoStack.arrangedSubviews.first as? UILabel,
               let idLabel = infoStack.arrangedSubviews.last as? UILabel {
                
                usernameLabel.text = user.name
                idLabel.text = "ID: \(user.id)"
            }
        }
    
    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        label.text = text
        label.numberOfLines = 0
        return label
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension String {
    func initials() -> String {
        let parts = self.components(separatedBy: " ")
        let initials = parts.prefix(2).compactMap { $0.first?.uppercased() }
        return initials.joined()
    }
}

extension ProfileViewController {
    private func setupChangeAvatarButton() {
        let changeButton = UIButton(type: .system)
        changeButton.setTitle("Сменить цвет аватара", for: .normal)
        changeButton.addTarget(self, action: #selector(changeAvatarColor), for: .touchUpInside)
        
        // Добавляем кнопку под аватаром
        let avatarContainer = UIStackView(arrangedSubviews: [avatarView, changeButton])
        avatarContainer.axis = .vertical
        avatarContainer.spacing = 8
        avatarContainer.alignment = .center
    }
    
    @objc private func changeAvatarColor() {
        user?.avatarName = .random()
        avatarView.backgroundColor = user?.avatarName
        
        // Анимация изменения
        UIView.animate(withDuration: 0.3, animations: {
            self.avatarView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.avatarView.transform = .identity
            }
        }
    }
}

extension UIColor {
    static func random() -> UIColor {
        return UIColor(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            alpha: 1.0
        )
    }
}
