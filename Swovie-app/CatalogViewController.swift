import UIKit

class CatalogViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    
    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []
    private var movieService = MovieService()
    
    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Каталог"
        
        setupSearchBar()
        setupCollectionView()
        setupFilterButton()
        setupActivityIndicator()
        
        loadMovies()
    }
    
    private func setupActivityIndicator() {
        activityIndicator.center = view.center
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
    }
    
    private func loadMovies() {
        activityIndicator.startAnimating()
        
        movieService.fetchTopMovies(totalMovies: 260) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let loadedMovies):
                    self.movies = loadedMovies
                    self.filteredMovies = loadedMovies
                    self.collectionView.reloadData()
                    
                case .failure(let error):
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Поиск по названию или жанру"
        navigationItem.titleView = searchBar
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let itemWidth = (view.frame.size.width - 30) / 2
        layout.itemSize = CGSize(width: itemWidth, height: itemWidth * 1.5) // Соотношение сторон постеров
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: "MovieCell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        view.addSubview(collectionView)
    }
    
    private func setupFilterButton() {
        let filterItem = UIBarButtonItem(title: "Фильтры", style: .plain, target: self, action: #selector(filterTapped))
        navigationItem.leftBarButtonItem = filterItem
    }
    
    @objc private func filterTapped() {
        let alert = UIAlertController(title: "Фильтр по жанру", message: nil, preferredStyle: .actionSheet)
        
        // Получаем все уникальные жанры из фильмов
        let allGenreIds = Set(movies.flatMap { $0.genreIds })
        let genres = allGenreIds.compactMap { movieService.genreName(for: $0) }.sorted()
        
        for genre in genres {
            alert.addAction(UIAlertAction(title: genre, style: .default, handler: { _ in
                self.filteredMovies = self.movies.filter { movie in
                    let movieGenres = movie.genreIds.compactMap { self.movieService.genreName(for: $0) }
                    return movieGenres.contains(genre)
                }
                self.collectionView.reloadData()
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Сбросить", style: .cancel, handler: { _ in
            self.filteredMovies = self.movies
            self.collectionView.reloadData()
        }))
        
        present(alert, animated: true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredMovies = movies
        } else {
            filteredMovies = movies.filter { movie in
                let titleMatch = movie.title.lowercased().contains(searchText.lowercased())
                
                // Проверяем совпадение с названиями жанров
                let genreNames = movie.genreIds.compactMap { movieService.genreName(for: $0) }
                let genreMatch = genreNames.contains { $0.lowercased().contains(searchText.lowercased()) }
                
                return titleMatch || genreMatch
            }
        }
        collectionView.reloadData()
    }
    
    // MARK: - CollectionView
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredMovies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        let movie = filteredMovies[indexPath.item]
        cell.configure(with: movie)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let movie = filteredMovies[indexPath.item]
        let detailVC = MovieDetailViewController(movie: movie)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - MovieCell

class MovieCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let ratingLabel = UILabel()
    private let genreLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupViews() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        titleLabel.font = .boldSystemFont(ofSize: 14)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center
        
        ratingLabel.font = .systemFont(ofSize: 12)
        ratingLabel.textColor = .systemYellow
        ratingLabel.textAlignment = .center
        
        genreLabel.font = .systemFont(ofSize: 11)
        genreLabel.textColor = .secondaryLabel
        genreLabel.numberOfLines = 1
        genreLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, ratingLabel, genreLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.5)
        ])
    }
    
    func configure(with movie: Movie) {
        titleLabel.text = movie.title
        ratingLabel.text = String(format: "★ %.1f", movie.voteAverage)
        
        // Загрузка изображения
        if let posterURL = movie.posterURL {
            URLSession.shared.dataTask(with: posterURL) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                }
            }.resume()
        }
        
        // Отображение жанров
        let movieService = MovieService()
        let genres = movie.genreIds.prefix(2).compactMap { movieService.genreName(for: $0) }
        genreLabel.text = genres.joined(separator: ", ")
    }
}
