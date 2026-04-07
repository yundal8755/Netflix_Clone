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
    case invalidRequestParameters

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "`Netflix_Clone/Configs/Base.xcconfig`의 `TMDB_API_KEY`를 설정해 주세요."
        case .invalidRequestParameters:
            return "요청 파라미터 인코딩에 실패했습니다."
        }
    }
}

protocol JSONDecoderManagerType {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

final class JSONDecoderManager: JSONDecoderManagerType {
    static let shared = JSONDecoderManager()

    private let decoder: JSONDecoder
    private let lock = NSLock()

    private init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        lock.lock()
        defer { lock.unlock() }
        return try decoder.decode(type, from: data)
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
    private let decoderManager: JSONDecoderManagerType

    init(
        session: Session = .default,
        bundle: Bundle = .main,
        decoderManager: JSONDecoderManagerType = JSONDecoderManager.shared
    ) {
        self.session = session
        self.bundle = bundle
        self.decoderManager = decoderManager
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
        guard let apiKey = tmdbAPIKey else {
            return .error(NetworkError.missingAPIKey)
        }

        let parameters: Parameters
        do {
            parameters = try endpoint.requestDTO(apiKey: apiKey).asParameters()
        } catch {
            return .error(NetworkError.invalidRequestParameters)
        }

        return Single.create { [session, decoderManager] single in
            let request = session.request(
                endpoint.urlString,
                method: .get,
                parameters: parameters
            )
            .validate(statusCode: 200 ..< 300)
            .responseData(queue: .main) { response in
                switch response.result {
                case .success(let data):
                    do {
                        let decodedResponse = try decoderManager.decode(
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

    private var tmdbAPIKey: String? {
        guard let key = bundle.object(forInfoDictionaryKey: "TMDBAPIKey") as? String else {
            return nil
        }

        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedKey.isEmpty == false else { return nil }
        guard trimmedKey.contains("$(") == false else { return nil }
        return trimmedKey
    }
}
