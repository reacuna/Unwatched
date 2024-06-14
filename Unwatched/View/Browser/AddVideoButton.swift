//
//  AddVideoButton.swift
//  Unwatched
//

import SwiftUI

struct AddVideoButton: View {
    @State var avm = AddVideoViewModel()
    @Environment(\.modelContext) var modelContext
    @AppStorage(Const.themeColor) var theme: ThemeColor = Color.defaultTheme

    @State var showHelp = false
    @State var showInsert = false

    var youtubeUrl: URL?
    var size: Double = 20

    var body: some View {
        let backgroundSize = avm.isDragOver ? 6 * size : 2 * size

        ZStack {
            Circle()
                .fill(.black.opacity(0.000001))
                .frame(width: backgroundSize, height: backgroundSize)
            Button {
                if isVideoUrl || isPlaylistUrl {
                    Task {
                        if let youtubeUrl = youtubeUrl {
                            await avm.addUrls([youtubeUrl])
                        }
                    }
                } else {
                    showHelp = true
                }
            } label: {
                Image(systemName: avm.isSuccess == true
                        ? "checkmark"
                        : avm.isSuccess == false
                        ? "xmark"
                        : isVideoUrl || isPlaylistUrl || showInsert
                        ? "text.insert"
                        : avm.isLoading
                        ? "ellipsis"
                        : "circle.circle")
                    .fontWeight(.semibold)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: size, height: size)
                    .padding(7)
            }
        }
        .background {
            // Workaround: isDragOver = true get's stuck otherwise
            Circle()
                .fill(avm.isDragOver ? theme.color : Color.neutralAccentColor)
                .frame(width: backgroundSize, height: backgroundSize)
                .animation(.default, value: avm.isDragOver)
        }
        .frame(width: backgroundSize, height: backgroundSize)
        .dropDestination(for: URL.self) { items, _ in
            Task {
                await avm.addUrls(items)
            }
            return true
        } isTargeted: { targeted in
            avm.isDragOver = targeted

            if targeted {
                showInsert = targeted
            } else {
                Task {
                    do {
                        try await Task.sleep(s: 0.5)
                        showInsert = targeted
                    }
                }
            }
        }
        .frame(width: size, height: size)
        .foregroundStyle(Color.backgroundColor)
        .popover(isPresented: $showHelp) {
            Text("dropVideosTip")
                .padding()
                .presentationCompactAdaptation(.popover)
        }
        .onAppear {
            avm.container = modelContext.container
        }
        .sensoryFeedback(Const.sensoryFeedback, trigger: avm.isDragOver)
    }

    var isVideoUrl: Bool {
        if let url = youtubeUrl {
            return UrlService.getYoutubeIdFromUrl(url: url) != nil
        }
        return false
    }

    var isPlaylistUrl: Bool {
        if let url = youtubeUrl {
            return UrlService.getPlaylistIdFromUrl(url) != nil
        }
        return false
    }
}

#Preview {
    HStack {
        Spacer()
        AddVideoButton(youtubeUrl: URL(string: "www.google.com")!)
            .padding(20)
    }
    .modelContainer(DataController.previewContainer)
}
