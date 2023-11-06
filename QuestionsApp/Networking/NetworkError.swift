//
//  NetworkError.swift
//  QuestionsApp
//
//  Created by Aleksey Gorbachevskiy on 6.11.23.
//

import Foundation

public enum NetworkError: Error {
    case error(Int)
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .error(let statusCode):
            let errorMessage: String = HTTPURLResponse.localizedString(forStatusCode: statusCode)
            return NSLocalizedString(errorMessage, comment: "")
        }
    }
}
