//
//  Profile.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RealmSwift

final class Profile: Object {
    static let defaultIdentifier = "default-profile"

    @Persisted(primaryKey: true) var id: String = Profile.defaultIdentifier
    @Persisted var nickname: String = ""
    @Persisted var profileImageName: String = ""
    @Persisted var statusMessage: String = ""
    @Persisted var updatedAt: Date = Date()

    convenience init(
        nickname: String,
        profileImageName: String,
        statusMessage: String
    ) {
        self.init()
        self.id = Profile.defaultIdentifier
        self.nickname = nickname
        self.profileImageName = profileImageName
        self.statusMessage = statusMessage
        self.updatedAt = Date()
    }
}
