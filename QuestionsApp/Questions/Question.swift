//
//  Questions.swift
//  QuestionsApp
//
//  Created by Aleksey Gorbachevskiy on 2.11.23.
//

struct Question: Equatable, Identifiable, Decodable {
    let id: Int
    let question: String
}

extension Question {
    static var sample: [Question] {
        [
            .init(id: 1, question: "What is your favourite colour?"),
            .init(id: 2, question: "What is your favourite food?"),
            .init(id: 3, question: "What is your favourite country?"),
            .init(id: 4, question: "What is your favourite sport?"),
            .init(id: 5, question: "What is your favourite team?"),
            .init(id: 6, question: "What is your favourite programming language?"),
            .init(id: 7, question: "What is your favourite song?"),
            .init(id: 8, question: "What is your favourite band?"),
            .init(id: 9, question: "What is your favourite music?"),
            .init(id: 10, question: "What is your favourite brand?")
        ]
    }
}
