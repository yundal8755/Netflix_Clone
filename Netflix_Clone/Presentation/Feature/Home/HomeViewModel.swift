//
//  HomeViewModel.swift
//  Netflix_Clone
//
//  Created by mac on 4/3/26.
//

import UIKit

final class HomeViewModel {
    struct Section {
        let title: String
        let items: [PosterItem]
    }

    enum Action {
        case viewDidLoad
    }

    enum State {
        case loaded(sections: [Section])
    }

    var onStateChange: ((State) -> Void)?

    func send(_ action: Action) {
        switch action {
        case .viewDidLoad:
            onStateChange?(.loaded(sections: makeSections()))
        }
    }
}

private extension HomeViewModel {
    func makeSections() -> [Section] {
        let popularItems: [PosterItem] = [
            PosterItem(title: "Money Heist", color: UIColor(red: 152 / 255, green: 38 / 255, blue: 36 / 255, alpha: 1)),
            PosterItem(title: "Stranger Things", color: UIColor(red: 46 / 255, green: 18 / 255, blue: 96 / 255, alpha: 1)),
            PosterItem(title: "The Witcher", color: UIColor(red: 45 / 255, green: 71 / 255, blue: 67 / 255, alpha: 1)),
            PosterItem(title: "Kingdom", color: UIColor(red: 58 / 255, green: 44 / 255, blue: 26 / 255, alpha: 1)),
            PosterItem(title: "Squid Game", color: UIColor(red: 92 / 255, green: 34 / 255, blue: 59 / 255, alpha: 1))
        ]

        let trendingItems: [PosterItem] = [
            PosterItem(title: "Squid Game", color: UIColor(red: 86 / 255, green: 56 / 255, blue: 36 / 255, alpha: 1)),
            PosterItem(title: "House of Secrets", color: UIColor(red: 57 / 255, green: 76 / 255, blue: 82 / 255, alpha: 1)),
            PosterItem(title: "Alive", color: UIColor(red: 56 / 255, green: 63 / 255, blue: 104 / 255, alpha: 1)),
            PosterItem(title: "Top Boy", color: UIColor(red: 77 / 255, green: 43 / 255, blue: 59 / 255, alpha: 1)),
            PosterItem(title: "Dark", color: UIColor(red: 35 / 255, green: 53 / 255, blue: 69 / 255, alpha: 1))
        ]

        let actionItems: [PosterItem] = [
            PosterItem(title: "Extraction", color: UIColor(red: 58 / 255, green: 60 / 255, blue: 55 / 255, alpha: 1)),
            PosterItem(title: "The Old Guard", color: UIColor(red: 82 / 255, green: 57 / 255, blue: 43 / 255, alpha: 1)),
            PosterItem(title: "6 Underground", color: UIColor(red: 41 / 255, green: 76 / 255, blue: 81 / 255, alpha: 1)),
            PosterItem(title: "Carter", color: UIColor(red: 89 / 255, green: 37 / 255, blue: 41 / 255, alpha: 1)),
            PosterItem(title: "Athena", color: UIColor(red: 62 / 255, green: 61 / 255, blue: 96 / 255, alpha: 1))
        ]

        return [
            Section(title: "Popular on Netflix", items: popularItems),
            Section(title: "Trending Now", items: trendingItems),
            Section(title: "Action", items: actionItems),
            Section(title: "New", items: actionItems)
        ]
    }
}
