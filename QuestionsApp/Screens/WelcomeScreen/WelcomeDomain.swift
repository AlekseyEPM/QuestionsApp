//
//  WelcomeDomain.swift
//  Questions
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import Foundation

struct WelcomeDomain: Reducer {
    struct State: Equatable {
        var path = StackState<QuestionDomain.State>()
        var dataLoadingStatus = DataLoadingStatus.notStarted
        var questions: IdentifiedArrayOf<Question> = []
        var answeredQuestions: IdentifiedArrayOf<Question> = []
        @PresentationState public var alert: AlertState<AlertAction>?

        var isLoading: Bool {
            dataLoadingStatus == .loading
        }
    }

    public enum AlertAction: Equatable, Sendable {
        case retry
    }

    enum DataLoadingStatus {
        case notStarted
        case loading
        case success
        case error
    }
    
    enum Action: Equatable {
        case path(StackAction<QuestionDomain.State, QuestionDomain.Action>)
        case fetchQuestions
        case fetchQuestionsResponse(TaskResult<[Question]>)
        case markQuestionAnswered(Question)
        case alert(PresentationAction<AlertAction>)
    }

    var fetchQuestions: @Sendable () async throws -> [Question]

    static let live = Self(
        fetchQuestions: APIClient.live.fetchQuestions
    )
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .path:
                return .none

            case .fetchQuestions:
                switch state.dataLoadingStatus {
                case .success, .loading:
                    return .none

                default:
                    state.dataLoadingStatus = .loading
                    return .run { send in
                        await send(
                            .fetchQuestionsResponse(
                                TaskResult { try await fetchQuestions() }
                            )
                        )
                    }
                }

            case .fetchQuestionsResponse(.success(let questions)):
                state.dataLoadingStatus = .success
                state.questions = IdentifiedArray(uniqueElements: questions, id: \.id)
                return .none

            case .fetchQuestionsResponse(.failure(let error)):
                state.dataLoadingStatus = .error
                state.alert = Self.errorAlert(with: error)
                return .none

            case .markQuestionAnswered(let question):
                if !state.answeredQuestions.contains(question) {
                    state.answeredQuestions.append(question)
                }
                return .none

            case .alert(.presented(.retry)):
                state.dataLoadingStatus = .loading
                return .run { send in
                    await send(
                        .fetchQuestionsResponse(
                            TaskResult { try await fetchQuestions() }
                        )
                    )
                }

            case .alert:
                state.alert = nil
                return .none
            }
        }
        .forEach(\.path, action: /Action.path) {
            QuestionDomain.live
        }
        .ifLet(\.$alert, action: /Action.alert)
    }

    static func errorAlert(with error: Error) -> AlertState<AlertAction> {
        AlertState(
            title: TextState("Oops!"),
            message: TextState(error.localizedDescription),
            buttons: [
                .default(TextState("Retry"), action: .send(.retry))
            ]
        )
    }
}
