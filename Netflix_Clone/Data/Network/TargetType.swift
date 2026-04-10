//
//  TargetType.swift
//  Netflix_Clone
//
//  Created by mac on 4/10/26.
//

import Foundation
import Alamofire

public enum RouterError: Error {
    case urlFail(url: String = "")
    case decodingFail
    case encodingFail
    case retryFail
    case timeOut
    case missingAPIKey
    case unknown(errorCode: String)
    case cancel
    case errorModelDecodingFail
    case refreshFailGoRoot
}

extension RouterError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .urlFail(let url):
            return "유효하지 않은 URL입니다: \(url)"
        case .decodingFail:
            return "응답 디코딩에 실패했습니다."
        case .encodingFail:
            return "요청 인코딩에 실패했습니다."
        case .retryFail:
            return "재시도에 실패했습니다."
        case .timeOut:
            return "요청 시간이 초과되었습니다."
        case .missingAPIKey:
            return "`TMDBAPIKey` 설정값을 찾을 수 없습니다."
        case .unknown(let errorCode):
            return "알 수 없는 오류가 발생했습니다. (\(errorCode))"
        case .cancel:
            return "요청이 취소되었습니다."
        case .errorModelDecodingFail:
            return "에러 모델 디코딩에 실패했습니다."
        case .refreshFailGoRoot:
            return "인증 갱신에 실패했습니다."
        }
    }
}

public enum EncodingType {
    case url
    case json
}

public protocol TargetType {
    
    var method: HTTPMethod { get }
    
    var baseURL: String { get }
    
    var path: String { get }
    
    var optionalHeaders: HTTPHeaders? { get } // secretHeader 말고도 추가적인 헤더가 필요시
    
    var headers: HTTPHeaders { get } // 다 합쳐진 헤더
    
    var parameters: Parameters? { get }
    
    var body: Data? { get }
    
    var encodingType: EncodingType { get }
}

extension TargetType {
    
    public var baseURL: String {
        #if DEBUG
        return "https://api.themoviedb.org"
        #else
        return "https://api.themoviedb.org"
        #endif
    }
    
    public var headers: HTTPHeaders {
        var combine = HTTPHeaders()
        if let optionalHeaders {
            optionalHeaders.forEach { header in
                combine.add(header)
            }
        }
        return combine
    }
    
    public func asURLRequest() throws(RouterError) -> URLRequest {
        let url = try baseURLToURL()
        
        var urlRequest = try urlToURLRequest(url: url)
        
        switch encodingType {
        case .url:
            do {
                urlRequest = try URLEncoding.queryString.encode(urlRequest, with: parameters)
                return urlRequest
            } catch {
                throw .encodingFail
            }
        case .json:
            do {
                if let body {
                    urlRequest.httpBody = body
                    if urlRequest.allHTTPHeaderFields?["Content-Type"] == nil {
                        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    }
                } else {
                    let request = try JSONEncoding.default.encode(urlRequest, withJSONObject: parameters)
                    print(parameters ?? "")
                    urlRequest = request
                }
                return urlRequest
            } catch {
                throw .decodingFail
            }
        }
    }
    
    private func baseURLToURL() throws(RouterError) -> URL {
        do {
            let url = try baseURL.asURL()
            return url
        } catch let error as AFError {
            if case .invalidURL = error {
                throw .urlFail(url: baseURL)
            } else {
                throw .unknown(errorCode: "baseURLToURL")
            }
        } catch {
            throw .unknown(errorCode: "baseURLToURL")
        }
    }
    
    private func urlToURLRequest(url: URL) throws(RouterError) -> URLRequest {
        do {
            let urlRequest = try URLRequest(url: url.appending(path: path), method: method, headers: headers)
            
            return urlRequest
        } catch let error as AFError {
            if case .invalidURL = error {
                throw .urlFail(url: baseURL)
            } else {
                throw .unknown(errorCode: "urlToURLRequest")
            }
        } catch {
            throw .unknown(errorCode: "urlToURLRequest")
        }
    }

    public func requestToBody(_ request: Encodable) -> Data? {
        do {
            return try CodableManager.shared.jsonEncoding(from: request)
        } catch {
            #if DEBUG
            print("requestToBody Error")
            #endif
            return nil
        }
    }
}
