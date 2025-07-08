//
//  GroupSwipe.swift
//  Swovie-app
//
//  Created by Екактерина Максаева on 08.07.2025.
//

import Foundation
import FirebaseFirestore

struct GroupSwipe {
    let movieId: Int
    let userId: String
    let groupId: String
    let isLiked: Bool
    let timestamp: Date
    
    init?(document: [String: Any]) {
        guard let movieId = document["movieId"] as? Int,
              let userId = document["userId"] as? String,
              let groupId = document["groupId"] as? String,
              let isLiked = document["isLiked"] as? Bool,
              let timestamp = document["timestamp"] as? Timestamp else {
            return nil
        }
        
        self.movieId = movieId
        self.userId = userId
        self.groupId = groupId
        self.isLiked = isLiked
        self.timestamp = timestamp.dateValue()
    }
}
