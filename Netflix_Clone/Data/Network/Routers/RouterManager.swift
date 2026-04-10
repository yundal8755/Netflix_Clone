//
//  RouterManager.swift
//  Netflix_Clone
//
//  Created by mac on 4/10/26.
//

import Foundation
import Alamofire

protocol TMDBServiceType {
    func requestPopular() async throws(RouterError) -> [TMDBMovieDTO]
    func requestTrending() async throws(RouterError) -> [TMDBMovieDTO]
    func requestAction() async throws(RouterError) -> [TMDBMovieDTO]
    func requestUpcoming() async throws(RouterError) -> [TMDBMovieDTO]
}

final class TMDBService: Sendable, TMDBServiceType {
    private let routerManager: RouterManager

    init(routerManager: RouterManager = RouterManager()) {
        self.routerManager = routerManager
    }

    func requestPopular() async throws(RouterError) -> [TMDBMovieDTO] {
        try await requestMovies(router: .popular)
    }

    func requestTrending() async throws(RouterError) -> [TMDBMovieDTO] {
        try await requestMovies(router: .trending)
    }

    func requestAction() async throws(RouterError) -> [TMDBMovieDTO] {
        try await requestMovies(router: .action)
    }

    func requestUpcoming() async throws(RouterError) -> [TMDBMovieDTO] {
        try await requestMovies(router: .upcoming)
    }
}

private extension TMDBService {
    func requestMovies(router: TMDBRouter) async throws(RouterError) -> [TMDBMovieDTO] {
        guard hasTMDBAPIKey else { throw .missingAPIKey }

        let response = try await routerManager.requestNetwork(
            dto: TMDBMovieListResponseDTO.self,
            router: router
        )
        return response.results
    }

    private var hasTMDBAPIKey: Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String else {
            return false
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty == false && trimmed.contains("$(") == false
    }
}
