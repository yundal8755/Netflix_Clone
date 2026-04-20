//
//  NetworkManager.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import Alamofire

final class NetworkManager: Sendable {
    
    // T: 어떤 모델로 디코딩할 것인가
    // R: 어떤 API 주소를 호출할 것인가
    func requestNetwork<T: Decodable, R: TargetType>(
        dto: T.Type,
        router: R
    ) async throws(RouterError) -> T {
        let request = try router.asURLRequest()
        let response = await performRequest(dtoType: dto, request: request)
        return try parseResponse(response)
    }
}

// MARK: Private
private extension NetworkManager {
    
    func performRequest<T: Decodable>(
        dtoType: T.Type,
        request: URLRequest
    ) async -> DataResponse<T, AFError> {
        await AF.request(request)
            .validate(statusCode: 200..<300)
            .serializingDecodable(dtoType)
            .response
    }

    func parseResponse<T: Decodable>(
        _ response: DataResponse<T, AFError>
    ) throws(RouterError) -> T {
        switch response.result {
        case .success(let data):
            return data
        case .failure(let error):
            if error.isExplicitlyCancelledError {
                throw .cancel
            }

            if error.isSessionTaskError,
               let underlyingError = error.underlyingError as NSError?,
               underlyingError.domain == NSURLErrorDomain,
               underlyingError.code == NSURLErrorTimedOut {
                throw .timeOut
            }

            throw .decodingFail
        }
    }
}
