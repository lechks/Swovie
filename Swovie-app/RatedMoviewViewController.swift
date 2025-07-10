import Foundation
import UIKit

class RatedMoviesViewController: UIViewController {
    private let collection: MovieCollection
    private let tableView = UITableView()
    
    // Декоративные элементы
    private let topLeftBlurCircle = UIView()
    private let bottomRightBlurCircle = UIView()
    private let gradientLayer = CAGradientLayer()
    
    init(collection: MovieCollection) {
        self.collection = collection
        super.init(nibName: nil, bundle: nil)
        title = collection.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.charcoal // Темный фон
        setupBackground()
        setupTableView()
    }
    
    private func setupBackground() {
        // Градиентный фон
        gradientLayer.colors = [
            AppColors.charcoal.cgColor,
            AppColors.slate.withAlphaComponent(0.2).cgColor,
            AppColors.charcoal.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.frame = view.bounds
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Декоративные размытые круги
        topLeftBlurCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        topLeftBlurCircle.layer.cornerRadius = 150
        topLeftBlurCircle.layer.masksToBounds = true
        view.insertSubview(topLeftBlurCircle, at: 0)
        
        bottomRightBlurCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        bottomRightBlurCircle.layer.cornerRadius = 100
        bottomRightBlurCircle.layer.masksToBounds = true
        view.insertSubview(bottomRightBlurCircle, at: 0)
    }
    
    private func setupTableView() {
        tableView.register(RatedMovieCell.self, forCellReuseIdentifier: "RatedMovieCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Констрейнты для декоративных элементов
        topLeftBlurCircle.translatesAutoresizingMaskIntoConstraints = false
        bottomRightBlurCircle.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topLeftBlurCircle.widthAnchor.constraint(equalToConstant: 300),
            topLeftBlurCircle.heightAnchor.constraint(equalToConstant: 300),
            topLeftBlurCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: -100),
            topLeftBlurCircle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -100),
            
            bottomRightBlurCircle.widthAnchor.constraint(equalToConstant: 200),
            bottomRightBlurCircle.heightAnchor.constraint(equalToConstant: 200),
            bottomRightBlurCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 50),
            bottomRightBlurCircle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 50)
        ])
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
}

extension RatedMoviesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RatedMovieCell", for: indexPath) as! RatedMovieCell
        let movie = collection.movies[indexPath.row]
        cell.configure(with: movie)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
}

class RatedMovieCell: UITableViewCell {
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let ratingLabel = UILabel()
    private let starImageView = UIImageView()
    private let cellContainer = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        // Контейнер для содержимого ячейки
        cellContainer.backgroundColor = AppColors.slate.withAlphaComponent(0.2)
        cellContainer.layer.cornerRadius = 12
        cellContainer.layer.borderWidth = 1
        cellContainer.layer.borderColor = AppColors.slate.withAlphaComponent(0.3).cgColor
        cellContainer.layer.shadowColor = AppColors.charcoal.cgColor
        cellContainer.layer.shadowOpacity = 0.2
        cellContainer.layer.shadowOffset = CGSize(width: 0, height: 2)
        cellContainer.layer.shadowRadius = 4
        contentView.addSubview(cellContainer)
        
        // Постер фильма
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.layer.cornerRadius = 8
        posterImageView.clipsToBounds = true
        cellContainer.addSubview(posterImageView)
        
        // Название фильма
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppColors.white
        titleLabel.numberOfLines = 2
        cellContainer.addSubview(titleLabel)
        
        // Рейтинг
        ratingLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        ratingLabel.textColor = .systemYellow
        cellContainer.addSubview(ratingLabel)
        
        // Иконка звезды
        starImageView.image = UIImage(systemName: "star.fill")
        starImageView.tintColor = .systemYellow
        cellContainer.addSubview(starImageView)
        
        // Констрейнты
        cellContainer.translatesAutoresizingMaskIntoConstraints = false
        posterImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        starImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cellContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            cellContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cellContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cellContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            posterImageView.leadingAnchor.constraint(equalTo: cellContainer.leadingAnchor, constant: 12),
            posterImageView.centerYAnchor.constraint(equalTo: cellContainer.centerYAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 60),
            posterImageView.heightAnchor.constraint(equalToConstant: 90),
            
            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: cellContainer.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: cellContainer.topAnchor, constant: 16),
            
            starImageView.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 16),
            starImageView.bottomAnchor.constraint(equalTo: cellContainer.bottomAnchor, constant: -16),
            starImageView.widthAnchor.constraint(equalToConstant: 16),
            starImageView.heightAnchor.constraint(equalToConstant: 16),
            
            ratingLabel.leadingAnchor.constraint(equalTo: starImageView.trailingAnchor, constant: 4),
            ratingLabel.centerYAnchor.constraint(equalTo: starImageView.centerYAnchor)
        ])
    }
    
    func configure(with movie: RatedMovie) {
        titleLabel.text = movie.title
        ratingLabel.text = "\(movie.rating)/10"
        
        if let posterPath = movie.posterPath {
            let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
            posterImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "movie_placeholder"))
        } else {
            posterImageView.image = UIImage(named: "movie_placeholder")
        }
    }
}
