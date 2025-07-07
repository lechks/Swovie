//
//  SwipeViewController.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 07.07.2025.
//

import Foundation
import UIKit
import SDWebImage

class SwipeViewController: UIViewController {
    
    // MARK: - Properties
    private var movies: [Movie] = []
    private var currentIndex = 0
    private var currentCard: MovieCardView?
    private var nextCard: MovieCardView?
    
    private let movieService = MovieService()
    private var isLoading = false
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let noMoviesLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMovies()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Топ фильмы"
        
        // Activity Indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // No Movies Label
        noMoviesLabel.text = "Нет фильмов для отображения"
        noMoviesLabel.textAlignment = .center
        noMoviesLabel.isHidden = true
        noMoviesLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noMoviesLabel)
        NSLayoutConstraint.activate([
            noMoviesLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noMoviesLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            noMoviesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            noMoviesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Data Loading
    private func loadMovies() {
        guard !isLoading else { return }
        
        isLoading = true
        activityIndicator.startAnimating()
        noMoviesLabel.isHidden = true
        
        movieService.fetchTopMovies { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let movies):
                    self?.movies = Array(movies.prefix(250)) // Берем первые 250 фильмов
                    self?.setupCards()
                case .failure(let error):
                    self?.noMoviesLabel.text = "Ошибка загрузки: \(error.localizedDescription)"
                    self?.noMoviesLabel.isHidden = false
                }
            }
        }
    }
    
    // MARK: - Card Setup
    private func setupCards() {
        guard !movies.isEmpty else {
            noMoviesLabel.text = "Нет фильмов для отображения"
            noMoviesLabel.isHidden = false
            return
        }
        
        noMoviesLabel.isHidden = true
        
        // Создаем текущую карточку
        currentCard = createCard(for: movies[currentIndex])
        guard let currentCard = currentCard else { return }
        
        // Добавляем жесты
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        currentCard.addGestureRecognizer(panGesture)
        
        // Создаем следующую карточку (если есть)
        if currentIndex + 1 < movies.count {
            nextCard = createCard(for: movies[currentIndex + 1])
            nextCard?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            nextCard?.alpha = 0.8
        }
    }
    
    private func createCard(for movie: Movie) -> MovieCardView {
        let card = MovieCardView()
        card.movie = movie
        card.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(card)
        
        NSLayoutConstraint.activate([
            card.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            card.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        view.layoutIfNeeded()
        return card
    }
    
    // MARK: - Gesture Handling
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let card = gesture.view as? MovieCardView else { return }
        
        let translation = gesture.translation(in: view)
        card.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        
        let rotationAngle = translation.x / view.bounds.width * 0.4
        card.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        // Изменение цвета в зависимости от направления
        if translation.x > 0 {
            card.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.2)
        } else {
            card.backgroundColor = UIColor.systemRed.withAlphaComponent(0.2)
        }
        
        if gesture.state == .ended {
            let velocity = gesture.velocity(in: view)
            let shouldDismiss = abs(translation.x) > 100 || abs(velocity.x) > 800
            
            if shouldDismiss {
                let direction: CGFloat = translation.x > 0 ? 1 : -1
                let screenWidth = UIScreen.main.bounds.width
                
                UIView.animate(withDuration: 0.3, animations: {
                    card.center = CGPoint(
                        x: direction * screenWidth * 1.5,
                        y: card.center.y + (direction * 100)
                    )
                }) { _ in
                    card.removeFromSuperview()
                    self.cardSwiped(direction: direction > 0 ? .right : .left)
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    card.center = self.view.center
                    card.transform = .identity
                    card.backgroundColor = .black
                }
            }
        }
    }
    
    private func cardSwiped(direction: SwipeDirection) {
        // Сохраняем выбор пользователя
        let movie = movies[currentIndex]
        print("User swiped \(direction) on \(movie.title)")
        
        // Переходим к следующей карточке
        currentIndex += 1
        
        if let nextCard = nextCard {
            // Анимируем следующую карточку на место текущей
            UIView.animate(withDuration: 0.3) {
                nextCard.transform = .identity
                nextCard.alpha = 1
            }
            
            // Устанавливаем новую следующую карточку (если есть)
            self.currentCard = nextCard
            if currentIndex + 1 < movies.count {
                self.nextCard = createCard(for: movies[currentIndex + 1])
                self.nextCard?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.nextCard?.alpha = 0.8
            } else {
                self.nextCard = nil
            }
            
            // Добавляем жесты к новой текущей карточке
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            nextCard.addGestureRecognizer(panGesture)
        } else {
            // Больше карточек нет
            currentCard = nil
            noMoviesLabel.isHidden = false
            noMoviesLabel.text = "Вы просмотрели все фильмы"
            
            // Можно добавить кнопку для сброса
            let resetButton = UIButton(type: .system)
            resetButton.setTitle("Начать заново", for: .normal)
            resetButton.addTarget(self, action: #selector(resetCards), for: .touchUpInside)
            resetButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(resetButton)
            
            NSLayoutConstraint.activate([
                resetButton.topAnchor.constraint(equalTo: noMoviesLabel.bottomAnchor, constant: 20),
                resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
    }
    
    @objc private func resetCards() {
        currentIndex = 0
        noMoviesLabel.isHidden = true
        view.subviews.forEach { view in
            if view is UIButton {
                view.removeFromSuperview()
            }
        }
        setupCards()
    }
}

enum SwipeDirection {
    case left, right
}
