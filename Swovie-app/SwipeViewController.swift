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

enum SwipeDirection {
    case left, right
}

class SwipeViewController: UIViewController {
    
    // MARK: - Properties
    private var movies: [Movie] = []
    private var currentIndex = 0
    private var currentCard: MovieCardView?
    private var nextCard: MovieCardView?
    private var isMatchFound = false
    
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
    
    // MARK: - UI Elements
    private let likeEmojiLabel = UILabel()
    private let dislikeEmojiLabel = UILabel()
    private let matchCardView = UIView()
    private let matchTitleLabel = UILabel()
    private let matchPosterImageView = UIImageView()
    private let matchCelebrationLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        if let groupId = groupId {
            setupMembersOverlay()
            setupGroupListeners(groupId: groupId)
            setupSwipesListener(groupId: groupId)
        } else {
            loadMovies()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Position emoji indicators
        likeEmojiLabel.center = CGPoint(x: view.bounds.width - 60, y: view.center.y)
        dislikeEmojiLabel.center = CGPoint(x: 60, y: view.center.y)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        // Setup emoji indicators
        likeEmojiLabel.text = "❤️🔥😍👍🥰"
        likeEmojiLabel.font = UIFont.systemFont(ofSize: 28)
        likeEmojiLabel.textAlignment = .center
        likeEmojiLabel.alpha = 0
        likeEmojiLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        view.addSubview(likeEmojiLabel)
        
        dislikeEmojiLabel.text = "💔👎😒🙅‍♂️❌"
        dislikeEmojiLabel.font = UIFont.systemFont(ofSize: 28)
        dislikeEmojiLabel.textAlignment = .center
        dislikeEmojiLabel.alpha = 0
        dislikeEmojiLabel.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        view.addSubview(dislikeEmojiLabel)
        
        // Setup match card view (hidden by default)
        setupMatchCardView()
        
        // Setup activity indicator
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Setup no movies label
        noMoviesLabel.text = "Нет фильмов для отображения"
        noMoviesLabel.textColor = .white
        noMoviesLabel.textAlignment = .center
        noMoviesLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
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
    
    private func setupMatchCardView() {
        matchCardView.backgroundColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        matchCardView.layer.cornerRadius = 20
        matchCardView.layer.masksToBounds = true
        matchCardView.isHidden = true
        matchCardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(matchCardView)
        
        matchTitleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        matchTitleLabel.textColor = .white
        matchTitleLabel.textAlignment = .center
        matchTitleLabel.numberOfLines = 0
        matchTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        matchCardView.addSubview(matchTitleLabel)
        
        matchPosterImageView.contentMode = .scaleAspectFill
        matchPosterImageView.layer.cornerRadius = 10
        matchPosterImageView.layer.masksToBounds = true
        matchPosterImageView.translatesAutoresizingMaskIntoConstraints = false
        matchCardView.addSubview(matchPosterImageView)
        
        matchCelebrationLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        matchCelebrationLabel.textColor = UIColor.systemGreen
        matchCelebrationLabel.text = "🎉 Мэтч! 🎉"
        matchCelebrationLabel.textAlignment = .center
        matchCelebrationLabel.translatesAutoresizingMaskIntoConstraints = false
        matchCardView.addSubview(matchCelebrationLabel)
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("Закрыть", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor.systemBlue
        closeButton.layer.cornerRadius = 10
        closeButton.addTarget(self, action: #selector(closeMatchCard), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        matchCardView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            matchCardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            matchCardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            matchCardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            matchCardView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.7),
            
            matchCelebrationLabel.topAnchor.constraint(equalTo: matchCardView.topAnchor, constant: 20),
            matchCelebrationLabel.leadingAnchor.constraint(equalTo: matchCardView.leadingAnchor, constant: 20),
            matchCelebrationLabel.trailingAnchor.constraint(equalTo: matchCardView.trailingAnchor, constant: -20),
            matchCelebrationLabel.heightAnchor.constraint(equalToConstant: 30),
            
            matchPosterImageView.topAnchor.constraint(equalTo: matchCelebrationLabel.bottomAnchor, constant: 20),
            matchPosterImageView.centerXAnchor.constraint(equalTo: matchCardView.centerXAnchor),
            matchPosterImageView.widthAnchor.constraint(equalTo: matchCardView.widthAnchor, multiplier: 0.8),
            matchPosterImageView.heightAnchor.constraint(equalTo: matchCardView.heightAnchor, multiplier: 0.6),
            
            matchTitleLabel.topAnchor.constraint(equalTo: matchPosterImageView.bottomAnchor, constant: 20),
            matchTitleLabel.leadingAnchor.constraint(equalTo: matchCardView.leadingAnchor, constant: 20),
            matchTitleLabel.trailingAnchor.constraint(equalTo: matchCardView.trailingAnchor, constant: -20),
            
            closeButton.bottomAnchor.constraint(equalTo: matchCardView.bottomAnchor, constant: -20),
            closeButton.centerXAnchor.constraint(equalTo: matchCardView.centerXAnchor),
            closeButton.widthAnchor.constraint(equalTo: matchCardView.widthAnchor, multiplier: 0.6),
            closeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupMembersOverlay() {
        membersOverlayView = UIView()
        membersOverlayView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 0.95)
        membersOverlayView.layer.cornerRadius = 20
        membersOverlayView.layer.masksToBounds = true
        membersOverlayView.isHidden = false
        membersOverlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "Групповой просмотр"
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        membersStatusLabel = UILabel()
        membersStatusLabel.textColor = .lightGray
        membersStatusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        membersStatusLabel.textAlignment = .center
        membersStatusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 15
        
        membersCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        membersCollectionView.backgroundColor = .clear
        membersCollectionView.showsHorizontalScrollIndicator = false
        membersCollectionView.register(MemberCell.self, forCellWithReuseIdentifier: "MemberCell")
        membersCollectionView.dataSource = self
        membersCollectionView.delegate = self
        membersCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        let waitingLabel = UILabel()
        waitingLabel.text = "Ожидаем всех участников..."
        waitingLabel.textColor = .lightGray
        waitingLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        waitingLabel.textAlignment = .center
        waitingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        membersOverlayView.addSubview(titleLabel)
        membersOverlayView.addSubview(membersStatusLabel)
        membersOverlayView.addSubview(membersCollectionView)
        membersOverlayView.addSubview(waitingLabel)
        view.addSubview(membersOverlayView)
        
        NSLayoutConstraint.activate([
            membersOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            membersOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            membersOverlayView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            membersOverlayView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),
            
            titleLabel.topAnchor.constraint(equalTo: membersOverlayView.topAnchor, constant: 25),
            titleLabel.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -20),
            
            membersStatusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            membersStatusLabel.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 20),
            membersStatusLabel.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -20),
            
            membersCollectionView.topAnchor.constraint(equalTo: membersStatusLabel.bottomAnchor, constant: 20),
            membersCollectionView.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 20),
            membersCollectionView.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -20),
            membersCollectionView.heightAnchor.constraint(equalToConstant: 120),
            
            waitingLabel.topAnchor.constraint(equalTo: membersCollectionView.bottomAnchor, constant: 20),
            waitingLabel.leadingAnchor.constraint(equalTo: membersOverlayView.leadingAnchor, constant: 20),
            waitingLabel.trailingAnchor.constraint(equalTo: membersOverlayView.trailingAnchor, constant: -20),
            waitingLabel.bottomAnchor.constraint(lessThanOrEqualTo: membersOverlayView.bottomAnchor, constant: -20)
        ])
        
        updateMembersStatus()
    }
    
    // MARK: - Actions
    @objc private func closeMatchCard() {
        matchCardView.isHidden = true
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: - Group Management
    private func updateMembersStatus() {
        membersStatusLabel.text = "Участников: \(groupMembers.count)/\(expectedMembersCount)"
        membersCollectionView.reloadData()
        
        if groupMembers.count >= expectedMembersCount {
            UIView.animate(withDuration: 0.3, animations: {
                self.membersOverlayView.alpha = 0
            }) { _ in
                self.membersOverlayView.isHidden = true
                self.loadMovies()
            }
        }
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
    
    private func checkForMatches() {
        guard let groupId = groupId, !isMatchFound else { return }
        
        for (movieId, userIds) in likedMovies {
            if userIds.count == groupMembers.count {
                isMatchFound = true
                showMatch(movieId: movieId)
                likedMovies.removeValue(forKey: movieId)
                deleteGroupAfterMatch(groupId: groupId, matchedMovieId: movieId)
                break
            }
        }
    }
    
    private func showMatch(movieId: Int) {
        guard let movie = movies.first(where: { $0.id == movieId }) else { return }
        
        // Hide all cards
        currentCard?.removeFromSuperview()
        nextCard?.removeFromSuperview()
        currentCard = nil
        nextCard = nil
        
        // Setup match card
        matchTitleLabel.text = movie.title
        if let posterPath = movie.posterPath {
            let posterUrl = URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
            matchPosterImageView.sd_setImage(with: posterUrl, placeholderImage: UIImage(named: "placeholder"))
        }
        
        // Show celebration
        matchCardView.isHidden = false
        matchCardView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: [], animations: {
            self.matchCardView.transform = .identity
        })
        
        // Disable swiping
        view.isUserInteractionEnabled = false
    }
    
    private func deleteGroupAfterMatch(groupId: String, matchedMovieId: Int) {
        let db = Firestore.firestore()
        
        let matchData: [String: Any] = [
            "groupId": groupId,
            "matchedMovieId": matchedMovieId,
            "members": groupMembers,
            "matchedAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("matchHistory").addDocument(data: matchData) { error in
            if let error = error {
                print("Ошибка сохранения истории мэтча:", error.localizedDescription)
            }
        }
        
        let batch = db.batch()
        let groupRef = db.collection("groups").document(groupId)
        batch.deleteDocument(groupRef)
        
        let swipesRef = db.collection("groupSwipes").whereField("groupId", isEqualTo: groupId)
        swipesRef.getDocuments { snapshot, _ in
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Ошибка удаления группы:", error.localizedDescription)
                }
            }
        }
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
                    self?.movies = Array(movies.prefix(250))
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
        guard !movies.isEmpty, !isMatchFound else {
            noMoviesLabel.text = "Нет фильмов для отображения"
            noMoviesLabel.isHidden = false
            return
        }
        
        noMoviesLabel.isHidden = true
        
        currentCard?.removeFromSuperview()
        nextCard?.removeFromSuperview()
        
        currentCard = createCard(for: movies[currentIndex])
        guard let currentCard = currentCard else { return }
        
        currentCard.transform = .identity
        currentCard.alpha = 1.0
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        currentCard.addGestureRecognizer(panGesture)
        currentCard.isUserInteractionEnabled = true
        
        view.addSubview(currentCard)
        
        if currentIndex + 1 < movies.count {
            nextCard = createCard(for: movies[currentIndex + 1])
            if let nextCard = nextCard {
                nextCard.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                nextCard.alpha = 1.0
                view.insertSubview(nextCard, belowSubview: currentCard)
            }
        }
    }
    
    private func createCard(for movie: Movie) -> MovieCardView {
        let card = MovieCardView()
        card.movie = movie
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        card.layer.cornerRadius = 20
        card.layer.masksToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.darkGray.cgColor
        
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
        guard let groupId = groupId, groupMembers.count >= expectedMembersCount, !isMatchFound,
              let card = gesture.view as? MovieCardView else {
            return
        }
        
        let translation = gesture.translation(in: view)
        card.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
        
        let rotationAngle = translation.x / view.bounds.width * 0.4
        card.transform = CGAffineTransform(rotationAngle: rotationAngle)
        
        // Update emoji indicators
        if translation.x > 0 {
            // Swiping right (like)
            card.layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.7).cgColor
            likeEmojiLabel.alpha = min(abs(translation.x) / 100, 0.8)
            dislikeEmojiLabel.alpha = 0
        } else {
            // Swiping left (dislike)
            card.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.7).cgColor
            dislikeEmojiLabel.alpha = min(abs(translation.x) / 100, 0.8)
            likeEmojiLabel.alpha = 0
        }
        
        if gesture.state == .ended {
            let velocity = gesture.velocity(in: view)
            let shouldDismiss = abs(translation.x) > 100 || abs(velocity.x) > 800
            
            if shouldDismiss {
                let direction: CGFloat = translation.x > 0 ? 1 : -1
                let isLiked = direction > 0
                
                if let movie = currentCard?.movie {
                    saveSwipe(movieId: movie.id, isLiked: isLiked, groupId: groupId)
                }
                
                UIView.animate(withDuration: 0.3, animations: {
                    card.center = CGPoint(
                        x: direction * self.view.bounds.width * 1.5,
                        y: card.center.y + (direction * 100)
                    )
                    self.likeEmojiLabel.alpha = 0
                    self.dislikeEmojiLabel.alpha = 0
                }) { _ in
                    card.removeFromSuperview()
                    self.cardSwiped(direction: direction > 0 ? .right : .left)
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    card.center = self.view.center
                    card.transform = .identity
                    card.layer.borderColor = UIColor.darkGray.cgColor
                    self.likeEmojiLabel.alpha = 0
                    self.dislikeEmojiLabel.alpha = 0
                }
            }
        }
    }
    
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
        
        currentCard?.removeFromSuperview()
        currentCard = nil
        
        currentIndex += 1
        
        if currentIndex < movies.count {
            currentCard = nextCard
            currentCard?.transform = .identity
            currentCard?.alpha = 1.0
            
            if let currentCard = currentCard {
                let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                currentCard.addGestureRecognizer(panGesture)
            }
            
            if currentIndex + 1 < movies.count {
                nextCard = createCard(for: movies[currentIndex + 1])
                nextCard?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                nextCard?.alpha = 1.0
                if let nextCard = nextCard, let currentCard = currentCard {
                    view.insertSubview(nextCard, belowSubview: currentCard)
                }
            } else {
                nextCard = nil
            }
        } else {
            currentCard = nil
            nextCard = nil
        }
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension SwipeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupMembers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberCell", for: indexPath) as! MemberCell
        let memberId = groupMembers[indexPath.item]
        cell.configure(with: String(memberId.prefix(1)), color: UIColor.random())
        return cell
    }
}

// MARK: - Member Cell
class MemberCell: UICollectionViewCell {
    private let avatarView = UIView()
    private let initialsLabel = UILabel()
    private let onlineIndicator = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        avatarView.layer.cornerRadius = 30
        avatarView.layer.masksToBounds = true
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.darkGray.cgColor
        
        initialsLabel.textAlignment = .center
        initialsLabel.textColor = .white
        initialsLabel.font = UIFont.boldSystemFont(ofSize: 20)
        
        onlineIndicator.backgroundColor = UIColor.systemGreen
        onlineIndicator.layer.cornerRadius = 5
        onlineIndicator.layer.masksToBounds = true
        onlineIndicator.layer.borderWidth = 1
        onlineIndicator.layer.borderColor = UIColor.white.cgColor
        
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(onlineIndicator)
        
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        onlineIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            
            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            onlineIndicator.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: -2),
            onlineIndicator.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: -2),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 10),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
    
    func configure(with initial: String, color: UIColor) {
        avatarView.backgroundColor = color
        initialsLabel.text = initial
    }
}

