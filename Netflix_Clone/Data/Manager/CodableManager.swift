//
//  CodableManager.swift
//  Netflix_Clone
//
//  Created by mac on 4/10/26.
//

import Foundation

public final class CodableManager: Sendable {
    
    public static let shared = CodableManager()
    
    private init () {}
    
    private let encoder = JSONEncoder()
    private let strategy = JSONEncoder()
    private let decoder = JSONDecoder()
}

extension CodableManager {
    
    public func jsonEncoding<T: Encodable>(from value: T) throws -> Data {
        return try encoder.encode(value)
    }
    
    public func jsonEncodingStrategy(_ target: Encodable) throws -> Data? {
        strategy.keyEncodingStrategy = .useDefaultKeys
        return try encoder.encode(target)
    }
    
    public func jsonDecoding<T:Decodable>(model: T.Type, from data: Data) throws -> T {
        return try decoder.decode(T.self, from: data)
    }
    
    public func toJSONSerialization(data: Data?) -> Any? {
        do {
            guard let data else {
                return nil
            }
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            return nil
        }
    }
}
