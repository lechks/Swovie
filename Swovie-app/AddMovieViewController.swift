import UIKit

class AddMovieViewController: UIViewController {
    
    var onSave: ((String, Int, String) -> Void)?
    
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    private let titleField = UITextField()
    private let genreField = UITextField()
    private let yearField = UITextField()
    private let directorField = UITextField()
    private let commentField = UITextField()
    
    private var selectedRating: Int = 0
    private var starButtons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Добавить фильм"
        
        setupScrollView()
        setupFields()
        setupStars()
        setupSaveButton()
    }
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.axis = .vertical
        contentView.spacing = 16
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func createTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.translatesAutoresizingMaskIntoConstraints = false
        field.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return field
    }
    
    private func setupFields() {
        titleField.placeholder = "Название фильма"
        genreField.placeholder = "Жанр"
        yearField.placeholder = "Год"
        directorField.placeholder = "Режиссер"
        commentField.placeholder = "Комментарий"
        
        [titleField, genreField, yearField, directorField, commentField].forEach {
            $0.borderStyle = .roundedRect
            contentView.addArrangedSubview($0)
        }
    }
    
    private func setupStars() {
        let starsStack = UIStackView()
        starsStack.axis = .horizontal
        starsStack.spacing = 8
        starsStack.distribution = .fillEqually
        starsStack.translatesAutoresizingMaskIntoConstraints = false
        
        for i in 1...5 {
            let button = UIButton(type: .system)
            button.tag = i
            button.setTitle("☆", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 32)
            button.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            starsStack.addArrangedSubview(button)
            starButtons.append(button)
        }
        
        contentView.addArrangedSubview(starsStack)
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        selectedRating = sender.tag
        updateStarAppearance()
    }
    
    private func updateStarAppearance() {
        for button in starButtons {
            if button.tag <= selectedRating {
                button.setTitle("★", for: .normal)
            } else {
                button.setTitle("☆", for: .normal)
            }
        }
    }
    
    private func setupSaveButton() {
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        contentView.addArrangedSubview(saveButton)
    }
    
    @objc private func saveTapped() {
        guard let title = titleField.text, !title.isEmpty,
              let genre = genreField.text, !genre.isEmpty,
              let yearText = yearField.text, let year = Int(yearText),
              let director = directorField.text, !director.isEmpty,
              selectedRating > 0
        else {
            let alert = UIAlertController(title: "Ошибка", message: "Пожалуйста заполните все поля и выберите рейтинг", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let comment = commentField.text ?? ""
        let movie = MovieReview(movieId: "", rating: selectedRating, comment: comment)
        
        onSave?("", selectedRating, comment)
        navigationController?.popViewController(animated: true)
    }
}
