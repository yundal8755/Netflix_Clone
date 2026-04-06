//
//  ProfileRepository.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RealmSwift
import RxSwift

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

protocol ProfileRepositoryType {
    func fetchProfile() -> Single<ProfileEntity>
    func saveProfile(
        nickname: String,
        profileImageName: String,
        statusMessage: String
    ) -> Single<ProfileEntity>
}

final class ProfileRepository: ProfileRepositoryType {
    private let configuration: Realm.Configuration

    init(configuration: Realm.Configuration = .defaultConfiguration) {
        self.configuration = configuration
    }

    func fetchProfile() -> Single<ProfileEntity> {
        Single.create { [configuration] single in
            do {
                let realm = try Realm(configuration: configuration)
                let profile = realm.object(ofType: Profile.self, forPrimaryKey: Profile.defaultIdentifier)

                let entity = ProfileEntity(
                    nickname: profile?.nickname ?? "",
                    profileImageName: profile?.profileImageName ?? "",
                    statusMessage: profile?.statusMessage ?? ""
                )

                single(.success(entity))
            } catch {
                single(.failure(error))
            }

            return Disposables.create()
        }
    }

    func saveProfile(
        nickname: String,
        profileImageName: String,
        statusMessage: String
    ) -> Single<ProfileEntity> {
        Single.create { [configuration] single in
            do {
                let realm = try Realm(configuration: configuration)
                let profile = Profile(
                    nickname: nickname,
                    profileImageName: profileImageName,
                    statusMessage: statusMessage
                )

                try realm.write {
                    realm.add(profile, update: .modified)
                }

                single(.success(
                    ProfileEntity(
                        nickname: profile.nickname,
                        profileImageName: profile.profileImageName,
                        statusMessage: profile.statusMessage
                    )
                ))
            } catch {
                single(.failure(error))
            }

            return Disposables.create()
        }
    }
}
