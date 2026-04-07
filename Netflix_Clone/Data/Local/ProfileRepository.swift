//
//  ProfileRepository.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RealmSwift

extension Notification.Name {
    static let profileDidUpdate = Notification.Name("profileDidUpdate")
}

enum ProfileNotificationUserInfoKey {
    static let profileImageName = "profileImageName"
}

struct ProfileEntity {
    let nickname: String
    let profileImageName: String
    let statusMessage: String

    static func initial() -> ProfileEntity {
        ProfileEntity(
            nickname: "",
            profileImageName: "",
            statusMessage: ""
        )
    }
}

protocol ProfileRepositoryType: Sendable {
    func fetchProfile() async throws -> ProfileEntity
    func saveProfile(
        nickname: String,
        profileImageName: String,
        statusMessage: String
    ) async throws -> ProfileEntity
}

actor ProfileRepository: ProfileRepositoryType {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    func fetchProfile() async throws -> ProfileEntity {
        try await MainActor.run {
            let realm = try Realm(configuration: configuration)
            let profile = realm.object(
                ofType: Profile.self,
                forPrimaryKey: Profile.defaultIdentifier
            )

            return ProfileEntity(
                nickname: profile?.nickname ?? "",
                profileImageName: profile?.profileImageName ?? "",
                statusMessage: profile?.statusMessage ?? ""
            )
        }
    }

    func saveProfile(
        nickname: String,
        profileImageName: String,
        statusMessage: String
    ) async throws -> ProfileEntity {
        try await MainActor.run {
            let realm = try Realm(configuration: configuration)
            let updatedAt = Date()

            try realm.write {
                realm.create(
                    Profile.self,
                    value: [
                        "id": Profile.defaultIdentifier,
                        "nickname": nickname,
                        "profileImageName": profileImageName,
                        "statusMessage": statusMessage,
                        "updatedAt": updatedAt
                    ],
                    update: .modified
                )
            }

            let entity = ProfileEntity(
                nickname: nickname,
                profileImageName: profileImageName,
                statusMessage: statusMessage
            )

            NotificationCenter.default.post(
                name: .profileDidUpdate,
                object: nil,
                userInfo: [ProfileNotificationUserInfoKey.profileImageName: profileImageName]
            )

            return entity
        }
    }

}
