//
//  SponsorBlockAPI.swift
//  Unwatched
//

import Foundation
import OSLog

struct SponsorBlockAPI {
    static let baseUrl = "https://sponsor.ajay.app/api/"

    static func skipSegments(for videoID: String) async throws -> [SponsorBlockSegmentModel] {
        let urlString = baseUrl + "skipSegments?videoID=\(videoID)"
        guard let url = URL(string: urlString) else {
            throw SponsorBlockError.noValidUrl
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        print("skipSegments url: \(urlString)")
        if let result = try? decoder.decode([SponsorBlockSegmentModel].self, from: data) {
            return result
        } else if let jsonString = String(data: data, encoding: .utf8) {
            throw SponsorBlockError.httpRequestFailed(jsonString)
        } else {
            throw SponsorBlockError.httpRequestFailed("unknown")
        }
    }

    static func getChapters(from segments: [SponsorBlockSegmentModel]) -> [SendableChapter] {
        var result = [SendableChapter]()
        for segment in segments {
            guard let startTime = segment.segment.first else {
                Logger.log.warning("Start time for sponsored segment could not be found")
                continue
            }
            let endTime = segment.segment.last

            let chapter = SendableChapter(
                title: nil,
                startTime: startTime,
                endTime: endTime,
                category: .sponsor
            )
            result.append(chapter)
        }
        return result
    }
}

struct SponsorBlockSegmentModel: Codable {
    var category: String
    var actionType: String
    var segment: [Double]
    var UUID: String
    var videoDuration: Double
    var locked: Int
    var votes: Int
    var description: String
}

enum SponsorBlockError: Error {
    case httpRequestFailed(String)
    case noValidUrl
}
