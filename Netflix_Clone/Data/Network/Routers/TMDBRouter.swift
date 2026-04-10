//
//  TMDBRouter.swift
//  Netflix_Clone
//
//  Created by mac on 4/10/26.
//

import Foundation
import Alamofire

enum TMDBRouter: TargetType {
    case popular
    case trending
    case action
    case upcoming
    case search(searchText: String)
}

extension TMDBRouter {
    
    var method: HTTPMethod {
        .get
    }
    
    var path: String {
        return switch self {
        case .popular:
            "/3/movie/popular"
        case .trending:
            "/3/trending/movie/day"
        case .action:
            "/3/discover/movie"
        case .upcoming:
            "/3/movie/upcoming"
        case .search:
            "/3/search/movie"
        }
    }
    
    var optionalHeaders: HTTPHeaders? {
        return nil
    }
    
    var parameters: Parameters? {
        var query = commonQuery

        switch self {
        case let .search(searchText):
            query["query"] = searchText
            return query
        case .action:
            query["with_genres"] = "28"
            query["sort_by"] = "popularity.desc"
            return query
        case .popular, .trending, .upcoming:
            return query
        }
    }
    
    var body: Data? {
        return nil
    }
    
    var encodingType: EncodingType {
        return .url
    }

    private var commonQuery: Parameters {
        var query: Parameters = [
            "language": "ko-KR",
            "page": 1
        ]

        if let key = Self.tmdbAPIKey {
            query["api_key"] = key
        }

        return query
    }

    private static var tmdbAPIKey: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        guard trimmed.contains("$(") == false else { return nil }
        return trimmed
    }
}
