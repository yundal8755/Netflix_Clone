//
//  LikedContentRepository.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import Foundation

extension Notification.Name {
    static let likedContentDidUpdate = Notification.Name("likedContentDidUpdate")
}

enum LikedContentNotificationUserInfoKey {
    static let movieID = "movieID"
    static let isLiked = "isLiked"
}

struct LikedPoster: Codable, Equatable {
    let movieID: Int
    let title: String
    let posterURLString: String?

    var posterURL: URL? {
        guard let posterURLString, posterURLString.isEmpty == false else { return nil }
        return URL(string: posterURLString)
    }
}

protocol LikedContentRepositoryType: AnyObject {
    func isLiked(movieID: Int) -> Bool
    func fetchLikedPosters() -> [LikedPoster]
    @discardableResult
    func toggle(movieID: Int, title: String, posterURL: URL?) -> Bool
}

final class LikedContentRepository: LikedContentRepositoryType {
    static let shared = LikedContentRepository()

    private enum Constant {
        static let storageKey = "liked-content-storage-key"
    }

    private let lock = NSLock()
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter

    private var likedPosters: [LikedPoster]

    init(
        userDefaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        self.likedPosters = Self.loadStoredPosters(from: userDefaults)
    }

    func isLiked(movieID: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return likedPosters.contains { $0.movieID == movieID }
    }

    func fetchLikedPosters() -> [LikedPoster] {
        lock.lock()
        defer { lock.unlock() }
        return likedPosters
    }

    @discardableResult
    func toggle(movieID: Int, title: String, posterURL: URL?) -> Bool {
        lock.lock()

        let isLiked: Bool

        if let index = likedPosters.firstIndex(where: { $0.movieID == movieID }) {
            likedPosters.remove(at: index)
            isLiked = false
        } else {
            likedPosters.append(
                LikedPoster(
                    movieID: movieID,
                    title: title,
                    posterURLString: posterURL?.absoluteString
                )
            )
            isLiked = true
        }

        let snapshot = likedPosters
        lock.unlock()

        persist(snapshot)
        notificationCenter.post(
            name: .likedContentDidUpdate,
            object: nil,
            userInfo: [
                LikedContentNotificationUserInfoKey.movieID: movieID,
                LikedContentNotificationUserInfoKey.isLiked: isLiked
            ]
        )

        return isLiked
    }
}

private extension LikedContentRepository {
    static func loadStoredPosters(from userDefaults: UserDefaults) -> [LikedPoster] {
        guard let data = userDefaults.data(forKey: Constant.storageKey) else { return [] }
        return (try? JSONDecoder().decode([LikedPoster].self, from: data)) ?? []
    }

    func persist(_ posters: [LikedPoster]) {
        guard let data = try? JSONEncoder().encode(posters) else { return }
        userDefaults.set(data, forKey: Constant.storageKey)
    }
}
