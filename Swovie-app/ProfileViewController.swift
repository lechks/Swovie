import UIKit
import FirebaseAuth
import FirebaseFirestore
class ProfileViewController: UIViewController {
    
    private var user: User?
    private var ratedMovies: [RatedMovie] = []
    private let avatarView = UIView()
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    private var avatarImage: UIImage? = UIImage(systemName: "person.circle.fill")
    private var collections: [MovieCollection]
    
    // Декоративные элементы
    private let backgroundGradient = CAGradientLayer()
    private let topRightCircle = UIView()
    private let bottomLeftCircle = UIView()
    private let starsPattern = UIImageView()
    
    
    init(collections: [MovieCollection] = []) {
            self.collections = collections
            super.init(nibName: nil, bundle: nil)
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Профиль"
        setupBackground()
        loadRatedMovies()
        setupScrollView()
        setupProfileHeader()
        setupProfileInfo()
        setupLogoutButton()
        loadUserData()
        loadRatedMoviesCollection()
        // Добавляем наблюдатель для обновлений
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRatingsUpdate),
            name: NSNotification.Name("RatingsUpdated"),
            object: nil
        )
    }
    
    @objc private func handleRatingsUpdate() {
        loadRatedMoviesCollection()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    private func loadRatedMovies() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
            
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("ratedMovies")
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading rated movies: \(error.localizedDescription)")
                    return
                }
                
                self.ratedMovies = snapshot?.documents.compactMap { doc in
                    let data = doc.data()
                    return RatedMovie(
                        id: data["movieId"] as? Int ?? 0,
                        title: data["title"] as? String ?? "",
                        rating: data["rating"] as? Int ?? 0,
                        posterPath: data["posterPath"] as? String
                    )
                } ?? []
                
                self.setupRatedMoviesSection()
            }
    }
    
    private func setupBackground() {
            // Градиентный фон
            backgroundGradient.colors = [
                AppColors.charcoal.cgColor,
                AppColors.slate.withAlphaComponent(0.3).cgColor,
                AppColors.charcoal.cgColor
            ]
            backgroundGradient.locations = [0, 0.5, 1]
            view.layer.insertSublayer(backgroundGradient, at: 0)
            
            // Декоративные круги
            topRightCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
            topRightCircle.layer.cornerRadius = 120
            view.insertSubview(topRightCircle, at: 1)
            
            bottomLeftCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
            bottomLeftCircle.layer.cornerRadius = 80
            view.insertSubview(bottomLeftCircle, at: 1)
            
            // Звездный паттерн
            starsPattern.image = createStarsPattern()
            starsPattern.contentMode = .scaleAspectFill
            starsPattern.alpha = 0.05
            view.insertSubview(starsPattern, at: 1)
    }
        
    private func createStarsPattern() -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200))
            return renderer.image { ctx in
                for _ in 0..<15 {
                    let x = CGFloat.random(in: 0..<200)
                    let y = CGFloat.random(in: 0..<200)
                    let star = UIImage(systemName: "star.fill")?
                        .withTintColor(AppColors.slate)
                    star?.draw(in: CGRect(x: x, y: y, width: 10, height: 10))
                }
            }
    }
    
    private func setupProfileHeader() {
            // Профильная карточка
            let profileCard = UIView()
            profileCard.backgroundColor = AppColors.slate.withAlphaComponent(0.2)
            profileCard.layer.cornerRadius = 20
            profileCard.layer.borderWidth = 1
            profileCard.layer.borderColor = AppColors.slate.withAlphaComponent(0.3).cgColor
            profileCard.layer.shadowColor = AppColors.charcoal.cgColor
            profileCard.layer.shadowOpacity = 0.3
            profileCard.layer.shadowOffset = CGSize(width: 0, height: 4)
            profileCard.layer.shadowRadius = 10
            
            // Аватар
            let avatarImageView = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
            avatarImageView.tintColor = AppColors.white
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.layer.cornerRadius = 50
            avatarImageView.clipsToBounds = true
            avatarImageView.layer.borderWidth = 2
            avatarImageView.layer.borderColor = AppColors.slate.cgColor
            
            // Имя пользователя
            let usernameLabel = UILabel()
            usernameLabel.text = user?.name ?? "Пользователь"
            usernameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
            usernameLabel.textColor = AppColors.white
            usernameLabel.textAlignment = .center
            
            // ID пользователя
            let idLabel = UILabel()
            idLabel.text = "ID: \(user?.id ?? "---")"
            idLabel.font = UIFont.systemFont(ofSize: 14)
            idLabel.textColor = AppColors.slate
            idLabel.textAlignment = .center
            
            // Кнопка смены аватара
            let changeAvatarButton = UIButton(type: .system)
            changeAvatarButton.setTitle("Сменить аватар", for: .normal)
            changeAvatarButton.setTitleColor(AppColors.slate, for: .normal)
            changeAvatarButton.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
            changeAvatarButton.addTarget(self, action: #selector(changeAvatarColor), for: .touchUpInside)
            
            let stack = UIStackView(arrangedSubviews: [
                avatarImageView,
                usernameLabel,
                idLabel,
                changeAvatarButton
            ])
            stack.axis = .vertical
            stack.spacing = 12
            stack.alignment = .center
            
            profileCard.addSubview(stack)
            contentView.addArrangedSubview(profileCard)
            
            // Констрейнты
            avatarImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
            avatarImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            
            stack.translatesAutoresizingMaskIntoConstraints = false
            profileCard.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                profileCard.widthAnchor.constraint(equalTo: contentView.widthAnchor),
                
                stack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 24),
                stack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -24),
                stack.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -24),
            ])
        }
    
    private func setupRatedMoviesSection() {
            // Удаляем старую секцию, если есть
            if let ratedSectionIndex = contentView.arrangedSubviews.firstIndex(where: { ($0 as? UILabel)?.text == "Оцененные фильмы" }) {
                for view in contentView.arrangedSubviews.suffix(from: ratedSectionIndex) {
                    view.removeFromSuperview()
                }
            }
            
            // Добавляем заголовок
            let ratedTitleLabel = makeTitleLabel("Оцененные фильмы")
            contentView.addArrangedSubview(ratedTitleLabel)
            
            // Добавляем фильмы
            for movie in ratedMovies {
                let movieView = createRatedMovieView(movie: movie)
                contentView.addArrangedSubview(movieView)
            }
        }
        
//        private func createRatedMovieView(movie: RatedMovie) -> UIView {
//            let container = UIView()
//            container.translatesAutoresizingMaskIntoConstraints = false
//            
//            // Постер
//            let posterImageView = UIImageView()
//            posterImageView.translatesAutoresizingMaskIntoConstraints = false
//            posterImageView.contentMode = .scaleAspectFill
//            posterImageView.clipsToBounds = true
//            posterImageView.layer.cornerRadius = 8
//            if let posterPath = movie.posterPath {
//                let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
//                posterImageView.sd_setImage(with: url)
//            }
//            
//            // Название и рейтинг
//            let titleLabel = UILabel()
//            titleLabel.translatesAutoresizingMaskIntoConstraints = false
//            titleLabel.text = movie.title
//            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
//            
//            let ratingLabel = UILabel()
//            ratingLabel.translatesAutoresizingMaskIntoConstraints = false
//            ratingLabel.text = "★ \(movie.rating)/10"
//            ratingLabel.textColor = .systemYellow
//            ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
//            
//            // Стек для текста
//            let textStack = UIStackView(arrangedSubviews: [titleLabel, ratingLabel])
//            textStack.axis = .vertical
//            textStack.spacing = 4
//            textStack.translatesAutoresizingMaskIntoConstraints = false
//            
//            // Основной стек
//            let mainStack = UIStackView(arrangedSubviews: [posterImageView, textStack])
//            mainStack.axis = .horizontal
//            mainStack.spacing = 12
//            mainStack.alignment = .center
//            mainStack.translatesAutoresizingMaskIntoConstraints = false
//            
//            container.addSubview(mainStack)
//            
//            // Констрейнты
//            NSLayoutConstraint.activate([
//                posterImageView.widthAnchor.constraint(equalToConstant: 50),
//                posterImageView.heightAnchor.constraint(equalToConstant: 75),
//                
//                mainStack.topAnchor.constraint(equalTo: container.topAnchor),
//                mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
//                mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
//                mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
//            ])
//            
//            return container
//        }
    
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
    
    private func createRatedMovieView(movie: RatedMovie) -> UIView {
            let container = UIView()
            container.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
            container.layer.cornerRadius = 12
            container.layer.borderWidth = 1
            container.layer.borderColor = AppColors.slate.withAlphaComponent(0.2).cgColor
            
            // Постер
            let posterImageView = UIImageView()
            if let posterPath = movie.posterPath {
                let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
                posterImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "film.fill"))
            } else {
                posterImageView.image = UIImage(systemName: "film.fill")
            }
            posterImageView.tintColor = AppColors.slate
            posterImageView.contentMode = .scaleAspectFill
            posterImageView.layer.cornerRadius = 8
            posterImageView.clipsToBounds = true
            
            // Информация о фильме
            let titleLabel = UILabel()
            titleLabel.text = movie.title
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            titleLabel.textColor = AppColors.white
            titleLabel.numberOfLines = 2
            
            let ratingLabel = UILabel()
            ratingLabel.text = "★ \(movie.rating)/10"
            ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
            ratingLabel.textColor = .systemYellow
            
            let textStack = UIStackView(arrangedSubviews: [titleLabel, ratingLabel])
            textStack.axis = .vertical
            textStack.spacing = 4
            
            let mainStack = UIStackView(arrangedSubviews: [posterImageView, textStack])
            mainStack.axis = .horizontal
            mainStack.spacing = 12
            mainStack.alignment = .center
            
            container.addSubview(mainStack)
            
            // Констрейнты
            posterImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
            posterImageView.heightAnchor.constraint(equalToConstant: 75).isActive = true
            
            mainStack.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                mainStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
                mainStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
                mainStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
                mainStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            ])
            
            return container
    }
        
    private func setupProfileInfo() {
            // Секция "Мои коллекции"
            let collectionsTitleLabel = UILabel()
            collectionsTitleLabel.text = "Мои коллекции"
            collectionsTitleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            collectionsTitleLabel.textColor = AppColors.white
            
            let addButton = UIButton(type: .system)
            addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            addButton.tintColor = AppColors.slate
            addButton.addTarget(self, action: #selector(addCollectionTapped), for: .touchUpInside)
            
            let titleStack = UIStackView(arrangedSubviews: [collectionsTitleLabel, addButton])
            titleStack.axis = .horizontal
            titleStack.distribution = .equalSpacing
            contentView.addArrangedSubview(titleStack)
            
            // Оцененные фильмы
            if let ratedCollection = collections.first(where: { $0.id == "rated" }) {
                let ratedHeader = UILabel()
                ratedHeader.text = "Оцененные фильмы"
                ratedHeader.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                ratedHeader.textColor = AppColors.white
                contentView.addArrangedSubview(ratedHeader)
                
                for movie in ratedCollection.movies.prefix(3) {
                    contentView.addArrangedSubview(createRatedMovieView(movie: movie))
                }
                
                if ratedCollection.movies.count > 3 {
                    let showAllButton = UIButton(type: .system)
                    showAllButton.setTitle("Показать все (\(ratedCollection.movies.count)) →", for: .normal)
                    showAllButton.setTitleColor(AppColors.slate, for: .normal)
                    showAllButton.addTarget(self, action: #selector(showAllRatedMovies), for: .touchUpInside)
                    contentView.addArrangedSubview(showAllButton)
                }
            }
            
            // Пользовательские коллекции
            for (index, collection) in collections.filter({ $0.id != "rated" }).enumerated() {
                let collectionView = createCollectionView(collection: collection, index: index)
                contentView.addArrangedSubview(collectionView)
            }
    }
        
    private func createCollectionView(collection: MovieCollection, index: Int) -> UIView {
        let container = UIView()
            container.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
            container.layer.cornerRadius = 12
            container.layer.borderWidth = 1
            container.layer.borderColor = AppColors.slate.withAlphaComponent(0.2).cgColor
            
            let icon = UIImageView(image: UIImage(systemName: "folder.fill"))
            icon.tintColor = AppColors.slate
            
            let titleLabel = UILabel()
            titleLabel.text = collection.name
            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            titleLabel.textColor = AppColors.white
            
            let countLabel = UILabel()
            countLabel.text = "\(collection.movies.count)"
            countLabel.font = UIFont.systemFont(ofSize: 14)
            countLabel.textColor = AppColors.slate
            
            let arrowIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
            arrowIcon.tintColor = AppColors.slate
            
            let stack = UIStackView(arrangedSubviews: [icon, titleLabel, countLabel, arrowIcon])
            stack.axis = .horizontal
            stack.spacing = 12
            stack.alignment = .center
            
            container.addSubview(stack)
            
            // Констрейнты
            icon.widthAnchor.constraint(equalToConstant: 20).isActive = true
            arrowIcon.widthAnchor.constraint(equalToConstant: 12).isActive = true
            
            stack.translatesAutoresizingMaskIntoConstraints = false
            container.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
                stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            ])
            
            // Добавляем тап-жест
            let tap = UITapGestureRecognizer(target: self, action: #selector(openCollectionFromView(_:)))
            container.addGestureRecognizer(tap)
            container.tag = index
            
            return container
        }
        
        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            backgroundGradient.frame = view.bounds
            
            // Обновляем позиции декоративных элементов
            topRightCircle.frame = CGRect(
                x: view.bounds.width - 120,
                y: -120,
                width: 240,
                height: 240
            )
            
            bottomLeftCircle.frame = CGRect(
                x: -80,
                y: view.bounds.height - 80,
                width: 160,
                height: 160
            )
            
            starsPattern.frame = view.bounds
        }
    
//    private func setupProfileHeader() {
//        // Создаем профильную карточку с frosted glass эффектом
//        let profileCard = UIView()
//        profileCard.translatesAutoresizingMaskIntoConstraints = false
//        profileCard.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
//        profileCard.layer.cornerRadius = 20
//        profileCard.layer.masksToBounds = false
//        profileCard.layer.shadowColor = UIColor.black.cgColor
//        profileCard.layer.shadowOpacity = 0.15
//        profileCard.layer.shadowOffset = CGSize(width: 0, height: 4)
//        profileCard.layer.shadowRadius = 8
//        
//        // Вертикальный стек для содержимого карточки
//        let stack = UIStackView()
//        stack.axis = .vertical
//        stack.alignment = .center
//        stack.spacing = 16
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        
//        // Аватарка
//        let avatarImageView = UIImageView()
//        avatarImageView.image = avatarImage
//        avatarImageView.tintColor = .systemGray
//        avatarImageView.contentMode = .scaleAspectFill
//        avatarImageView.layer.cornerRadius = 50
//        avatarImageView.clipsToBounds = true
//        avatarImageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
//        avatarImageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
//        
//        // Имя пользователя
//        let usernameLabel = UILabel()
//        usernameLabel.text = user?.name
//        usernameLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
//        usernameLabel.textAlignment = .center
//        usernameLabel.numberOfLines = 1
//        
//        // ID пользователя
//        let idLabel = UILabel()
//        idLabel.text = "ID: \(user?.id ?? "default")"
//        idLabel.font = UIFont.systemFont(ofSize: 16)
//        idLabel.textColor = .tertiaryLabel
//        idLabel.isUserInteractionEnabled = true
//        
//        // Контейнер для ID
//        let idContainer = UIStackView()
//        idContainer.axis = .horizontal
//        idContainer.spacing = 8
//        idContainer.alignment = .center
//        
//        // Добавляем только аватар, имя, ID
//        stack.addArrangedSubview(avatarImageView)
//        stack.addArrangedSubview(usernameLabel)
//        stack.addArrangedSubview(idLabel)
//        
//        profileCard.addSubview(stack)
//        
//        // Добавляем профильную карточку в contentView
//        contentView.addArrangedSubview(profileCard)
//        
//        // Ограничения для стека внутри карточки
//        NSLayoutConstraint.activate([
//            stack.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 24),
//            stack.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -24),
//            stack.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 24),
//            stack.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -24),
//            profileCard.widthAnchor.constraint(equalTo: contentView.widthAnchor)
//        ])
//    }
    
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
    
//    private func setupProfileInfo() {
//        // Create horizontal stack for title and "+" button
//        let collectionsTitleLabel = makeTitleLabel("Мои коллекции")
//        collectionsTitleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
//
//        let addButton = UIButton(type: .system)
//        let plusImage = UIImage(systemName: "plus")
//        addButton.setImage(plusImage, for: .normal)
//        addButton.tintColor = .systemBlue
//        addButton.addTarget(self, action: #selector(addCollectionTapped), for: .touchUpInside)
//        addButton.widthAnchor.constraint(equalToConstant: 28).isActive = true
//        addButton.heightAnchor.constraint(equalToConstant: 28).isActive = true
//        addButton.setContentHuggingPriority(.required, for: .horizontal)
//
//        let titleStack = UIStackView(arrangedSubviews: [collectionsTitleLabel, addButton])
//        titleStack.axis = .horizontal
//        titleStack.alignment = .center
//        titleStack.spacing = 8
//        contentView.addArrangedSubview(titleStack)
//        
//        // Добавляем секцию с оцененными фильмами
//            if let ratedCollection = collections.first(where: { $0.id == "rated" }) {
//                let ratedHeader = makeTitleLabel(ratedCollection.name)
//                contentView.addArrangedSubview(ratedHeader)
//                
//                for movie in ratedCollection.movies.prefix(5) { // Показываем первые 5
//                    let movieView = createRatedMovieView(movie: movie)
//                    contentView.addArrangedSubview(movieView)
//                }
//                
//                if ratedCollection.movies.count > 5 {
//                    let showAllButton = UIButton(type: .system)
//                    showAllButton.setTitle("Показать все (\(ratedCollection.movies.count))", for: .normal)
//                    showAllButton.addTarget(self, action: #selector(showAllRatedMovies), for: .touchUpInside)
//                    contentView.addArrangedSubview(showAllButton)
//                }
//            }
//
//        for (index, collection) in collections.enumerated() {
//            let folderIcon = UIImageView(image: UIImage(systemName: "folder.fill"))
//            folderIcon.tintColor = UIColor.systemBlue
//            folderIcon.setContentHuggingPriority(.required, for: .horizontal)
//
//            let titleLabel = UILabel()
//            titleLabel.text = collection.name
//            titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
//            titleLabel.numberOfLines = 1
//
//            let horizontalStack = UIStackView(arrangedSubviews: [folderIcon, titleLabel])
//            horizontalStack.axis = .horizontal
//            horizontalStack.alignment = .center
//            horizontalStack.spacing = 8
//            horizontalStack.isUserInteractionEnabled = true
//            horizontalStack.tag = index
//
//            // Add tap gesture recognizer to horizontalStack
//            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openCollectionFromView(_:)))
//            horizontalStack.addGestureRecognizer(tapGesture)
//
//            contentView.addArrangedSubview(horizontalStack)
//        }
//    }
    
    @objc private func openCollectionFromView(_ sender: UITapGestureRecognizer) {
        guard let view = sender.view else { return }
        let index = view.tag
        let collection = collections[index]
        let detailVC = CollectionDetailViewController(collection: collection)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func openCollection(_ sender: UIButton) {
        let index = sender.tag
        let collection = collections[index]
        let detailVC = CollectionDetailViewController(collection: collection)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func showAllRatedMovies() {
        guard let ratedCollection = collections.first(where: { $0.id == "rated" }) else { return }
        let ratedVC = RatedMoviesViewController(collection: ratedCollection)
        navigationController?.pushViewController(ratedVC, animated: true)
    }
    
    private func refreshProfile() {
            guard let user = user else { return }
            
            // Обновляем аватар и текст
            if let initialsLabel = avatarView.subviews.first as? UILabel {
                initialsLabel.text = user.name.initials()
            }
            
            if let headerStack = contentView.arrangedSubviews.first as? UIView,
               let stack = headerStack.subviews.first as? UIStackView,
               stack.arrangedSubviews.count >= 3,
               let usernameLabel = stack.arrangedSubviews[1] as? UILabel,
               let idLabel = stack.arrangedSubviews[2] as? UILabel {
                
                usernameLabel.text = user.name
                idLabel.text = "ID: \(user.id)"
            }
    }
    
    private func loadRatedMoviesCollection() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("ratings")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading rated movies: \(error.localizedDescription)")
                    return
                }
                
                let ratedMovies = snapshot?.documents.compactMap { doc -> RatedMovie? in
                    let data = doc.data()
                    guard let movieId = data["movieId"] as? Int,
                          let title = data["movieTitle"] as? String,
                          let rating = data["rating"] as? Int else {
                        return nil
                    }
                    
                    return RatedMovie(
                        id: movieId,
                        title: title,
                        rating: rating,
                        posterPath: data["posterPath"] as? String,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue()
                    )
                } ?? []
                
                // Создаем или обновляем коллекцию "Оцененные фильмы"
                if let index = self.collections.firstIndex(where: { $0.id == "rated" }) {
                    self.collections[index].movies = ratedMovies
                } else {
                    let ratedCollection = MovieCollection(
                        id: "rated",
                        name: "Оцененные фильмы",
                        movies: ratedMovies
                    )
                    self.collections.insert(ratedCollection, at: 0)
                }
                
                DispatchQueue.main.async {
                    self.reloadCollectionsList()
                }
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

extension ProfileViewController: CreateCollectionDelegate {
    @objc private func addCollectionTapped() {
        let createVC = CreateCollectionViewController()
        createVC.delegate = self
        let nav = UINavigationController(rootViewController: createVC)
        present(nav, animated: true)
    }
    
    func didCreateCollection(_ collection: MovieCollection) {
        collections.append(collection)
        reloadCollectionsList()
    }

    private func reloadCollectionsList() {
        // удаляем все старые коллекции, оставляя только профильную карточку
        while contentView.arrangedSubviews.count > 1 {
            contentView.arrangedSubviews.last?.removeFromSuperview()
        }
        setupProfileInfo()
    }
}
