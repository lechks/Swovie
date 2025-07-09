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
    
    private var expectedMembersCount: Int = 2
    private var membersOverlayView: UIView!
    private var membersCollectionView: UICollectionView!
    private var membersStatusLabel: UILabel!
    private var groupListener: ListenerRegistration?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // loadMovies()
        if let groupId = groupId {
            setupMembersOverlay()
            setupGroupListeners(groupId: groupId)
        } else {
            loadMovies()
        }
    }
    
    private func setupMembersOverlay() {
        // Overlay View
        membersOverlayView = UIView()
        membersOverlayView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        membersOverlayView.layer.cornerRadius = 12
        membersOverlayView.isHidden = false
        membersOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        // Status Label
        membersStatusLabel = UILabel()
        membersStatusLabel.textColor = .white
        membersStatusLabel.font = UIFont.boldSystemFont(ofSize: 18)
        membersStatusLabel.textAlignment = .center
        membersStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Collection View Layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 80)
        layout.minimumInteritemSpacing = 10
        
        // Collection View
        membersCollectionView = UICollectionView(frame: .zero, collectionViewLayout:layout)
        membersCollectionView.backgroundColor = .clear
        membersCollectionView.showsHorizontalScrollIndicator = false
        membersCollectionView.register(MemberCell.self, forCellWithReuseIdentifier: "MemberCell")
        membersCollectionView.dataSource = self
        membersCollectionView.delegate = self
        membersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add Subviews
        membersOverlayView.addSubview(membersStatusLabel)
        membersOverlayView.addSubview(membersCollectionView)
        view.addSubview(membersOverlayView)
        
        // Constraints
        NSLayoutConstraint.activate([
            membersOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            membersOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            membersOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor,multiplier: 0.8),
            membersOverlayView.heightAnchor.constraint(equalToConstant: 200),
            
            membersStatusLabel.topAnchor.constraint(equalTo: membersOverlayView.topAnchor, constant: 16),
            membersStatusLabel.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 16),
            membersStatusLabel.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -16),
            membersStatusLabel.heightAnchor.constraint(equalToConstant: 24),
            
            membersCollectionView.topAnchor.constraint(equalTo: membersStatusLabel.bottomAnchor, constant: 16),
            membersCollectionView.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 16),
            membersCollectionView.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -16),
            membersCollectionView.bottomAnchor.constraint(equalTo: membersOverlayView.bottomAnchor, constant: -16)
        ])
        
        updateMembersStatus()
    }
    
    private func updateMembersStatus() {
        print("Обновление статуса участников: \(groupMembers.count)/\(expectedMembersCount)")
        
        membersStatusLabel.text = "Ожидание участников (\(groupMembers.count)/\(expectedMembersCount))"
        membersCollectionView.reloadData()
        
        if groupMembers.count >= expectedMembersCount {
            print("Все участники подключились, скрываем оверлей")
            
            UIView.animate(withDuration: 0.3, animations: {
                self.membersOverlayView.alpha = 0
            }) { _ in
                self.membersOverlayView.isHidden = true
                self.loadMovies()
            }
        } else {
            print("Ещё не все участники подключились")
            membersOverlayView.isHidden = false
            membersOverlayView.alpha = 1.0
        }
    }
    
    // MARK: - Helpers
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        let groupRef = db.collection("groups").document(groupId)
        
        groupListener = groupRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error listening to group: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data(),
                  let membersCount = data["membersCount"] as? Int,
                  let currentMembers = data["currentMembers"] as? [String: Bool] else {
                print("Group data not found")
                return
            }
            
            self.groupMembers = Array(currentMembers.keys)
            self.expectedMembersCount = membersCount
            self.updateMembersStatus()
            
            if self.groupMembers.count >= self.expectedMembersCount {
                self.loadMovies()
            }
        }
    }
    
    private func setupSwipesListener(groupId: String) {
            let db = Firestore.firestore()
            
            db.collection("groupSwipes")
                .whereField("groupId", isEqualTo: groupId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error listening to swipes: \(error.localizedDescription)")
                        return
                    }
                    
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
                    
                    self.likedMovies = newLikedMovies
                    self.checkForMatches()
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
            
            // Only setup cards if all members joined or it's not a group
            if groupId == nil || groupMembers.count >= expectedMembersCount {
                currentCard?.removeFromSuperview()
                nextCard?.removeFromSuperview()
                
                currentCard = createCard(for: movies[currentIndex])
                guard let currentCard = currentCard else { return }
                
                currentCard.transform = .identity
                currentCard.alpha = 1.0
                currentCard.backgroundColor = .black
                
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                currentCard.addGestureRecognizer(panGesture)
                currentCard.isUserInteractionEnabled = true
                
                view.addSubview(currentCard)
                
                if currentIndex + 1 < movies.count {
                    nextCard = createCard(for: movies[currentIndex + 1])
                    if let nextCard = nextCard {
                        nextCard.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        nextCard.alpha = 0.8
                        view.insertSubview(nextCard, belowSubview: currentCard)
                    }
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
            // Don't allow swiping if not all members joined
            if let groupId = groupId, groupMembers.count < expectedMembersCount {
                showAlert(title: "Ожидание", message: "Еще не все участники подключились к группе")
                return
            }
            
            // Rest of the handlePan implementation remains the same
            guard let card = gesture.view as? MovieCardView else { return }
            
            let translation = gesture.translation(in: view)
            card.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
            
            let rotationAngle = translation.x / view.bounds.width * 0.4
            card.transform = CGAffineTransform(rotationAngle: rotationAngle)
            
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

// MARK: - UICollectionView DataSource & Delegate
extension SwipeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let memberId = groupMembers[indexPath.item]
        // Here you should fetch user data based on memberId
        // For now we'll just show the first letter of the ID
        cell.configure(with: String(memberId.prefix(1)), color: UIColor.random())
        return cell
    }
}

// MARK: - Member Cell
class MemberCell: UICollectionViewCell {
    private let avatarView = UIView()
    private let initialsLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        avatarView.layer.cornerRadius = 25
        avatarView.clipsToBounds = true
        
        initialsLabel.textAlignment = .center
        initialsLabel.textColor = .white
        initialsLabel.font = UIFont.boldSystemFont(ofSize: 16)
        
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 50),
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
    }
    
    func configure(with initial: String, color: UIColor) {
        avatarView.backgroundColor = color
        initialsLabel.text = initial
    }
}
