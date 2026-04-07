//
//  Profile.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RealmSwift

final class Profile: Object {
    nonisolated static let defaultIdentifier = "default-profile"

    @Persisted(primaryKey: true) var id: String = Profile.defaultIdentifier
    @Persisted var nickname: String = ""
    @Persisted var profileImageName: String = ""
    @Persisted var statusMessage: String = ""
    @Persisted var updatedAt: Date = Date()
}
