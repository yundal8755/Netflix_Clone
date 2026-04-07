//
//  TMDBEndpoint.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation

struct TMDBMovieRequestDTO: RequestDTO {
    let apiKey: String
    let language: String
    let page: Int
    let withGenres: String?
    let sortBy: String?

    init(apiKey: String, isActionRequest: Bool) {
        self.apiKey = apiKey
        self.language = "ko-KR"
        self.page = 1
        self.withGenres = isActionRequest ? "28" : nil
        self.sortBy = isActionRequest ? "popularity.desc" : nil
    }

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case language
        case page
        case withGenres = "with_genres"
        case sortBy = "sort_by"
    }
}

enum TMDBEndpoint {
    case popular
    case trending
    case action
    case upcoming

    private var path: String {
        switch self {
        case .popular:
            return "/3/movie/popular"
        case .trending:
            return "/3/trending/movie/day"
        case .action:
            return "/3/discover/movie"
        case .upcoming:
            return "/3/movie/upcoming"
        }
    }

    var sectionTitle: String {
        switch self {
        case .popular:
            return "Popular on Netflix"
        case .trending:
            return "Trending Now"
        case .action:
            return "Action"
        case .upcoming:
            return "New Releases"
        }
    }

    func requestDTO(apiKey: String) -> TMDBMovieRequestDTO {
        TMDBMovieRequestDTO(
            apiKey: apiKey,
            isActionRequest: self == .action
        )
    }

    var urlString: String {
        "https://api.themoviedb.org\(path)"
    }
}
