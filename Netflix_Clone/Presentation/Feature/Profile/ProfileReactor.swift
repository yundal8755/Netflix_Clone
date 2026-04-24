//
//  ProfileReactor.swift
//  Netflix_Clone
//
//  Created by mac on 4/21/26.
//

import Foundation
import ReactorKit
import RxSwift

// 흐름
// Action -> mutate() -> Mutation -> reduce() -> State
@MainActor
final class ProfileReactor: Reactor {
    
    // 화면에 반영될 모든 상태값의 집합
    // struct인 이유: reduce()에서 복사본 만들어 수정하는 패턴 사용하므로
    struct State {
        var nickname: String = ""
        var statusMessage: String = ""
        var profileImageName: String = ""
        var isSaving: Bool = false
        
        // 일반 프로퍼티와 달리 같은 값 들어와도 무조건 방출
        // 저장되었습니다 알림이 2번 이상 뜰 수 있음
        @Pulse var showAlertText: String? = nil
    }
    
    // View -> Reactor로 전달되는 사용자의 의도 (View는 내부 로직 전혀 모름)
    enum Action: Equatable {
        case viewDidLoad
        case nicknameChanged(String)
        case statusMessageChanged(String)
        case profileImagePicked(Data)
        case saveButtonTapped
        case updateProfile
    }
    
    // State를 어떻게 바꿀 것인가 (명령)
    // 예) saveButtonTapped 액션 발생 -> isSaving(true), updateProfile(entity) 등
    enum Mutation {
        case updateProfile(ProfileEntity)
        case nicknameChanged(String)
        case statusMessageChanged(String)
        case profileImageChanged(String)
        case isSaving(Bool)
        case showSaveCompleted(String)
        case none
    }

    var initialState: State = State() // 시작값.

    private let repository = ProfileRepository.shared
}

extension ProfileReactor {

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoad:
            return .run(priority: .high) { [weak repository] send in
                guard let repository else { return }
                if Task.isCancelled { return }

                let result = try await repository.fetchProfile()
                await send(.updateProfile(result))
            }.catch { error in
                print(error)
                return .just(.none)
            }
            
        case let .nicknameChanged(text):
            return .just(.nicknameChanged(text))
            
        case let .statusMessageChanged(text):
            return .just(.statusMessageChanged(text))
            
        case let .profileImagePicked(data):
            do {
                let savedImagePath = try saveImageToDocuments(data: data)
                return .concat([
                    .just(.profileImageChanged(savedImagePath)),
                    .run { [weak repository, currentState] send in
                        guard let repository else { return }

                        let nickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
                        let statusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)

                        _ = try await repository.saveProfile(
                            nickname: nickname,
                            profileImageName: savedImagePath,
                            statusMessage: statusMessage
                        )

                    }.catch { error in
                        print(error)
                        return .just(.none)
                    }
                ])
            } catch {
                print(error)
                return .just(.none)
            }
            
        case .saveButtonTapped:
            guard currentState.isSaving == false else { return .empty() }

            let trimmedNickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedStatusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            let currentProfileImageName = currentState.profileImageName

            return .concat([
                .just(.isSaving(true)),
                .run {[weak repository] send in
                    guard let repository else { return }
                    if Task.isCancelled { return }

                    let entity = try await repository.saveProfile(
                        nickname: trimmedNickname,
                        profileImageName: currentProfileImageName,
                        statusMessage: trimmedStatusMessage
                    )

                    await send(.updateProfile(entity))
                    await send(.isSaving(false))
                    await send(.showSaveCompleted("프로필이 저장되었습니다."))
                }.catch { error in
                    print(error)
                    return .just(.isSaving(false))
                }
            ])
            
        default:
            return .just(.none)
        }
    }

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state

        switch mutation {
        case let .updateProfile(entity):
            state.profileImageName = entity.profileImageName
            state.nickname = entity.nickname
            state.statusMessage = entity.statusMessage
            
        case let .nicknameChanged(text):
            state.nickname = text
            
        case let .statusMessageChanged(text):
            state.statusMessage = text
            
        case let .profileImageChanged(text):
            state.profileImageName = text
            
        case let .isSaving(bool):
            state.isSaving = bool
            
        case let .showSaveCompleted(text):
            state.showAlertText = text

        default :
            break
        }

        return state
    }
    
    // NOTE: 다른 리엑터에서의 이벤트를 우리의 이벤트로 바꿀꺼다
    func transform(action: Observable<Action>) -> Observable<Action> {
        let repoAction = repository.updateEvent
            .map { _ in
                Action.updateProfile
            }
            
        return Observable.merge([
            action,
            repoAction
        ])
    }
}

// MARK: Logic
extension ProfileReactor {
    private func saveImageToDocuments(data: Data) throws -> String {
        guard let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            throw NSError(domain: "ProfileImage", code: -1)
        }

        let fileURL = documentsDirectory.appendingPathComponent("profile_user_image.jpg")
        try data.write(to: fileURL, options: .atomic)
        return fileURL.path
    }
}
