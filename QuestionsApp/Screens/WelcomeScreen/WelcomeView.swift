//
//  ContentView.swift
//  Questions
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import SwiftUI

struct WelcomeView: View {
    let store: Store<WelcomeDomain.State, WelcomeDomain.Action>
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStackStore(store.scope(state: \.path, action: { .path($0) })) {
                ZStack {
                    VStack {
                        Text("Welcome")
                        Spacer()
                        NavigationLink(
                            state: QuestionDomain.State(
                                questions: viewStore.questions
                            )
                        ) {
                            Text("Start survey")
                                .frame(width: 200, height: 50)
                                .background(.white)
                                .foregroundColor(.blue)
                                .cornerRadius(10)
                        }
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray)
                    loadingView(isLoading: viewStore.isLoading)
                }
            } destination: {
                QuestionView(store: $0)
            }
            .task {
                viewStore.send(.fetchQuestions)
            }
            .alert(store: store.scope(state: \.$alert, action: { .alert($0) }))
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
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            store: Store(
                initialState: WelcomeDomain.State(),
                reducer: {
                    WelcomeDomain.live
                }
            )
        )
    }
}
