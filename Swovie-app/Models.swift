import Foundation
import FirebaseCore
import UIKit
import FirebaseFirestore

struct Movie: Decodable, Identifiable {
    let adult: Bool
    let backdropPath: String?
    let genreIds: [Int]
    let id: Int
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let releaseDate: String
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int
    
    // Вычисляемое свойство для полного URL постера
    var posterURL: URL? {
        guard let posterPath = posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(posterPath)")
    }
    
    // Вычисляемое свойство для года выпуска
    var releaseYear: String {
        return String(releaseDate.prefix(4))
    }
    
    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case genreIds = "genre_ids"
        case id
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title
        case video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}

struct MovieResponse: Decodable {
    let page: Int
    let results: [Movie]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct MovieCollection {
    let id: String
    let name: String
    var movies: [RatedMovie]
}

struct User {
    let id: String
    let name: String
    var avatarName: UIColor
    var likedMovies: [Movie] = []
}

struct FirebaseRating: Codable {
    let userId: String
    let movieId: Int
    let movieTitle: String
    let stars: Int
    let review: String
    let timestamp: TimeInterval
    
    var dictionary: [String: Any] {
        return [
            "userId": userId,
            "movieId": movieId,
            "movieTitle": movieTitle,
            "stars": stars,
            "review": review,
            "timestamp": timestamp
        ]
    }
}

struct RatedMovie {
    let id: Int
    let title: String
    let rating: Int
    let posterPath: String?
    let timestamp: Date?
    
    init(id: Int, title: String, rating: Int, posterPath: String?, timestamp: Date? = nil) {
        self.id = id
        self.title = title
        self.rating = rating
        self.posterPath = posterPath
        self.timestamp = timestamp
    }
    
    init?(document: QueryDocumentSnapshot) {
        let data = document.data()
        guard let movieId = data["movieId"] as? Int,
              let title = data["title"] as? String,
              let rating = data["rating"] as? Int else {
            return nil
        }
        
        self.id = movieId
        self.title = title
        self.rating = rating
        self.posterPath = data["posterPath"] as? String
        if let timestamp = data["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue()
        } else {
            self.timestamp = nil
        }
    }
}
