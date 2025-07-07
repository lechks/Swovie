//
//  MovieCardView.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 06.07.2025.
//

import Foundation
import UIKit
import SDWebImage

class MovieCardView: UIView {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let yearLabel = UILabel()
    private let ratingLabel = UILabel()
    private let overviewLabel = UILabel()
    
    var movie: Movie? {
        didSet {
            configureWithMovie()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        layer.cornerRadius = 25
        layer.masksToBounds = true
        backgroundColor = .black
        
        // Настройка imageView
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        // Градиент для текста поверх изображения
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        gradientLayer.locations = [0.5, 1]
        imageView.layer.addSublayer(gradientLayer)
        
        // Настройка titleLabel
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        addSubview(titleLabel)
        
        // Настройка yearLabel и ratingLabel
        yearLabel.font = UIFont.systemFont(ofSize: 16)
        yearLabel.textColor = .lightGray
        addSubview(yearLabel)
        
        ratingLabel.font = UIFont.systemFont(ofSize: 16)
        ratingLabel.textColor = .systemYellow
        addSubview(ratingLabel)
        
        // Настройка overviewLabel
        overviewLabel.font = UIFont.systemFont(ofSize: 16)
        overviewLabel.textColor = .white
        overviewLabel.numberOfLines = 3
        addSubview(overviewLabel)
        
        // Констрейнты
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        yearLabel.translatesAutoresizingMaskIntoConstraints = false
        ratingLabel.translatesAutoresizingMaskIntoConstraints = false
        overviewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.7),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            yearLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            ratingLabel.centerYAnchor.constraint(equalTo: yearLabel.centerYAnchor),
            ratingLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            overviewLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 16),
            overviewLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            overviewLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            overviewLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
        
        // Обновляем frame градиента после layout
        DispatchQueue.main.async {
            gradientLayer.frame = self.imageView.bounds
        }
    }
    
    private func configureWithMovie() {
        guard let movie = movie else { return }
        
        titleLabel.text = movie.title
        yearLabel.text = movie.year
        ratingLabel.text = "★ \(String(format: "%.1f", movie.vote_average))"
        overviewLabel.text = movie.overview
        
        if let url = movie.posterURL {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
        } else {
            imageView.image = UIImage(systemName: "film.fill")?
                .withTintColor(.lightGray, renderingMode: .alwaysOriginal)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем frame градиента при изменении размера
        if let gradient = imageView.layer.sublayers?.first as? CAGradientLayer {
            gradient.frame = imageView.bounds
        }
    }
}
