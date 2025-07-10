//
//  RatingService.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 10.07.2025.
//

import Foundation
import FirebaseDatabase

class RatingService {
    static let shared = RatingService()
    private let databaseRef = Database.database().reference()
    
    func saveRating(rating: FirebaseRating, completion: @escaping (Error?) -> Void) {
        let ratingRef = databaseRef.child("ratings").childByAutoId()
        ratingRef.setValue(rating.dictionary) { error, _ in
            completion(error)
        }
    }
    
    func getUserRatings(userId: String, completion: @escaping ([FirebaseRating]) -> Void) {
        databaseRef.child("ratings")
            .queryOrdered(byChild: "userId")
            .queryEqual(toValue: userId)
            .observeSingleEvent(of: .value) { snapshot in
                var ratings = [FirebaseRating]()
                for child in snapshot.children {
                    if let snapshot = child as? DataSnapshot,
                       let dict = snapshot.value as? [String: Any],
                       let rating = FirebaseRating(from: dict) {
                        ratings.append(rating)
                    }
                }
                completion(ratings)
            }
    }
}

// Расширение для инициализации из словаря
extension FirebaseRating {
    init?(from dict: [String: Any]) {
        guard let userId = dict["userId"] as? String,
              let movieId = dict["movieId"] as? Int,
              let movieTitle = dict["movieTitle"] as? String,
              let stars = dict["stars"] as? Int,
              let review = dict["review"] as? String,
              let timestamp = dict["timestamp"] as? TimeInterval else { return nil }
        
        self.userId = userId
        self.movieId = movieId
        self.movieTitle = movieTitle
        self.stars = stars
        self.review = review
        self.timestamp = timestamp
    }
}
