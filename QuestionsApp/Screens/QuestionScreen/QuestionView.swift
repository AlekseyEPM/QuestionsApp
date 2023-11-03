//
//  ContentView.swift
//  Questions
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import SwiftUI

struct QuestionView: View {
    let store: Store<QuestionDomain.State, QuestionDomain.Action>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            if viewStore.questions.count == 0 {
                emptyView
            } else {
                ZStack {
                    navigationView
                    loadingView(isLoading: viewStore.isLoading)
                }
                .onAppear {
                    viewStore.send(.verifyButtonsAvailability)
                }
            }
        }
        .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
    }

    private var navigationView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationView {
                contentView
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(
                "Question \(viewStore.selectedQuestionIndex + 1)/\(viewStore.questions.count)"
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.didTapPreviousButton)
                    } label: {
                        Text("Previous")
                    }
                    .disabled(viewStore.isPreviousButtonDisabled)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewStore.send(.didTapNextButton)
                    } label: {
                        Text("Next")
                    }
                    .disabled(viewStore.isNextButtonDisabled)
                }
            }
        }
    }

    private var contentView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack {
                Text("Questions submitted: \(viewStore.answeredQuestions.count)")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                Text(viewStore.selectedQuestion.question)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                textView
                Button {
                    viewStore.send(.didTapSubmitButton)
                } label: {
                    Text(viewStore.isAlreadyAnswered ? "Already submitted" : "Submit")
                        .frame(width: 200, height: 50)
                        .background(.white)
                        .foregroundColor(.blue)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(viewStore.isSubmitButtonDisabled)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray)
        }
    }

    private var textView: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            TextField(
                viewStore.isAlreadyAnswered ? "Already answered" : "Type here for an answer...",
                text: viewStore.binding(
                    get: \.enteredText,
                    send: { .textChange($0) }
                ),
                axis: .vertical
            )
            .disabled(viewStore.isAlreadyAnswered)
            .lineLimit(3...10)
            .padding(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.black, lineWidth: 1)
            )
            .padding(16)
        }
    }

    @ViewBuilder
    private func loadingView(isLoading: Bool) -> some View {
        if isLoading {
            Group {
                Color.black.opacity(0.8)
                ProgressView()
                    .tint(Color.white)
            }
            .ignoresSafeArea()
        }
    }

    private var emptyView: some View {
        Text("Nothing to display")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .foregroundColor(.white)
            .background(Color.black.opacity(0.8))
    }
}

struct QuestionView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionView(
            store: Store(
                initialState: QuestionDomain.State(
                    questions: IdentifiedArray(uniqueElements: Question.sample)
                )
            ) {
                QuestionDomain.live
            }
        )
    }
}
