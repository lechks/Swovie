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
    
    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []
    private let movieService = MovieService()
    private var currentUser: User?
    private var selectedMovie: Movie?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPopularMovies()
    }
    
    private func loadCurrentUser() {
            guard let firebaseUser = Auth.auth().currentUser else {
                //showLoginAlert()
                return
            }
        let db = Firestore.firestore()
            // Получаем вашего пользователя из Firestore
        db.collection("users").document(firebaseUser.uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
                
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                print("User data not found")
                return
            }
            
            // Преобразуем данные Firestore в вашу структуру User
            self.currentUser = self.parseUserData(data: data, userId: firebaseUser.uid)!
        }
    }

    private func parseUserData(data: [String: Any], userId: String) -> User? {
        guard let name = data["name"] as? String,
              let avatarHex = data["avatarColor"] as? String else {
            return nil
        }
        
        let avatarColor = UIColor(named: avatarHex) ?? .systemBlue
        var likedMovies: [Movie] = []
        
        return User(
            id: userId,
            name: name,
            avatarName: avatarColor,
            likedMovies: likedMovies
        )
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Оценить фильм"
        
        // Search bar
        searchBar.delegate = self
        searchBar.placeholder = "Введите название фильма"
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Table view for suggestions
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.isHidden = true
        view.addSubview(tableView)
        
        // Poster image view
        posterImageView.backgroundColor = .systemGray5
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.layer.cornerRadius = 12
        posterImageView.clipsToBounds = true
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.isHidden = true
        view.addSubview(posterImageView)
        
        // Movie title label
        movieTitleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        movieTitleLabel.textAlignment = .center
        movieTitleLabel.numberOfLines = 0
        movieTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        movieTitleLabel.isHidden = true
        view.addSubview(movieTitleLabel)
        
        // Rate button
        rateButton.setTitle("Оценить этот фильм", for: .normal)
        rateButton.backgroundColor = .systemBlue
        rateButton.setTitleColor(.white, for: .normal)
        rateButton.layer.cornerRadius = 8
        rateButton.addTarget(self, action: #selector(rateButtonTapped), for: .touchUpInside)
        rateButton.translatesAutoresizingMaskIntoConstraints = false
        rateButton.isHidden = true
        view.addSubview(rateButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 200),
            
            posterImageView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            posterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 200),
            posterImageView.heightAnchor.constraint(equalToConstant: 300),
            
            movieTitleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 20),
            movieTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            movieTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            rateButton.topAnchor.constraint(equalTo: movieTitleLabel.bottomAnchor, constant: 20),
            rateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            rateButton.widthAnchor.constraint(equalToConstant: 200),
            rateButton.heightAnchor.constraint(equalToConstant: 50)
        ])
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
        // Use the selectedMovie property instead of searching again
        guard let movie = selectedMovie else {
            // Show an alert if no movie is selected
            let alert = UIAlertController(title: "Ошибка", message: "Фильм не выбран", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Here you would typically show a rating interface
        print("Rating movie: \(movie.title)")
        
        let ratingDialog = UIAlertController(
            title: "Оценить фильм",
            message: "Выберите оценку для \(movie.title)",
            preferredStyle: .alert
        )
        
        for rating in 1...10 {
            ratingDialog.addAction(UIAlertAction(
                title: "\(rating)",
                style: .default,
                handler: { _ in
                    print("User rated \(movie.title) with \(rating) stars")
                    // Here you would save the rating to your database
                }
            ))
        }
        
        ratingDialog.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(ratingDialog, animated: true)
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
