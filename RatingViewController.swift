import UIKit

class RatingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Оценка фильмов"

        let label = UILabel()
        label.text = "Тут пользователь сможет оценивать фильмы"
        label.textAlignment = .center
        label.numberOfLines = 0

        view.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
