import UIKit

class ProfileViewController: UIViewController {
    
    private var userId: String = "User123"
    private var collections: [MovieCollection] = [
        MovieCollection(name: "Любимые Sci-Fi", reviews: [
            MovieReview(movieId: "10", rating: 5, comment: "Великолепно!")
        ])
    ]
    
    private let scrollView = UIScrollView()
    private let contentView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Профиль"
        
        setupScrollView()
        setupProfileInfo()
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
        contentView.spacing = 16
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
    
    private func setupProfileInfo() {
        let idLabel = makeTitleLabel("ID: \(userId)")
        contentView.addArrangedSubview(idLabel)
        
        let collectionsTitle = makeTitleLabel("Мои коллекции")
        contentView.addArrangedSubview(collectionsTitle)
        
        for collection in collections {
            let button = UIButton(type: .system)
            button.setTitle("📁 \(collection.name) (\(collection.reviews.count))", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            button.contentHorizontalAlignment = .left
            button.addTarget(self, action: #selector(openCollection(_:)), for: .touchUpInside)
            // сохраним в tag индекс коллекции
            button.tag = collections.firstIndex(where: { $0.name == collection.name }) ?? 0
            contentView.addArrangedSubview(button)
        }
        
        let addCollectionButton = UIButton(type: .system)
        addCollectionButton.setTitle("➕ Добавить коллекцию", for: .normal)
        addCollectionButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        addCollectionButton.addTarget(self, action: #selector(addCollectionTapped), for: .touchUpInside)
        contentView.addArrangedSubview(addCollectionButton)
    }
    
    @objc private func openCollection(_ sender: UIButton) {
        let index = sender.tag
        let collection = collections[index]
        let detailVC = CollectionDetailViewController(collection: collection)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    @objc private func addCollectionTapped() {
        let alert = UIAlertController(title: "Новая коллекция", message: "Введите название коллекции", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Например: Фильмы для осени" }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Создать", style: .default, handler: { [weak self] _ in
            if let name = alert.textFields?.first?.text, !name.isEmpty {
                self?.collections.append(MovieCollection(name: name, reviews: []))
                self?.refreshProfile()
            }
        }))
        present(alert, animated: true)
    }
    
    private func refreshProfile() {
        contentView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        setupProfileInfo()
    }
    
    private func makeTitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.text = text
        label.numberOfLines = 0
        return label
    }
}
