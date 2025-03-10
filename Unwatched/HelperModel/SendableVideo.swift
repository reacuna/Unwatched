//
//  SendableVideo.swift
//  Unwatched
//

import Foundation
import SwiftData

struct SendableVideo: Sendable, Codable {
    var persistendId: Int?
    var youtubeId: String
    var title: String
    var url: URL?
    var thumbnailUrl: URL?
    var thumbnailData: Data?
    var youtubeChannelId: String?
    var feedTitle: String?
    var duration: Double?
    var elapsedSeconds: Double?
    var chapters = [SendableChapter]()

    var publishedDate: Date?
    var updatedDate: Date?
    var watchedDate: Date?
    var isYtShort: Bool = false

    var videoDescription: String?
    var bookmarkedDate: Date?
    var clearedInboxDate: Date?
    var createdDate: Date?

    func createVideo(
        title: String? = nil,
        url: URL? = nil,
        youtubeId: String? = nil,
        thumbnailUrl: URL? = nil,
        publishedDate: Date? = nil,
        youtubeChannelId: String? = nil,
        feedTitle: String? = nil,
        duration: TimeInterval? = nil,
        videoDescription: String? = nil
    ) -> Video {
        let title = title ?? self.title
        let description = videoDescription ?? self.videoDescription

        var newChapters = chapters
        if chapters.isEmpty, let desc = self.videoDescription {
            newChapters = ChapterService.extractChapters(from: desc, videoDuration: duration)
        }
        return Video(
            title: title,
            url: url ?? self.url,
            youtubeId: youtubeId ?? self.youtubeId,
            thumbnailUrl: thumbnailUrl ?? self.thumbnailUrl,
            publishedDate: publishedDate ?? self.publishedDate,
            updatedDate: self.updatedDate,
            youtubeChannelId: youtubeChannelId ?? self.youtubeChannelId,
            duration: duration ?? self.duration,
            elapsedSeconds: self.elapsedSeconds,
            videoDescription: description,
            chapters: newChapters.map { $0.getChapter },
            watchedDate: self.watchedDate,
            isYtShort: self.isYtShort,
            bookmarkedDate: self.bookmarkedDate,
            clearedInboxDate: self.clearedInboxDate,
            createdDate: self.createdDate
        )
    }

    init(
        persistendId: Int? = nil,
        youtubeId: String,
        title: String,
        url: URL?,
        thumbnailUrl: URL? = nil,
        youtubeChannelId: String? = nil,
        feedTitle: String? = nil,
        duration: Double? = nil,
        elapsedSeconds: Double? = nil,
        chapters: [SendableChapter] = [SendableChapter](),
        publishedDate: Date? = nil,
        updatedDate: Date? = nil,
        watchedDate: Date? = nil,
        isYtShort: Bool = false,
        videoDescription: String? = nil,
        bookmarkedDate: Date? = nil,
        clearedInboxDate: Date? = nil,
        createdDate: Date? = .now
    ) {
        self.persistendId = persistendId
        self.youtubeId = youtubeId
        self.title = title
        self.url = url
        self.thumbnailUrl = thumbnailUrl
        self.youtubeChannelId = youtubeChannelId
        self.feedTitle = feedTitle
        self.duration = duration
        self.elapsedSeconds = elapsedSeconds
        self.chapters = chapters
        self.publishedDate = publishedDate
        self.updatedDate = updatedDate
        self.watchedDate = watchedDate
        self.isYtShort = isYtShort
        self.videoDescription = videoDescription
        self.bookmarkedDate = bookmarkedDate
        self.clearedInboxDate = clearedInboxDate
        self.createdDate = createdDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SendableVideoCodingKeys.self)

        persistendId = try container.decodeIfPresent(Int.self, forKey: .persistendId)
        youtubeId = try container.decode(String.self, forKey: .youtubeId)
        title = try container.decode(String.self, forKey: .title)
        url = try container.decode(URL.self, forKey: .url)
        thumbnailUrl = try container.decodeIfPresent(URL.self, forKey: .thumbnailUrl)
        youtubeChannelId = try container.decodeIfPresent(String.self, forKey: .youtubeChannelId)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration)
        elapsedSeconds = try container.decodeIfPresent(Double.self, forKey: .elapsedSeconds)
        publishedDate = try container.decodeIfPresent(Date.self, forKey: .publishedDate)
        updatedDate = try container.decodeIfPresent(Date.self, forKey: .updatedDate)
        watchedDate = try container.decodeIfPresent(Date.self, forKey: .watchedDate)
        isYtShort = try container.decodeIfPresent(Bool.self, forKey: .isYtShort) ?? false
        videoDescription = try container.decodeIfPresent(String.self, forKey: .videoDescription)
        bookmarkedDate = try container.decodeIfPresent(Date.self, forKey: .bookmarkedDate)
        clearedInboxDate = try container.decodeIfPresent(Date.self, forKey: .clearedInboxDate)
        createdDate = try container.decodeIfPresent(Date.self, forKey: .createdDate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SendableVideoCodingKeys.self)

        try container.encodeIfPresent(persistendId, forKey: .persistendId)
        try container.encode(youtubeId, forKey: .youtubeId)
        try container.encode(title, forKey: .title)
        try container.encode(url, forKey: .url)
        try container.encodeIfPresent(thumbnailUrl, forKey: .thumbnailUrl)
        try container.encodeIfPresent(youtubeChannelId, forKey: .youtubeChannelId)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(elapsedSeconds, forKey: .elapsedSeconds)
        try container.encodeIfPresent(publishedDate, forKey: .publishedDate)
        try container.encodeIfPresent(updatedDate, forKey: .updatedDate)
        try container.encodeIfPresent(watchedDate, forKey: .watchedDate)
        try container.encodeIfPresent(isYtShort, forKey: .isYtShort)
        try container.encodeIfPresent(videoDescription, forKey: .videoDescription)
        try container.encodeIfPresent(bookmarkedDate, forKey: .bookmarkedDate)
        try container.encodeIfPresent(clearedInboxDate, forKey: .clearedInboxDate)
        try container.encodeIfPresent(createdDate, forKey: .createdDate)
    }
}

// MARK: - SendableVideoCodingKeys
enum SendableVideoCodingKeys: String, CodingKey {
    case persistendId
    case youtubeId
    case title
    case url
    case thumbnailUrl
    case youtubeChannelId
    case duration
    case elapsedSeconds
    case publishedDate
    case updatedDate
    case watchedDate
    case isYtShort
    case videoDescription
    case bookmarkedDate
    case clearedInboxDate
    case createdDate
}
