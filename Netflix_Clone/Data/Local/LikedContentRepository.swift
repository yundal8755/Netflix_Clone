//
//  LikedContentRepository.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import Foundation
import RealmSwift

struct LikedPoster: Equatable {
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
    func toggle(movieID: Int, title: String, posterURL: URL?)
}

final class LikedContentRepository: LikedContentRepositoryType {
    static let shared = LikedContentRepository()

    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    func isLiked(movieID: Int) -> Bool {
        do {
            let realm = try Realm(configuration: configuration)
            return realm.object(ofType: LikedPosterObject.self, forPrimaryKey: movieID) != nil
        } catch {
            assertionFailure("Failed to open Realm: \(error)")
            return false
        }
    }

    func fetchLikedPosters() -> [LikedPoster] {
        do {
            let realm = try Realm(configuration: configuration)
            let objects = realm.objects(LikedPosterObject.self)
                .sorted(byKeyPath: "updatedAt", ascending: true)

            return objects.map {
                LikedPoster(
                    movieID: $0.movieID,
                    title: $0.title,
                    posterURLString: $0.posterURLString
                )
            }
        } catch {
            assertionFailure("Failed to fetch liked posters from Realm: \(error)")
            return []
        }
    }

    func toggle(movieID: Int, title: String, posterURL: URL?) {
        do {
            let realm = try Realm(configuration: configuration)

            try realm.write {
                if let object = realm.object(ofType: LikedPosterObject.self, forPrimaryKey: movieID) {
                    realm.delete(object)
                    return
                }

                let object = LikedPosterObject()
                object.movieID = movieID
                object.title = title
                object.posterURLString = posterURL?.absoluteString
                object.updatedAt = Date()
                realm.add(object, update: .modified)
            }
        } catch {
            assertionFailure("Failed to toggle liked poster in Realm: \(error)")
        }
    }
}

// DTO
//@objc(LikedPosterObject)
final class LikedPosterObject: Object {
    @Persisted(primaryKey: true) var movieID: Int
    @Persisted var title: String
    @Persisted var posterURLString: String?
    @Persisted var updatedAt: Date
}
