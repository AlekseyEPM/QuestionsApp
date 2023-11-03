//
//  QuestionsTests.swift
//  QuestionsTests
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import XCTest

@testable import QuestionsApp

@MainActor
class WelcomeTest: XCTestCase {

    func testFetchQuestionsSuccess() async {
        let questions = Question.sample

        let store = TestStore(
            initialState: WelcomeDomain.State(),
            reducer: {
                WelcomeDomain(
                    fetchQuestions: {
                        questions
                    }
                )
            }
        )

        let identifiedArray = IdentifiedArrayOf(uniqueElements: questions)

        await store.send(.fetchQuestions) {
            $0.dataLoadingStatus = .loading
        }

        await store.receive(.fetchQuestionsResponse(.success(questions))) {
            $0.questions = identifiedArray
            $0.dataLoadingStatus = .success
        }
    }

    func testFetchQuestionsFailure() async {
        let error = APIClient.Failure()
        let store = TestStore(
            initialState: WelcomeDomain.State(),
            reducer: {
                WelcomeDomain(
                    fetchQuestions: {
                        throw error
                    }
                )
            }
        )

        await store.send(.fetchQuestions) {
            $0.dataLoadingStatus = .loading
        }

        await store.receive(.fetchQuestionsResponse(.failure(error))) {
            $0.questions = []
            $0.dataLoadingStatus = .error
            $0.alert = WelcomeDomain.errorAlert(with: error)
        }
    }
}
