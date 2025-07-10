//
//  MobileService.swift
//  Swovie-app
//
//  Created by Екатерина Максаева on 06.07.2025.
// Работа с api TDBM

import Foundation
class MovieService {
    private let apiKey = "c35f063711811e12589b4572ac12655f"
    private let baseURL = "https://api.themoviedb.org/3"
    
    // Кэш для жанров
    private var movieGenres: [Genre] = []
    private var tvGenres: [Genre] = []
    private var genresLoaded = false
    
    // Инициализатор с возможностью предзагрузки жанров
    init(preloadGenres: Bool = true) {
        if preloadGenres {
            loadAllGenres()
        }
    }
    
    // MARK: - Жанры
    
    // Загрузка всех жанров (фильмы и сериалы)
    private func loadAllGenres(completion: (() -> Void)? = nil) {
        let dispatchGroup = DispatchGroup()
        
        // Загрузка жанров фильмов
        dispatchGroup.enter()
        fetchMovieGenres { [weak self] result in
            if case .success(let genres) = result {
                self?.movieGenres = genres
            }
            dispatchGroup.leave()
        }
        
        // Загрузка жанров ТВ-шоу
        dispatchGroup.enter()
        fetchTVGenres { [weak self] result in
            if case .success(let genres) = result {
                self?.tvGenres = genres
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            self.genresLoaded = true
            completion?()
        }
    }
    
    // Получение названия жанра по ID для фильмов
    func genreName(for id: Int, mediaType: MediaType = .movie) -> String {
        let genres = mediaType == .movie ? movieGenres : tvGenres
        return genres.first { $0.id == id }?.name ?? "Неизвестный жанр"
    }
    
    // Получение ID жанра по названию для фильмов
    func genreId(for name: String, mediaType: MediaType = .movie) -> Int? {
        let genres = mediaType == .movie ? movieGenres : tvGenres
        return genres.first { $0.name.lowercased() == name.lowercased() }?.id
    }
    
    // Получение списка жанров для фильмов
    func getGenres(for ids: [Int], mediaType: MediaType = .movie) -> [String] {
        let genres = mediaType == .movie ? movieGenres : tvGenres
        return ids.compactMap { id in
            genres.first { $0.id == id }?.name
        }
    }
    
    // MARK: - Private Genre Methods
    
    private func fetchMovieGenres(completion: @escaping (Result<[Genre], Error>) -> Void) {
        let urlString = "\(baseURL)/genre/movie/list?api_key=\(apiKey)&language=ru-RU"
        fetchGenres(urlString: urlString, completion: completion)
    }
    
    private func fetchTVGenres(completion: @escaping (Result<[Genre], Error>) -> Void) {
        let urlString = "\(baseURL)/genre/tv/list?api_key=\(apiKey)&language=ru-RU"
        fetchGenres(urlString: urlString, completion: completion)
    }
    
    private func fetchGenres(urlString: String, completion: @escaping (Result<[Genre], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(GenreResponse.self, from: data)
                completion(.success(response.genres))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Остальные методы (из предыдущей реализации)
    
    func fetchTopMovies(totalMovies: Int = 250, completion: @escaping (Result<[Movie], Error>) -> Void) {
        let moviesPerPage = 20
        let totalPages = Int(ceil(Double(totalMovies) / Double(moviesPerPage)))
        
        var allMovies = [Movie]()
        let dispatchGroup = DispatchGroup()
        var lastError: Error?
        
        for page in 1...totalPages {
            dispatchGroup.enter()
            let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=ru-RU&page=\(page)"
            
            performRequest(urlString: urlString) { result in
                switch result {
                case .success(let movies):
                    allMovies.append(contentsOf: movies)
                case .failure(let error):
                    lastError = error
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                let result = Array(allMovies.prefix(totalMovies))
                completion(.success(result))
            }
        }
    }
    
    func fetchTopTVShows(totalShows: Int = 250, completion: @escaping (Result<[Movie], Error>) -> Void) {
        let showsPerPage = 20
        let totalPages = Int(ceil(Double(totalShows) / Double(showsPerPage)))
        
        var allShows = [Movie]()
        let dispatchGroup = DispatchGroup()
        var lastError: Error?
        
        for page in 1...totalPages {
            dispatchGroup.enter()
            let urlString = "\(baseURL)/tv/top_rated?api_key=\(apiKey)&language=ru-RU&page=\(page)"
            
            performRequest(urlString: urlString) { result in
                switch result {
                case .success(let shows):
                    allShows.append(contentsOf: shows)
                case .failure(let error):
                    lastError = error
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let error = lastError {
                completion(.failure(error))
            } else {
                let result = Array(allShows.prefix(totalShows))
                completion(.success(result))
            }
        }
    }
    
    private func performRequest(urlString: String, completion: @escaping (Result<[Movie], Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            
            do {
                let response = try JSONDecoder().decode(MovieResponse.self, from: data)
                completion(.success(response.results))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getRecommendations(basedOn likedMovies: [Movie], completion: @escaping (Result<[Movie], Error>) -> Void) {
        let likedGenres = Set(likedMovies.flatMap { $0.genreIds ?? [] })
        let likedKeywords = likedMovies.compactMap { $0.title.components(separatedBy: " ") }.flatMap { $0 }
        
        let urlString = "\(baseURL)/discover/movie?api_key=\(apiKey)&language=ru-RU&sort_by=popularity.desc&with_genres=\(likedGenres.prefix(3).map(String.init).joined(separator: ","))"
        
        performRequest(urlString: urlString, completion: completion)
    }
}

// MARK: - Вспомогательные структуры

struct GenreResponse: Codable {
    let genres: [Genre]
}

struct Genre: Codable {
    let id: Int
    let name: String
}

enum MediaType {
    case movie
    case tv
}
