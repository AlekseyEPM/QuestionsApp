//
//  QuestionsApp.swift
//  Questions
//
//  Created by Aleksey Gorbachevskiy on 02/11/2023.
//

import ComposableArchitecture
import SwiftUI

@main
struct QuestionsApp: App {
    var body: some Scene {
        WindowGroup {
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
}
