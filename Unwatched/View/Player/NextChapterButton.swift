//
//  PreviousChapterButton.swift
//  Unwatched
//

import SwiftUI

struct NextChapterButton<Content>: View where Content: View {
    @Environment(PlayerManager.self) var player
    @State var actionToggle: Bool = false

    private let contentImage: ((Image) -> Content)

    init(
        @ViewBuilder content: @escaping (Image) -> Content = { $0 }
    ) {
        self.contentImage = content
    }

    var body: some View {
        Button {
            actionToggle.toggle()
            player.goToNextChapter()
        } label: {
            contentImage(
                Image(systemName: Const.nextChapterSF)
            )
            .symbolEffect(.bounce.down, value: actionToggle)
        }
        .accessibilityLabel("nextChapter")
        .sensoryFeedback(Const.sensoryFeedback, trigger: actionToggle)
    }
}
