import UIKit

class MovieDetailViewController: UIViewController {

    private let movie: Movie

    private let posterImageView = UIImageView()
    private let titleLabel = UILabel()
    private let infoLabel = UILabel()
    private let rateButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)

    init(movie: Movie) {
        self.movie = movie
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = movie.title
        setupViews()
    }

    private func setupViews() {
        posterImageView.image = UIImage(named: movie.poster_path!)
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.heightAnchor.constraint(equalToConstant: 300).isActive = true

        titleLabel.text = movie.title
        titleLabel.font = .boldSystemFont(ofSize: 22)

        infoLabel.text = "🎬 \(movie.genre), \(movie.year)\n🎬 Обзор фильма: \(movie.overview)\n⭐️ Рейтинг: \(movie.vote_average)"
        infoLabel.numberOfLines = 0

        rateButton.setTitle("Оценить", for: .normal)
        rateButton.addTarget(self, action: #selector(rateTapped), for: .touchUpInside)

        addButton.setTitle("Добавить в коллекцию", for: .normal)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [posterImageView, titleLabel, infoLabel, rateButton, addButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    @objc private func rateTapped() {
        print("Оценить фильм \(movie.title)")
        // Здесь можешь вызывать свой RatingViewController
    }

    @objc private func addTapped() {
        print("Добавить в коллекцию фильм \(movie.title)")
    }
}
