//
//  NetworkManager.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Alamofire
import Foundation
import RxSwift

enum NetworkError: LocalizedError {
    case missingAPIKey

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Info.plist에 `TMDBAPIKey`를 설정해 주세요."
        }
    }
}

protocol NetworkManagerType {
    func fetchPopularMovies() -> Single<[TMDBMovieDTO]>
    func fetchTrendingMovies() -> Single<[TMDBMovieDTO]>
    func fetchActionMovies() -> Single<[TMDBMovieDTO]>
    func fetchUpcomingMovies() -> Single<[TMDBMovieDTO]>
}

final class NetworkManager: NetworkManagerType {
    private let session: Session
    private let bundle: Bundle

    init(
        session: Session = .default,
        bundle: Bundle = .main
    ) {
        self.session = session
        self.bundle = bundle
    }

    func fetchPopularMovies() -> Single<[TMDBMovieDTO]> {
        requestMovies(endpoint: .popular)
    }

    func fetchTrendingMovies() -> Single<[TMDBMovieDTO]> {
        requestMovies(endpoint: .trending)
    }

    func fetchActionMovies() -> Single<[TMDBMovieDTO]> {
        requestMovies(endpoint: .action)
    }

    func fetchUpcomingMovies() -> Single<[TMDBMovieDTO]> {
        requestMovies(endpoint: .upcoming)
    }

    private func requestMovies(endpoint: TMDBEndpoint) -> Single<[TMDBMovieDTO]> {
        guard let apiKey = bundle.object(forInfoDictionaryKey: "TMDBAPIKey") as? String,
              apiKey.isEmpty == false else {
            return .error(NetworkError.missingAPIKey)
        }

        return Single.create { [session] single in
            let request = session.request(
                endpoint.urlString,
                method: .get,
                parameters: endpoint.parameters(apiKey: apiKey)
            )
            .validate(statusCode: 200 ..< 300)
            .responseData(queue: .global(qos: .userInitiated)) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decodedResponse = try JSONDecoder().decode(
                            TMDBMovieListResponseDTO.self,
                            from: data
                        )
                        single(.success(decodedResponse.results))
                    } catch {
                        single(.failure(error))
                    }
                case .failure(let error):
                    single(.failure(error))
                }
            }

            return Disposables.create {
                request.cancel()
            }
        }
    }
}
