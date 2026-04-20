//
//  TMDBService.swift
//  Netflix_Clone
//
//  Created by mac on 4/10/26.
//

import Foundation

protocol TMDBServiceType: Sendable {
    func requestPopular() async throws(RouterError) -> [TMDBMovieEntity]
    func requestTrending() async throws(RouterError) -> [TMDBMovieEntity]
    func requestAction() async throws(RouterError) -> [TMDBMovieEntity]
    func requestUpcoming() async throws(RouterError) -> [TMDBMovieEntity]
    func requestSearch(searchText: String) async throws(RouterError) -> [TMDBMovieEntity]
}

// MARK: INIT
final class TMDBService: TMDBServiceType {
    private let networkManager: NetworkManager
    private let tmdbMapper: TMDBMapperType

    init(
        networkManager: NetworkManager = NetworkManager(),
        tmdbMapper: TMDBMapperType = TMDBMapper()
    ) {
        self.networkManager = networkManager
        self.tmdbMapper = tmdbMapper
    }
}

// MARK: Logic
extension TMDBService {
    
    func requestPopular() async throws(RouterError) -> [TMDBMovieEntity] {
        try await requestMovies(router: .popular)
    }

    func requestTrending() async throws(RouterError) -> [TMDBMovieEntity] {
        try await requestMovies(router: .trending)
    }

    func requestAction() async throws(RouterError) -> [TMDBMovieEntity] {
        try await requestMovies(router: .action)
    }

    func requestUpcoming() async throws(RouterError) -> [TMDBMovieEntity] {
        try await requestMovies(router: .upcoming)
    }

    func requestSearch(searchText: String) async throws(RouterError) -> [TMDBMovieEntity] {
        try await requestMovies(router: .search(searchText: searchText))
    }
    
    private var hasTMDBAPIKey: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String else {
            return false
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && trimmed.contains("$(") == false
    }

    
    func requestMovies(router: TMDBRouter) async throws(RouterError) -> [TMDBMovieEntity] {
        guard hasTMDBAPIKey else { throw .missingAPIKey }

        let response = try await networkManager.requestNetwork(
            dto: MovieListResponseDTO.self,
            router: router
        )

        return tmdbMapper.map(response.results)
    }
}
