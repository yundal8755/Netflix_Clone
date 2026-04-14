//
//  TMDBDTO.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation

struct TMDBMovieListResponseDTO: Decodable {
    let results: [TMDBMovieDTO]
}

struct TMDBMovieDTO: Decodable {
    let id: Int
    let title: String?
    let name: String?
    let posterPath: String?
    let overview: String?

    var displayTitle: String {
        title ?? name ?? "Untitled"
    }

    var posterImageURL: URL? {
        guard let posterPath, posterPath.isEmpty == false else { return nil }
        let normalizedPath = posterPath.hasPrefix("/") ? posterPath : "/\(posterPath)"
        return URL(string: "https://image.tmdb.org/t/p/w500\(normalizedPath)")
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case posterPath = "poster_path"
        case overview
    }
}
