//
//  APIClient.swift
//  QuestionsApp
//
//  Created by Aleksey Gorbachevskiy on 2.11.23.
//

import Foundation

struct APIClient {

    private static let baseURL = ""

    var fetchQuestions:  @Sendable () async throws -> [Question]
    var submitAnswer: @Sendable (_ answer: String, _ question: Question) async throws -> Int

    struct Failure: Error, Equatable {}
}

extension APIClient {
    static let live = Self(
        fetchQuestions: {
            guard let url = URL(string: baseURL + "/questions") else { fatalError("Can't create url from string") }
            let (data, _) = try await URLSession.shared.data(from: url)
            let questions = try JSONDecoder().decode([Question].self, from: data)
            return questions
        }, submitAnswer: { answer, question in
            guard let url = URL(string: baseURL + "/question/submit") else { fatalError("Can't create url from string") }
            let answer = Answer(id: question.id, answer: answer)
            let payload = try JSONEncoder().encode(answer)
            var urlRequest = URLRequest(url: url)
            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpMethod = "POST"
            let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: payload)

            guard let httpResponse = (response as? HTTPURLResponse) else {
                throw Failure()
            }

            if let error = Self.checkError(in: httpResponse) {
                throw error
            }

            return httpResponse.statusCode
        }
    )

    private static func checkError(in response: HTTPURLResponse) -> Error? {
        switch response.statusCode {
        case 300...599:
            return NetworkError.error(response.statusCode)

        default:
            return nil
        }
    }
}

private struct Answer: Encodable {
    let id: Int
    let answer: String
}
