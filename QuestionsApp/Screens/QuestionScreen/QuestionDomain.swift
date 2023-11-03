//
//  WelcomeDomain.swift
//  Questions
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import Foundation

struct QuestionDomain: Reducer {
    struct State: Equatable {
        var welcomeState = WelcomeDomain.State()
        var isLoading = false
        var isSubmitButtonDisabled = true
        var isPreviousButtonDisabled = false
        var isNextButtonDisabled = false
        var enteredText: String = ""
        @PresentationState public var alert: AlertState<AlertAction>?

        var questions: IdentifiedArrayOf<Question>
        var selectedQuestionIndex = 0
        var answeredQuestions: IdentifiedArrayOf<Question> {
            get { welcomeState.answeredQuestions }
            set { welcomeState.answeredQuestions = newValue }
        }

        var selectedQuestion: Question {
            questions[selectedQuestionIndex]
        }

        var isAlreadyAnswered: Bool {
            answeredQuestions.contains(selectedQuestion)
        }
    }

    public enum AlertAction: Equatable, Sendable {
        case retry
        case close
    }

    enum Action: Equatable {
        case verifyButtonsAvailability
        case didTapPreviousButton
        case didTapNextButton
        case didTapSubmitButton
        case submitAnswerResponse(TaskResult<Int>)
        case textChange(String)
        case markQuestionAnswered(WelcomeDomain.Action)
        case alert(PresentationAction<AlertAction>)
    }

    var submitAnswer: @Sendable (_ answer: String, _ question: Question) async throws -> Int

    static let live = Self(
        submitAnswer: APIClient.live.submitAnswer
    )

    var body: some ReducerOf<Self> {
        Scope(state: \.welcomeState, action: /Action.markQuestionAnswered) {
            WelcomeDomain.live
        }
        Reduce { state, action in
            switch action {
            case .verifyButtonsAvailability:
                return verifyPreviousNextButtonsAvailability(state: &state)
                    .concatenate(with: verifySubmitButtonAvailability(state: &state))

            case .didTapPreviousButton:
                state.selectedQuestionIndex -= 1
                return verifyPreviousNextButtonsAvailability(state: &state)
                    .concatenate(with: clearTextField(state: &state))
                    .concatenate(with: verifySubmitButtonAvailability(state: &state))
                
            case .didTapNextButton:
                state.selectedQuestionIndex += 1
                return verifyPreviousNextButtonsAvailability(state: &state)
                    .concatenate(with: clearTextField(state: &state))
                    .concatenate(with: verifySubmitButtonAvailability(state: &state))
                
            case .didTapSubmitButton:
                state.isLoading = true
                let enteredText = state.enteredText
                let selectedQuestion = state.selectedQuestion
                return .run { send in
                    await send(
                        .submitAnswerResponse(
                            TaskResult { try await submitAnswer(enteredText, selectedQuestion) }
                        )
                    )
                }

            case .submitAnswerResponse(.success):
                state.isLoading = false
                let question = state.selectedQuestion
                return clearTextField(state: &state)
                    .concatenate(with: verifySubmitButtonAvailability(state: &state))
                    .concatenate(
                        with: .run { send in
                            await send(
                                .markQuestionAnswered(.markQuestionAnswered(question))
                            )
                        }
                    )

            case .submitAnswerResponse(.failure(let error)):
                state.isLoading = false
                state.alert = Self.errorAlert(with: error)
                return .none

            case .textChange(let text):
                state.enteredText = text
                return verifySubmitButtonAvailability(state: &state)

            case .markQuestionAnswered:
                state.alert = Self.successAlert
                return .none

            case .alert(.presented(.retry)):
                return .run { send in
                    await send(.didTapSubmitButton)
                }

            case .alert(.presented(.close)):
                state.alert = nil
                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: /Action.alert)
    }

    private func verifyPreviousNextButtonsAvailability(
        state: inout State
    ) -> Effect<Action> {
        state.isPreviousButtonDisabled = state.selectedQuestionIndex <= 0
        state.isNextButtonDisabled = state.selectedQuestionIndex >= state.questions.count - 1
        return .none
    }

    private func verifySubmitButtonAvailability(
        state: inout State
    ) -> Effect<Action> {
        state.isSubmitButtonDisabled = state.isAlreadyAnswered || state.enteredText.isEmpty
        return .none
    }

    private func clearTextField(
        state: inout State
    ) -> Effect<Action> {
        state.enteredText = ""
        return .none
    }

    static func errorAlert(with error: Error) -> AlertState<AlertAction> {
        AlertState(
            title: TextState("Oops!"),
            message: TextState(error.localizedDescription),
            buttons: [
                .default(TextState("Retry"), action: .send(.retry)),
                .default(TextState("Close"), action: .send(.close))
            ]
        )
    }

    static var successAlert: AlertState<AlertAction> {
        AlertState(
            title: TextState("Success"),
            buttons: [
                .default(TextState("Close"), action: .send(.close))
            ]
        )
    }
}

