//
//  VideoListView.swift
//  Unwatched
//

import SwiftUI
import SwiftData

struct VideoListView: View {
    @Query var videos: [Video]
    var idPrefix: String

    init(subscriptionId: PersistentIdentifier? = nil,
         ytShortsFilter: ShortsDetection? = nil,
         idPrefix: String = "") {
        // TODO: This is initiated on the library view already and apparently for every subscription. Should it be that way?
        let filter = VideoListView.getVideoFilter(subscriptionId, ytShortsFilter)
        _videos = Query(filter: filter, sort: \.publishedDate, order: .reverse)
        self.idPrefix = idPrefix
    }

    var body: some View {
        ForEach(videos.indices, id: \.self) { index in
            let video = videos[index]
            VideoListItem(
                video: video,
                showVideoStatus: true,
                hasInboxEntry: video.inboxEntry != nil,
                hasQueueEntry: video.queueEntry != nil,
                watched: video.watched,
                videoSwipeActions: [.queueTop, .queueBottom, .clear]
            )
            .id("\(idPrefix)-\(index)")
        }
    }

    static func getVideoFilter(_ subscriptionId: PersistentIdentifier? = nil,
                               _ ytShortsFilter: ShortsDetection? = nil) -> Predicate<Video>? {
        var filter: Predicate<Video>?
        let allSubscriptions = subscriptionId == nil
        if allSubscriptions {
            switch ytShortsFilter {
            case .safe:
                filter = #Predicate<Video> { video in
                    video.isYtShort == false
                }
            case .moderate:
                filter = #Predicate<Video> { video in
                    (video.isYtShort == false && video.isLikelyYtShort == false)
                }
            case .none:
                break
            }
        } else {
            switch ytShortsFilter {
            case .safe:
                filter = #Predicate<Video> { video in
                    video.subscription?.persistentModelID == subscriptionId &&
                        video.isYtShort == false
                }
            case .moderate:
                filter = #Predicate<Video> { video in
                    video.subscription?.persistentModelID == subscriptionId &&
                        (video.isYtShort == false && video.isLikelyYtShort == false)
                }
            case .none:
                filter = #Predicate<Video> { video in
                    video.subscription?.persistentModelID == subscriptionId
                }
            }
        }
        return filter
    }

}

// #Preview {
//    VideoListView()
// }
