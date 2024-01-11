import SwiftData
import SwiftUI
import Observation

@ModelActor
actor VideoActor {
    // MARK: public functions that save context
    func loadVideoData(from videoUrls: [URL], in videoplacement: VideoPlacement, at index: Int = 0) async throws {
        var videos = [Video]()
        for url in videoUrls {
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            guard let youtubeId = urlComponents?.queryItems?.first(where: { $0.name == "v" })?.value else {
                print("no youtubeId found")
                return
            }
            guard let videoData = try await YoutubeDataAPI.getYtVideoInfo(youtubeId) else {
                return
            }
            print("videoData", videoData)
            let title = videoData.title.isEmpty ? youtubeId : videoData.title
            let video = videoData.getVideo(title: title, url: url, youtubeId: youtubeId)
            modelContext.insert(video)
            if let channelId = videoData.youtubeChannelId {
                addToCorrectSubscription(video, channelId: channelId)
            }
            videos.append(video)
        }
        addVideosTo(videos: videos, placement: videoplacement, index: index)
        try modelContext.save()
    }

    func loadVideos(_ subscriptionIds: [PersistentIdentifier]?,
                    defaultVideoPlacement: VideoPlacement) async throws {
        let subs = try fetchSubscriptions(subscriptionIds)
        for sub in subs {
            try await loadVideos(for: sub)
        }
        try modelContext.save()
    }

    func fetchSubscriptions(_ subscriptionIds: [PersistentIdentifier]?) throws -> [Subscription] {
        var subs = [Subscription]()
        if let ids = subscriptionIds {
            for id in ids {
                if let loadedSub = modelContext.model(for: id) as? Subscription {
                    subs.append(loadedSub)
                } else {
                    print("Subscription not found for id: \(id)")
                }
            }
        } else {
            let fetchDescriptor = FetchDescriptor<Subscription>()
            subs = try modelContext.fetch(fetchDescriptor)
        }
        return subs
    }

    func moveQueueEntry(from source: IndexSet, to destination: Int) throws {
        let fetchDescriptor = FetchDescriptor<QueueEntry>()
        let queue = try modelContext.fetch(fetchDescriptor)
        var orderedQueue = queue.sorted(by: { $0.order < $1.order })
        orderedQueue.move(fromOffsets: source, toOffset: destination)

        for (index, queueEntry) in orderedQueue.enumerated() {
            queueEntry.order = index
        }
        try modelContext.save()
    }

    private func addToCorrectSubscription(_ video: Video, channelId: String) {
        let channelIdWithout = String(channelId.dropFirst(2))
        let fetchDescriptor = FetchDescriptor<Subscription>(predicate: #Predicate {
            $0.youtubeChannelId == channelId || $0.youtubeChannelId == channelIdWithout
        })
        let subscriptions = try? modelContext.fetch(fetchDescriptor)
        if let sub = subscriptions?.first {
            sub.videos.append(video)
            for video in sub.videos {
                video.feedTitle = sub.title
                video.youtubeChannelId = sub.youtubeChannelId
            }
        }
    }

    private func loadVideos(for sub: Subscription) async throws {
        // load videos from web
        let loadedVideos = try await VideoCrawler.loadVideosFromRSS(
            url: sub.link,
            mostRecentPublishedDate: sub.mostRecentVideoDate)
        var newVideos = [Video]()
        for vid in loadedVideos {
            let video = vid.getVideo(youtubeChannelId: sub.youtubeChannelId)
            modelContext.insert(video)
            newVideos.append(video)
        }

        sub.videos.append(contentsOf: newVideos)
        let limitVideos = sub.mostRecentVideoDate == nil ? 5 : nil
        updateRecentVideoDate(subscription: sub, videos: newVideos)

        triageSubscriptionVideos(sub,
                                 videos: newVideos,
                                 defaultPlacement: .inbox,
                                 limitVideos: limitVideos)
    }

    private func updateRecentVideoDate(subscription: Subscription, videos: [Video]) {
        let dates = videos.compactMap { $0.publishedDate }
        if let mostRecentDate = dates.max() {
            print("mostRecentDate", mostRecentDate)
            subscription.mostRecentVideoDate = mostRecentDate
        }
    }

    private func triageSubscriptionVideos(_ sub: Subscription,
                                          videos: [Video],
                                          defaultPlacement: VideoPlacement,
                                          limitVideos: Int?) {
        let videosToAdd = limitVideos == nil ? videos : Array(videos.prefix(limitVideos!))

        var placement = sub.placeVideosIn
        if sub.placeVideosIn == .defaultPlacement {
            placement = defaultPlacement
        }
        addVideosTo(videos: videosToAdd, placement: placement)
    }

    private func addVideosTo(videos: [Video], placement: VideoPlacement, index: Int = 0) {
        if placement == .inbox {
            addVideosToInbox(videos)
        } else if placement == .queue {
            VideoActor.insertQueueEntries(at: index, videos: videos, modelContext: modelContext)
        }
    }

    private func addVideosToInbox(_ videos: [Video]) {
        for video in videos {
            video.status = .inbox
            let inboxEntry = InboxEntry(video: video)
            modelContext.insert(inboxEntry)
        }
    }

    // MARK: static functions
    static func markVideoWatched(_ video: Video, modelContext: ModelContext) throws {
        VideoActor.clearFromEverywhere(video, modelContext: modelContext)
        video.watched = true
        let watchEntry = WatchEntry(video: video)
        modelContext.insert(watchEntry)
    }

    static func insertQueueEntries(at startIndex: Int = 0, videos: [Video], modelContext: ModelContext) {
        do {
            print("insertQueueEntries")
            print("startIndex", startIndex)
            let sort = SortDescriptor<QueueEntry>(\.order)
            let fetch = FetchDescriptor<QueueEntry>(sortBy: [sort])
            var queue = try modelContext.fetch(fetch)
            for (index, video) in videos.enumerated() {
                video.status = .queued
                let queueEntry = QueueEntry(video: video, order: 0)
                modelContext.insert(queueEntry)
                queue.insert(queueEntry, at: startIndex + index)
            }
            for (index, queueEntry) in queue.enumerated() {
                queueEntry.order = index
            }
        } catch {
            print("\(error)")
        }
        // TODO: delete inbox entries here?
    }

    private static func clearFromQueue(_ video: Video, modelContext: ModelContext) {
        let videoId = video.youtubeId
        let fetchDescriptor = FetchDescriptor<QueueEntry>(predicate: #Predicate {
            $0.video.youtubeId == videoId
        })
        do {
            let queueEntry = try modelContext.fetch(fetchDescriptor)
            for entry in queueEntry {
                VideoActor.deleteQueueEntry(entry, modelContext: modelContext)
            }
        } catch {
            print("No queue entry found to delete")
        }
    }

    private static func clearFromInbox(_ video: Video, modelContext: ModelContext) {
        let videoId = video.youtubeId
        let fetchDescriptor = FetchDescriptor<InboxEntry>(predicate: #Predicate {
            $0.video.youtubeId == videoId
        })
        do {
            let inboxEntry = try modelContext.fetch(fetchDescriptor)
            for entry in inboxEntry {
                VideoActor.deleteInboxEntry(entry: entry, modelContext: modelContext)
            }
        } catch {
            print("No inbox entry found to delete")
        }
    }

    static func clearFromEverywhere(_ video: Video, modelContext: ModelContext) {
        VideoActor.clearFromQueue(video, modelContext: modelContext)
        VideoActor.clearFromInbox(video, modelContext: modelContext)
    }

    static func deleteQueueEntry(_ queueEntry: QueueEntry, modelContext: ModelContext) {
        let deletedOrder = queueEntry.order
        modelContext.delete(queueEntry)
        queueEntry.video.status = nil
        VideoActor.updateQueueOrderDelete(deletedOrder: deletedOrder, modelContext: modelContext)
    }

    private static func deleteInboxEntry(entry: InboxEntry, modelContext: ModelContext) {
        entry.video.status = nil
        modelContext.delete(entry)
    }

    private static func updateQueueOrderDelete(deletedOrder: Int, modelContext: ModelContext) {
        do {
            let fetchDescriptor = FetchDescriptor<QueueEntry>()
            let queue = try modelContext.fetch(fetchDescriptor)
            for queueEntry in queue where queueEntry.order > deletedOrder {
                queueEntry.order -= 1
            }
        } catch {
            print("No queue entry found to delete")
        }
    }
}
