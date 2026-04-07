//
//  RequestDTO.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Alamofire
import Foundation

protocol RequestDTO: Encodable {
    func asParameters() throws -> Parameters
}

enum RequestDTOError: Error {
    case invalidJSONObject
}

extension RequestDTO {
    func asParameters() throws -> Parameters {
        let data = try JSONEncoder().encode(self)
        let object = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)

        guard let parameters = object as? Parameters else {
            throw RequestDTOError.invalidJSONObject
        }

        return parameters
    }
}
