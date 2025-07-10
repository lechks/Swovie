import Foundation
import UIKit

class MovieDetailViewController: UIViewController {
    
    private let movie: Movie
    
    // Основные элементы
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let rateButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    
    // Декоративные элементы
    private let topRightCircle = UIView()
    private let bottomLeftCircle = UIView()
    private let gradientLayer = CAGradientLayer()
    
    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.charcoal
        title = movie.title
        setupBackground()
        setupViews()
    }
    
    private func setupBackground() {
        // Градиентный фон
        gradientLayer.colors = [
            AppColors.charcoal.cgColor,
            AppColors.slate.withAlphaComponent(0.2).cgColor,
            AppColors.charcoal.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Декоративные круги
        topRightCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        topRightCircle.layer.cornerRadius = 120
        view.insertSubview(topRightCircle, at: 0)
        
        bottomLeftCircle.backgroundColor = AppColors.slate.withAlphaComponent(0.1)
        bottomLeftCircle.layer.cornerRadius = 80
        view.insertSubview(bottomLeftCircle, at: 0)
    }
    
    private func setupViews() {
        // Настройка скроллвью
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Постер фильма
        posterImageView.sd_setImage(with: movie.posterURL)
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 12
        posterImageView.layer.masksToBounds = true
        
        // Заголовок
        titleLabel.text = movie.title
        titleLabel.font = .boldSystemFont(ofSize: 24)
        titleLabel.textColor = AppColors.white
        titleLabel.numberOfLines = 0
        
        // Информация о фильме
        let genres = movie.genreIds.prefix(2).compactMap { MovieService().genreName(for: $0) }.joined(separator: ", ")
        infoLabel.text = """
        🎬 \(genres), \(movie.releaseYear)
        ⭐️ Рейтинг: \(movie.voteAverage)/10
        
        \(movie.overview)
        """
        infoLabel.numberOfLines = 0
        infoLabel.textColor = AppColors.white
        infoLabel.font = .systemFont(ofSize: 16)
        
        // Кнопки
        configureButton(rateButton, title: "Оценить", color: AppColors.slate, action: #selector(rateTapped))
        configureButton(addButton, title: "Добавить в коллекцию", color: UIColor.systemTeal, action: #selector(addTapped))
        
        // Стек с контентом
        let stack = UIStackView(arrangedSubviews: [
            posterImageView,
            titleLabel,
            infoLabel,
            rateButton,
            addButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stack)
        
        // Констрейнты
        NSLayoutConstraint.activate([
            // Скроллвью
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Контент вью
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Стек
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            
            // Постер
            posterImageView.heightAnchor.constraint(equalToConstant: 300),
            
            // Кнопки
            rateButton.heightAnchor.constraint(equalToConstant: 50),
            addButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Декоративные круги
            topRightCircle.widthAnchor.constraint(equalToConstant: 240),
            topRightCircle.heightAnchor.constraint(equalToConstant: 240),
            topRightCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: -120),
            topRightCircle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            
            bottomLeftCircle.widthAnchor.constraint(equalToConstant: 160),
            bottomLeftCircle.heightAnchor.constraint(equalToConstant: 160),
            bottomLeftCircle.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 40),
            bottomLeftCircle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -40)
        ])
    }
    
    private func configureButton(_ button: UIButton, title: String, color: UIColor, action: Selector) {
        button.setTitle(title, for: .normal)
        button.backgroundColor = color
        button.setTitleColor(AppColors.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.layer.cornerRadius = 12
        button.layer.shadowColor = color.cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    @objc private func rateTapped() {
        let ratingVC = RatingViewController(movie: movie)
        navigationController?.pushViewController(ratingVC, animated: true)
    }
    
    @objc private func addTapped() {
        print("Добавить в коллекцию фильм \(movie.title)")
    }
}
