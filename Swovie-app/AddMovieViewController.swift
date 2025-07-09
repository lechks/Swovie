import UIKit

class AddMovieViewController: UIViewController {

    // UI Elements
    private let gradientLayer = CAGradientLayer()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Оцените фильм"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.2) // frosted glass look
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Placeholder icon
        imageView.image = UIImage(systemName: "film")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        imageView.contentMode = .center
        return imageView
    }()

    private let movieTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Название фильма"
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private var starButtons: [UIButton] = []
    private var currentRating: Int = 0
    private let starsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let commentTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = UIColor(red: 0.106, green: 0.384, blue: 0.757, alpha: 1.0) // #1B62C1 saturated blue
        textView.layer.cornerRadius = 15
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textColor = UIColor.lightGray
        textView.text = "Оцените фильм"
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить оценку", for: .normal)
        button.backgroundColor = UIColor(red: 0.106, green: 0.384, blue: 0.757, alpha: 1.0) // #1B62C1 saturated blue
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGradientBackground()
        setupUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    private func setupGradientBackground() {
        gradientLayer.colors = [
            UIColor(red: 0.106, green: 0.384, blue: 0.757, alpha: 1.0).cgColor, // #1B62C1
            UIColor(red: 0.635, green: 0.839, blue: 0.976, alpha: 1.0).cgColor  // #A2D6F9
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func setupUI() {
        // Title label
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Poster
        view.addSubview(posterImageView)
        NSLayoutConstraint.activate([
            posterImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            posterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            posterImageView.widthAnchor.constraint(equalToConstant: 220),
            posterImageView.heightAnchor.constraint(equalToConstant: 220)
        ])
        posterImageView.layer.shadowColor = UIColor.black.cgColor
        posterImageView.layer.shadowOpacity = 0.2
        posterImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        posterImageView.layer.shadowRadius = 6

        // Movie title label
        view.addSubview(movieTitleLabel)
        NSLayoutConstraint.activate([
            movieTitleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 16),
            movieTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Star buttons
        for i in 1...5 {
            let button = UIButton(type: .system)
            let starImage = UIImage(systemName: "star.fill")
            button.setImage(starImage, for: .normal)
            button.tintColor = UIColor.lightGray
            button.translatesAutoresizingMaskIntoConstraints = false
            button.widthAnchor.constraint(equalToConstant: 40).isActive = true
            button.heightAnchor.constraint(equalToConstant: 40).isActive = true
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            button.tag = i
            // Add subtle shadow for glow (will be updated in updateStars)
            button.layer.shadowColor = UIColor.yellow.cgColor
            button.layer.shadowRadius = 4
            button.layer.shadowOpacity = 0.0
            button.layer.shadowOffset = CGSize(width: 0, height: 0)
            starButtons.append(button)
            starsStackView.addArrangedSubview(button)
        }
        // Set up commentTextView delegate for placeholder behavior
        commentTextView.delegate = self
        view.addSubview(starsStackView)
        NSLayoutConstraint.activate([
            starsStackView.topAnchor.constraint(equalTo: movieTitleLabel.bottomAnchor, constant: 16),
            starsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        // Comment text view
        view.addSubview(commentTextView)
        NSLayoutConstraint.activate([
            commentTextView.topAnchor.constraint(equalTo: starsStackView.bottomAnchor, constant: 20),
            commentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            commentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            commentTextView.heightAnchor.constraint(equalToConstant: 100)
        ])
        commentTextView.layer.shadowColor = UIColor.black.cgColor
        commentTextView.layer.shadowOpacity = 0.1
        commentTextView.layer.shadowOffset = CGSize(width: 0, height: 3)
        commentTextView.layer.shadowRadius = 5

        // Save button
        view.addSubview(saveButton)
        NSLayoutConstraint.activate([
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        ])
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOpacity = 0.3
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 5)
        saveButton.layer.shadowRadius = 8
    }

    @objc private func starTapped(_ sender: UIButton) {
        currentRating = sender.tag
        updateStars()
        UIView.animate(withDuration: 0.2,
                       animations: { sender.transform = CGAffineTransform(scaleX: 1.3, y: 1.3) },
                       completion: { _ in
                           UIView.animate(withDuration: 0.2) {
                               sender.transform = .identity
                           }
                       })
    }

    private func updateStars() {
        for (index, button) in starButtons.enumerated() {
            if index < currentRating {
                button.tintColor = .systemYellow
                button.layer.shadowOpacity = 0.6
            } else {
                button.tintColor = .lightGray
                button.layer.shadowOpacity = 0.0
            }
        }
    }

}

// MARK: - UITextViewDelegate for placeholder behavior
extension AddMovieViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Оцените фильм" && textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = .white
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = "Оцените фильм"
            textView.textColor = .lightGray
        }
    }
}
