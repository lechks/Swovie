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
    
    func fetchTopMovies(completion: @escaping (Result<[Movie], Error>) -> Void) {
        let urlString = "\(baseURL)/movie/top_rated?api_key=\(apiKey)&language=ru-RU&page=1"
        performRequest(urlString: urlString, completion: completion)
    }
    
    func fetchTopTVShowsm(completion: @escaping (Result<[Movie], Error>) -> Void) {
        let urlString = "\(baseURL)/tv/top_rated?api_key=\(apiKey)&language=ru-RU&page=1"
        performRequest(urlString: urlString, completion: completion)
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
}
