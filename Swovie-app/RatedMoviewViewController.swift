//
//  RatedMoviewViewController.swift
//  Swovie-app
//
//  Created by Екактерина Максаева on 10.07.2025.
//

import Foundation
import UIKit
class RatedMoviesViewController: UIViewController {
    private let collection: MovieCollection
    private let tableView = UITableView()
    
    init(collection: MovieCollection) {
        self.collection = collection
        super.init(nibName: nil, bundle: nil)
        title = collection.name
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.register(RatedMovieCell.self, forCellReuseIdentifier: "RatedMovieCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.frame = view.bounds
    }
}

extension RatedMoviesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collection.movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RatedMovieCell", for: indexPath) as! RatedMovieCell
        let movie = collection.movies[indexPath.row]
        cell.configure(with: movie)
        return cell
    }
}

class RatedMovieCell: UITableViewCell {
    func configure(with movie: RatedMovie) {
        // Настройка ячейки
        textLabel?.text = movie.title
        detailTextLabel?.text = "Оценка: \(movie.rating)/10"
        
        if let posterPath = movie.posterPath {
            let url = URL(string: "https://image.tmdb.org/t/p/w200\(posterPath)")
            imageView?.sd_setImage(with: url)
        }
    }
}
