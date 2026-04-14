//
//  TMDBMapper+PosterItem.swift
//  Netflix_Clone
//
//  Created by Codex on 4/14/26.
//

import Foundation

extension TMDBMapperType {
    func mapPosterItems(from movies: [TMDBMovieEntity]) -> [PosterItem] {
        movies.prefix(10).map { movie in
            PosterItem(
                movieID: movie.id,
                title: movie.title ?? movie.name ?? "Untitled",
                posterURL: mapPosterURL(from: movie.posterPath)
            )
        }
    }

    func mapPosterURL(from posterPath: String?) -> URL? {
        guard let posterPath, posterPath.isEmpty == false else { return nil }
        let normalizedPath = posterPath.hasPrefix("/") ? posterPath : "/\(posterPath)"
        return URL(string: "https://image.tmdb.org/t/p/w500\(normalizedPath)")
    }
}
