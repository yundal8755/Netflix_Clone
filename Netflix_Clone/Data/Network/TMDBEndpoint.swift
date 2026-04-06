//
//  TMDBEndpoint.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Alamofire
import Foundation

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

    func parameters(apiKey: String) -> Parameters {
        var parameters: Parameters = [
            "api_key": apiKey,
            "language": "ko-KR",
            "page": 1
        ]

        if case .action = self {
            parameters["with_genres"] = "28"
            parameters["sort_by"] = "popularity.desc"
        }

        return parameters
    }

    var urlString: String {
        "https://api.themoviedb.org\(path)"
    }
}
