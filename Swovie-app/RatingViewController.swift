import UIKit
import FirebaseFirestore
import FirebaseAuth

class RatingViewController: UIViewController {
    
    // UI Elements
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let posterImageView = UIImageView()
    private let movieTitleLabel = UILabel()
    private let rateButton = UIButton(type: .system)
    
    private var user: User?

    
    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []
    private let movieService = MovieService()
    private var selectedMovie: Movie?
    
    // Декоративные элементы
    private let backgroundGradient = CAGradientLayer()
    private let topLeftCircle = UIView()
    private let bottomRightCircle = UIView()
    private let starsBackground = UIImageView()
    
    private var currentUser: User? {
        didSet {
            print("Текущий пользователь установлен:", currentUser?.name ?? "nil")
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    
    init(movie: Movie) {
        self.selectedMovie = movie
        super.init(nibName: nil, bundle: nil)
        
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {

        super.viewDidLoad()
        view.backgroundColor = AppColors.charcoal
        title = "Оценить фильм"
        setupBackground()
        loadUserData()
        setupUI()
        
        
        if let movie = selectedMovie {
            showMovieDetails(movie)
            searchBar.isHidden = true
            tableView.isHidden = true
        } else {
            loadPopularMovies()
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
        topLeftCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        topLeftCircle.layer.cornerRadius = 150
        view.insertSubview(topLeftCircle, at: 1)
        
        bottomRightCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        bottomRightCircle.layer.cornerRadius = 100
        view.insertSubview(bottomRightCircle, at: 1)
        
        // Звездный фон
        starsBackground.image = UIImage(systemName: "star.fill")?
            .withTintColor(AppColors.slate.withAlphaComponent(0.05), renderingMode: .alwaysOriginal)
        starsBackground.contentMode = .scaleAspectFill
        view.insertSubview(starsBackground, at: 1)
    }
    
    private func setupUI() {
        // Настройка searchBar
        searchBar.delegate = self
        searchBar.placeholder = "Найти фильм..."
        searchBar.searchTextField.backgroundColor = AppColors.slate.withAlphaComponent(0.2)
        searchBar.searchTextField.textColor = AppColors.white
        searchBar.searchTextField.leftView?.tintColor = AppColors.slate
        searchBar.barTintColor = AppColors.charcoal
        searchBar.tintColor = AppColors.slate
        
        // Настройка tableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.backgroundColor = AppColors.charcoal
        tableView.separatorColor = AppColors.slate.withAlphaComponent(0.3)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Настройка posterImageView
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.layer.cornerRadius = 12
        posterImageView.layer.borderWidth = 1
        posterImageView.layer.borderColor = AppColors.slate.withAlphaComponent(0.3).cgColor
        posterImageView.clipsToBounds = true
        posterImageView.layer.shadowColor = AppColors.charcoal.cgColor
        posterImageView.layer.shadowOpacity = 0.5
        posterImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        posterImageView.layer.shadowRadius = 8
        
        // Настройка movieTitleLabel
        movieTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        movieTitleLabel.textColor = AppColors.white
        movieTitleLabel.textAlignment = .center
        movieTitleLabel.numberOfLines = 0
        
        // Настройка rateButton
        rateButton.setTitle("Оценить ★", for: .normal)
        rateButton.backgroundColor = AppColors.slate
        rateButton.setTitleColor(AppColors.white, for: .normal)
        rateButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        rateButton.layer.cornerRadius = 12
        rateButton.layer.shadowColor = AppColors.slate.cgColor
        rateButton.layer.shadowOpacity = 0.3
        rateButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        rateButton.layer.shadowRadius = 8
        rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
        
        // Добавление элементов и констрейнтов
        [searchBar, tableView, posterImageView, movieTitleLabel, rateButton, starsBackground].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            // Декоративные элементы
            topLeftCircle.widthAnchor.constraint(equalToConstant: 300),
            topLeftCircle.heightAnchor.constraint(equalToConstant: 300),
            topLeftCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: -150),
            topLeftCircle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -150),
            
            bottomRightCircle.widthAnchor.constraint(equalToConstant: 200),
            bottomRightCircle.heightAnchor.constraint(equalToConstant: 200),
            bottomRightCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 100),
            bottomRightCircle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 100),
            
            starsBackground.topAnchor.constraint(equalTo: view.topAnchor),
            starsBackground.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            starsBackground.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            starsBackground.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Основные элементы
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 200),
            
            posterImageView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 40),
            posterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 200),
            posterImageView.heightAnchor.constraint(equalToConstant: 300),
            
            movieTitleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 20),
            movieTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            movieTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            rateButton.topAnchor.constraint(equalTo: movieTitleLabel.bottomAnchor, constant: 30),
            rateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rateButton.widthAnchor.constraint(equalToConstant: 200),
            rateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradient.frame = view.bounds
        
        // Создаем паттерн из звезд для фона
        let starSize: CGFloat = 24
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: starSize*5, height: starSize*5))
        let starPattern = renderer.image { ctx in
            for _ in 0..<10 {
                let randomX = CGFloat.random(in: 0...starSize*5)
                let randomY = CGFloat.random(in: 0...starSize*5)
                let star = UIImage(systemName: "star.fill")?
                    .withTintColor(AppColors.slate.withAlphaComponent(0.05))
                star?.draw(in: CGRect(x: randomX, y: randomY, width: starSize, height: starSize))
            }
        }
        starsBackground.image = starPattern
    }
    
    
    private func loadPopularMovies() {
        movieService.fetchTopMovies { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let movies) = result {
                    self?.movies = movies
                }
            }
        }
    }
    
    private func showMovieDetails(_ movie: Movie) {
        selectedMovie = movie
        movieTitleLabel.text = movie.title
        movieTitleLabel.isHidden = false
        posterImageView.isHidden = false
        rateButton.isHidden = false
        
        if let posterPath = movie.posterPath {
            let imageUrl = "https://image.tmdb.org/t/p/w500\(posterPath)"
            ImageLoader().loadImage(from: imageUrl) { [weak self] image in
                DispatchQueue.main.async {
                    self?.posterImageView.image = image
                }
            }
        }
    }
    
    @objc private func rateButtonTapped() {
        guard let movie = selectedMovie else {
            let alert = UIAlertController(title: "Ошибка", message: "Фильм не выбран", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
            
        if let user = user {
            self.showRatingDialog(for: movie, user: user)
        } else {
            self.showErrorAlert(message: "Не удалось загрузить данные пользователя")
        }
    }
    
    private func loadUserData() {
        AuthService.shared.fetchUserData { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.user = user
                case .failure(let error):
                    print("Ошибка загрузки данных пользователя: \(error.localizedDescription)")
                    self?.showErrorAlert(message: "Не удалось загрузить данные профиля")
                }
            }
        }
    }

    private func showRatingDialog(for movie: Movie, user: User) {
        let ratingDialog = UIAlertController(
            title: "Оценить фильм",
            message: "Выберите оценку для \(movie.title)",
            preferredStyle: .alert
        )
        
        for rating in 1...10 {
            ratingDialog.addAction(UIAlertAction(
                title: "\(rating)",
                style: .default,
                handler: { [weak self] _ in
                    self?.saveRating(rating, for: movie, user: user)
                }
            ))
        }
        
        ratingDialog.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(ratingDialog, animated: true)
    }
    
    private func saveRating(_ rating: Int, for movie: Movie, user: User) {
        let db = Firestore.firestore()
        let ratingData: [String: Any] = [
            "userId": user.id,
            "movieId": movie.id,
            "movieTitle": movie.title,
            "rating": rating,
            "timestamp": FieldValue.serverTimestamp(),
            "posterPath": movie.posterPath ?? ""
        ]
        
        db.collection("ratings").addDocument(data: ratingData) { error in
            if let error = error {
                print("Error saving rating: \(error.localizedDescription)")
                self.showErrorAlert(message: "Не удалось сохранить оценку")
            } else {
                print("Rating saved successfully")
                self.showSuccessAlert(message: "Вы оценили фильм на \(rating)")
                
                // Отправляем уведомление об обновлении оцененных фильмов
                NotificationCenter.default.post(name: NSNotification.Name("RatingsUpdated"), object: nil)
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    

    private func updateUserRatings(movie: Movie, rating: Int) {
        guard let userId = currentUser?.id else { return }
        let db = Firestore.firestore()
        
        let userRef = db.collection("users").document(userId)
        
        // Добавляем оценку в подколлекцию ratedMovies
        userRef.collection("ratedMovies").document("\(movie.id)").setData([
            "movieId": movie.id,
            "title": movie.title,
            "rating": rating,
            "timestamp": FieldValue.serverTimestamp(),
            "posterPath": movie.posterPath ?? ""
        ])
    }

    private func showSuccessAlert(message: String) {
        let alert = UIAlertController(title: "Успешно", message: message, preferredStyle: .alert)
        present(alert, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            alert.dismiss(animated: true)
        }
    }
}

extension RatingViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMovies = []
            tableView.isHidden = true
            posterImageView.isHidden = true
            movieTitleLabel.isHidden = true
            rateButton.isHidden = true
        } else {
            filteredMovies = movies.filter { $0.title.lowercased().contains(searchText.lowercased()) }
            tableView.isHidden = filteredMovies.isEmpty
            tableView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension RatingViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMovies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let movie = filteredMovies[indexPath.row]
        cell.textLabel?.text = movie.title
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMovie = filteredMovies[indexPath.row]
        searchBar.text = selectedMovie.title
        searchBar.resignFirstResponder()
        tableView.isHidden = true
        
        showMovieDetails(selectedMovie)
    }
}
// Вспомогательный класс для загрузки изображений
class ImageLoader {
    private let cache = NSCache<NSString, UIImage>()
    
    func loadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: urlString as NSString) {
            completion(cachedImage)
            return
        }
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            
            self?.cache.setObject(image, forKey: urlString as NSString)
            completion(image)
        }.resume()
    }
}

