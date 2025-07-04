import UIKit

class MovieTableViewCell: UITableViewCell {
    
    private let posterView = UIView()
    private let titleLabel = UILabel()
    private let ratingLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        posterView.backgroundColor = .systemGray4
        posterView.layer.cornerRadius = 8
        posterView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(posterView)
        
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        ratingLabel.font = UIFont.systemFont(ofSize: 16)
        ratingLabel.textColor = .systemGray
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(ratingLabel)
        
        NSLayoutConstraint.activate([
            posterView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            posterView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            posterView.widthAnchor.constraint(equalToConstant: 60),
            posterView.heightAnchor.constraint(equalToConstant: 90),
            
            titleLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            ratingLabel.leadingAnchor.constraint(equalTo: posterView.trailingAnchor, constant: 16),
            ratingLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            ratingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with movie: Movie, rating: Int) {
        titleLabel.text = movie.title
        ratingLabel.text = "⭐️ \(rating)/5"
    }
}
