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
class QuestionTest: XCTestCase {

    func testIncreaseCounterTappingNextButtonOnce() async {
        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: Question.sample)),
            reducer: {
                QuestionDomain.live
            }
        )

        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 1 }
    }

    func testIncreaseCounterTappingNextButtonThreeTimes() async {
        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: Question.sample)),
            reducer: {
                QuestionDomain.live
            }
        )

        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 1 }
        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 2 }
        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 3 }
    }

    func testUpdatingCounterTappingNextAndPreviousButtons() async {
        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: Question.sample)),
            reducer: {
                QuestionDomain.live
            }
        )

        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 1 }
        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 2 }
        await store.send(.didTapPreviousButton) { $0.selectedQuestionIndex = 1 }
        await store.send(.didTapNextButton) { $0.selectedQuestionIndex = 2 }
    }

    func testSubmitButtonAvailability() async {
        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: Question.sample)),
            reducer: {
                QuestionDomain.live
            }
        )

        let testString = "test"
        await store.send(.textChange(testString)) {
            $0.isSubmitButtonDisabled = false
            $0.enteredText = testString
        }
    }

    func testSubmitButtonSuccess() async {
        let questions = Question.sample
        let question = questions[0]
        let statusCode: Int = 200

        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: questions)),
            reducer: {
                QuestionDomain { answer, question in
                    statusCode
                }
            }
        )

        let testString = "test"
        await store.send(.textChange(testString)) {
            $0.isSubmitButtonDisabled = false
            $0.enteredText = testString
        }

        await store.send(.didTapSubmitButton) {
            $0.isLoading = true
        }

        await store.receive(.submitAnswerResponse(.success(statusCode))) {
            $0.isLoading = false
            $0.enteredText = ""
            $0.isSubmitButtonDisabled = true
        }

        await store.receive(.markQuestionAnswered(.markQuestionAnswered(question))) {
            $0.answeredQuestions.append(question)
            $0.alert = QuestionDomain.successAlert
        }
    }

    func testSubmitButtonFailure() async {
        let error = APIClient.Failure()

        let store = TestStore(
            initialState: QuestionDomain.State(questions: IdentifiedArray(uniqueElements: Question.sample)),
            reducer: {
                QuestionDomain { answer, question in
                    throw error
                }
            }
        )

        let testString = "test"
        await store.send(.textChange(testString)) {
            $0.isSubmitButtonDisabled = false
            $0.enteredText = testString
        }

        await store.send(.didTapSubmitButton) {
            $0.isLoading = true
        }

        await store.receive(.submitAnswerResponse(.failure(error))) {
            $0.isLoading = false
            $0.alert = QuestionDomain.errorAlert(with: error)
        }
    }
}
