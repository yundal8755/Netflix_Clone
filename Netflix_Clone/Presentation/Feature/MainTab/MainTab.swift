//
//  MainTab.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import Foundation

enum MainTab: CaseIterable {
    case home
    case likes
    case profile

    var title: String {
        switch self {
        case .home:
            return "홈"
        case .likes:
            return "좋아요"
        case .profile:
            return "프로필"
        }
    }

    var symbolName: String {
        switch self {
        case .home:
            return "house"
        case .likes:
            return "heart"
        case .profile:
            return "person"
        }
    }

    var selectedSymbolName: String {
        switch self {
        case .home:
            return "house.fill"
        case .likes:
            return "heart.fill"
        case .profile:
            return "person.fill"
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .home:
            return "main.tab.home"
        case .likes:
            return "main.tab.likes"
        case .profile:
            return "main.tab.profile"
        }
    }
}
