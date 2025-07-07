import Foundation
import UIKit

struct MovieResponse: Decodable {
    let results: [Movie]
    let total_pages: Int
    let total_results: Int
}

struct Movie: Decodable {
    let id: Int
    let title: String
    let genre: String
    let overview: String
    let poster_path: String?
    let vote_average: Double
    let rating: Double
    let release_date: String?
    
    var posterURL: URL? {
        guard let path = poster_path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
    
    var year: String {
        guard let date = release_date else { return "N/A" }
        return String(date.prefix(4))
    }
}
struct MovieReview {
    let movieId: String
    let rating: Int
    let comment: String
}

struct MovieCollection {
    let name: String
    var reviews: [MovieReview]
}

struct User {
    let id: String
    let name: String
    var avatarName: UIColor
    var likedMovies: [Movie] = []
}
