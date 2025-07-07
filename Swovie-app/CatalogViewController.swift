import UIKit

class CatalogViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {

    private var movies: [Movie] = []
    private var filteredMovies: [Movie] = []

    private let searchBar = UISearchBar()
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Каталог"

        movies = sampleMovies()
        filteredMovies = movies

        setupSearchBar()
        setupCollectionView()
        setupFilterButton()
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Поиск по названию или жанру"
        navigationItem.titleView = searchBar
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: (view.frame.size.width - 30) / 2, height: 240)

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
        let genres = Array(Set(movies.map { $0.genre }))
        for genre in genres {
            alert.addAction(UIAlertAction(title: genre, style: .default, handler: { _ in
                self.filteredMovies = self.movies.filter { $0.genre == genre }
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
            filteredMovies = movies.filter { $0.title.lowercased().contains(searchText.lowercased()) || $0.genre.lowercased().contains(searchText.lowercased()) }
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

    private func sampleMovies() -> [Movie] {
        [
            // Здесь загрудать фильмы из апи
        ]
    }
}

// MARK: - MovieCell

class MovieCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let ratingLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = .boldSystemFont(ofSize: 14)
        titleLabel.numberOfLines = 2
        ratingLabel.font = .systemFont(ofSize: 12)
        ratingLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, ratingLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with movie: Movie) {
        imageView.image = UIImage(named: movie.poster_path!)
        titleLabel.text = movie.title
        ratingLabel.text = "⭐️ \(movie.rating)"
    }
}
