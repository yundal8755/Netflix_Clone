//
//  TMDBMoveRequestDTO.swift
//  Netflix_Clone
//
//  Created by mac on 4/14/26.
//

import Foundation

struct MovieRequestDTO: RequestDTO {
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
