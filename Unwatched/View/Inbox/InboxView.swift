//
//  InboxView.swift
//  Unwatched
//

import SwiftUI
import SwiftData
import TipKit
import OSLog

struct InboxView: View {
    @AppStorage(Const.newInboxItemsCount) var newInboxItemsCount = 0
    @AppStorage(Const.themeColor) var theme: ThemeColor = Color.defaultTheme
    @AppStorage(Const.showAddToQueueButton) var showAddToQueueButton: Bool = false

    @Environment(\.modelContext) var modelContext
    @Environment(NavigationManager.self) private var navManager

    var inboxEntries: [InboxEntry]
    var showCancelButton: Bool = false
    var swipeTip = InboxSwipeTip()

    var body: some View {
        @Bindable var navManager = navManager
        let showClear = inboxEntries.count >= Const.minListEntriesToShowClear

        NavigationStack(path: $navManager.presentedSubscriptionInbox) {
            ZStack {
                Color.backgroundColor.ignoresSafeArea(.all)

                if inboxEntries.isEmpty {
                    ContentUnavailableView("noInboxItems",
                                           systemImage: "tray.fill",
                                           description: Text("noInboxItemsDescription"))
                        .contentShape(Rectangle())
                        .handleVideoUrlDrop(.inbox)
                }
                // Workaround: always have the list visible, this avoids a crash when adding the last
                // inbox item to the queue and then moving the video on top of the queue
                List {
                    if !inboxEntries.isEmpty {
                        swipeTipView
                            .listRowBackground(Color.backgroundColor)
                    }

                    HideShortsTipView()

                    ForEach(inboxEntries) { entry in
                        ZStack {
                            if let video = entry.video {
                                VideoListItem(
                                    video,
                                    config: VideoListItemConfig(
                                        clearRole: .destructive,
                                        queueRole: .destructive,
                                        onChange: handleVideoChange,
                                        clearAboveBelowList: .inbox,
                                        showQueueButton: showAddToQueueButton
                                    )
                                )
                            } else {
                                EmptyEntry(entry)
                            }
                        }
                        .id(NavigationManager.getScrollId(entry.video?.youtubeId, "inbox"))
                    }
                    .handleDynamicVideoURLDrop(.inbox)
                    .listRowBackground(Color.backgroundColor)

                    ClearAllVideosButton(clearAll: clearAll)
                        .opacity(showClear ? 1 : 0)
                        .disabled(!showClear)
                }
                .disabled(inboxEntries.isEmpty)
                .listStyle(.plain)
            }
            .onAppear {
                navManager.setScrollId(inboxEntries.first?.video?.youtubeId, "inbox")
            }
            .onDisappear {
                newInboxItemsCount = 0
            }
            .toolbar {
                if showCancelButton {
                    DismissToolbarButton()
                }
                RefreshToolbarButton()
            }
            .myNavigationTitle("inbox", showBack: false)
            .navigationDestination(for: Subscription.self) { sub in
                SubscriptionDetailView(subscription: sub)
            }
            .tint(theme.color)
        }
        .tint(.neutralAccentColor)
    }

    var swipeTipView: some View {
        TipView(swipeTip)
            .tipBackground(Color.insetBackgroundColor)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(action: invalidateTip) {
                    Image(systemName: "text.insert")
                        .accessibilityLabel("queueNext")
                }
                .tint(theme.color.mix(with: Color.black, by: 0.1))

                Button(action: invalidateTip) {
                    Image(systemName: Const.queueBottomSF)
                }
                .accessibilityLabel("queueLast")
                .tint(theme.color.mix(with: Color.black, by: 0.3))
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(action: invalidateTip) {
                    Image(systemName: Const.clearSF)
                }
                .accessibilityLabel("clear")
                .tint(theme.color.mix(with: Color.black, by: 0.9))
            }
    }

    func invalidateTip() {
        swipeTip.invalidate(reason: .actionPerformed)
    }

    func handleVideoChange() {
        if newInboxItemsCount > 0 {
            withAnimation {
                newInboxItemsCount = 0
            }
        }
    }

    func deleteInboxEntryIndexSet(_ indexSet: IndexSet) {
        for index in indexSet {
            let entry = inboxEntries[index]
            deleteInboxEntry(entry)
        }
    }

    func deleteInboxEntry(_ entry: InboxEntry) {
        VideoService.deleteInboxEntry(entry, modelContext: modelContext)
    }

    func clearAll() {
        VideoService.deleteInboxEntries(inboxEntries, modelContext: modelContext)
        handleVideoChange()
    }
}

#Preview {
    InboxView(inboxEntries: [])
        .modelContainer(DataController.previewContainer)
        .environment(NavigationManager())
        .environment(PlayerManager())
        .environment(RefreshManager())
}
