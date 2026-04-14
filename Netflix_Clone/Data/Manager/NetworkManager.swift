//
//  NetworkManager.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import Alamofire

// Sendable
// 1. 보낼수있다.
// -> 다른 쓰레드간 송수신시 데이터 레이스가 일어나지 않음을 개발자가 보장하겠습니다.
final class NetworkManager: Sendable {
    
    func requestNetwork<T: Decodable, R: TargetType>(
        dto: T.Type,
        router: R
    ) async throws(RouterError) -> T {
        let request = try router.asURLRequest()
        let response = await performRequest(dtoType: dto, request: request)
        return try parseResponse(response)
    }
}

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
