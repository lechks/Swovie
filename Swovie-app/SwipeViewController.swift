//
//  SwipeViewController.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 07.07.2025.
//

import Foundation
import UIKit
import SDWebImage
import FirebaseFirestore
import FirebaseAuth

class SwipeViewController: UIViewController {
    
    // MARK: - Properties
    private var movies: [Movie] = []
    private var currentIndex = 0
    private var currentCard: MovieCardView?
    private var nextCard: MovieCardView?
    
    private let movieService = MovieService()
    private var isLoading = false
    
    var groupId: String?
    private var groupMembers: [String] = []
    private var likedMovies: [Int: Set<String>] = [:] // movieId: [userIds]
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let noMoviesLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // loadMovies()
        if let groupId = groupId {
            setupGroupListeners(groupId: groupId)
        } else {
            loadMovies()
        }
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
    
    private func setupGroupListeners(groupId: String) {
            let db = Firestore.firestore()
            
            // Слушаем изменения в группе
            db.collection("groups").document(groupId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let data = snapshot?.data(),
                          let members = data["memberIds"] as? [String] else { return }
                    
                    self?.groupMembers = members
                    self?.loadMovies()
                }
            
            // Слушаем свайпы участников группы
            db.collection("groupSwipes")
                .whereField("groupId", isEqualTo: groupId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let documents = snapshot?.documents else { return }
                    
                    var newLikedMovies: [Int: Set<String>] = [:]
                    
                    for doc in documents {
                        guard let movieId = doc.data()["movieId"] as? Int,
                              let userId = doc.data()["userId"] as? String,
                              let isLiked = doc.data()["isLiked"] as? Bool,
                              isLiked else { continue }
                        
                        if newLikedMovies[movieId] == nil {
                            newLikedMovies[movieId] = []
                        }
                        newLikedMovies[movieId]?.insert(userId)
                    }
                    
                    self?.likedMovies = newLikedMovies
                    self?.checkForMatches()
                }
        }
        
        // Добавьте этот метод для проверки мэтчей
        private func checkForMatches() {
            for (movieId, userIds) in likedMovies {
                // Проверяем, всем ли участникам понравился фильм
                if userIds.count == groupMembers.count {
                    showMatchPopup(movieId: movieId)
                    // Удаляем из отслеживания, чтобы не показывать повторно
                    likedMovies.removeValue(forKey: movieId)
                }
            }
        }
        
        // Добавьте этот метод для показа попапа мэтча
        private func showMatchPopup(movieId: Int) {
            guard let movie = movies.first(where: { $0.id == movieId }) else { return }
            
            let alert = UIAlertController(
                title: "Мэтч!",
                message: "Всем в группе понравился фильм \(movie.title)",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Круто!", style: .default))
            present(alert, animated: true)
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
        
        // Удаляем старые карточки
        currentCard?.removeFromSuperview()
        nextCard?.removeFromSuperview()
        
        // Создаем текущую карточку
        currentCard = createCard(for: movies[currentIndex])
        guard let currentCard = currentCard else { return }
        
        // Настраиваем внешний вид текущей карточки
        currentCard.transform = .identity
        currentCard.alpha = 1.0
        currentCard.backgroundColor = .black  // Или ваш цвет
        
        // Добавляем жест ДО добавления на экран
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        currentCard.addGestureRecognizer(panGesture)
        currentCard.isUserInteractionEnabled = true
        
        view.addSubview(currentCard)
        
        // Создаем следующую карточку (если есть)
        if currentIndex + 1 < movies.count {
            nextCard = createCard(for: movies[currentIndex + 1])
            if let nextCard = nextCard {
                nextCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                nextCard.alpha = 0.8
                view.insertSubview(nextCard, belowSubview: currentCard)
            }
        }
    }
    
    private func createCard(for movie: Movie) -> MovieCardView {
        let card = MovieCardView()
        card.movie = movie
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .black  // Или ваш цвет фона
        card.layer.cornerRadius = 15  // Пример скругления углов
        card.clipsToBounds = true
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
            let screenWidth = UIScreen.main.bounds.width
            
            if shouldDismiss {
                let direction: CGFloat = translation.x > 0 ? 1 : -1
                let isLiked = direction > 0
                
                // Сохраняем свайп в Firestore
                if let groupId = groupId, let movie = currentCard?.movie {
                    saveSwipe(movieId: movie.id, isLiked: isLiked, groupId: groupId)
                }
                
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
        
    // Mетод для сохранения свайпа
    private func saveSwipe(movieId: Int, isLiked: Bool, groupId: String) {
                guard let userId = Auth.auth().currentUser?.uid else { return }
                
                let db = Firestore.firestore()
                let swipeData: [String: Any] = [
                    "movieId": movieId,
                    "userId": userId,
                    "groupId": groupId,
                    "isLiked": isLiked,
                    "timestamp": Timestamp(date: Date())
                ]
                
                db.collection("groupSwipes").addDocument(data: swipeData)
    }
    
    private func cardSwiped(direction: SwipeDirection) {
        let movie = movies[currentIndex]
        print("User swiped \(direction) on \(movie.title)")
        
        // Удаляем текущую карточку
        currentCard?.removeFromSuperview()
        currentCard = nil
        
        // Переходим к следующему индексу
        currentIndex += 1
        
        if currentIndex < movies.count {
            // Делаем следующую карточку текущей
            currentCard = nextCard
            currentCard?.transform = .identity
            currentCard?.alpha = 1.0
            
            // Добавляем жест к новой текущей карточке
            if let currentCard = currentCard {
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                currentCard.addGestureRecognizer(panGesture)
            }
            
            // Создаем новую следующую карточку
            if currentIndex + 1 < movies.count {
                nextCard = createCard(for: movies[currentIndex + 1])
                nextCard?.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                nextCard?.alpha = 0.8
                if let nextCard = nextCard, let currentCard = currentCard {
                    view.insertSubview(nextCard, belowSubview: currentCard)
                }
            } else {
                nextCard = nil
            }
        } else {
            // Больше карточек нет
            currentCard = nil
            nextCard = nil
            // showNoMoreCards()
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
