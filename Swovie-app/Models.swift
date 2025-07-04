import Foundation
import UIKit

struct Movie {
    let id: String
    let title: String
    let genre: String
    let year: Int
    let director: String
    let rating: Double
    let posterName: String // название изображения в ассетах
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
    let avatarName: UIColor
    var likedMovies: [Movie] = []
}
