//
//  Color.swift
//  Unwatched
//

import SwiftUI

enum ThemeColor: Int, CustomStringConvertible, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case darkGreen
    case mint
    case teal
    case blue
    case purple
    case blackWhite

    var color: Color {
        switch self {
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .darkGreen:
            return .darkGreen
        case .mint:
            return .mint
        case .teal:
            return .teal
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .blackWhite:
            return .neutralAccentColor
        }
    }

    var description: String {
        switch self {
        case .red:
            return String(localized: "red")
        case .orange:
            return String(localized: "orange")
        case .yellow:
            return String(localized: "yellow")
        case .green:
            return String(localized: "green")
        case .darkGreen:
            return String(localized: "darkGreen")
        case .mint:
            return String(localized: "mint")
        case .teal:
            return String(localized: "teal")
        case .blue:
            return String(localized: "blue")
        case .purple:
            return String(localized: "purple")
        case .blackWhite:
            return String(localized: "blackWhite")
        }
    }

    var appIconName: String {
        switch self {
        case .red:
            return "RedIcon"
        case .orange:
            return "OrangeIcon"
        case .yellow:
            return "YellowIcon"
        case .green:
            return "GreenIcon"
        case .darkGreen:
            return "DarkGreenIcon"
        case .mint:
            return "MintIcon"
        case .teal:
            return "TealIcon"
        case .blue:
            return "BlueIcon"
        case .purple:
            return "PurpleIcon"
        case .blackWhite:
            return "BlackWhiteIcon"
        }
    }
}

extension Color {
    static var defaultTheme: ThemeColor {
        .teal
    }

    static var neutralAccentColor: Color {
        Color("neutralAccentColor")
    }
    static var backgroundColor: Color {
        Color("BackgroundColor")
    }
    static var grayColor: Color {
        Color("CustomGray")
    }
    static var myBackgroundGray: Color {
        Color("backgroundGray")
    }
    static var myForegroundGray: Color {
        Color("foregroundGray")
    }
    static var youtubeWebBackground: Color {
        Color("YouTubeWebBackground")
    }
}
