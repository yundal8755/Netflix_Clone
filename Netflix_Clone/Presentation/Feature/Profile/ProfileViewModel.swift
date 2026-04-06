//
//  ProfileViewModel.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RxRelay
import RxSwift

enum ProfileViewModelInput {
    case viewDidLoad
    case saveButtonTapped(nickname: String, statusMessage: String)
}

struct ProfileViewModelOutput {
    let nickname: Observable<String>
    let statusMessage: Observable<String>
    let profileImageName: Observable<String>
    let isSaving: Observable<Bool>
    let saveCompleted: Observable<String>
    let errorMessage: Observable<String>
}

final class ProfileViewModel {
    private struct State {
        var nickname: String
        var statusMessage: String
        var profileImageName: String
        var isSaving: Bool

        static func initial() -> State {
            State(
                nickname: "",
                statusMessage: "",
                profileImageName: "",
                isSaving: false
            )
        }
    }

    let input = PublishRelay<ProfileViewModelInput>()
    let output: ProfileViewModelOutput

    private let stateRelay = BehaviorRelay<State>(value: .initial())
    private let saveCompletedRelay = PublishRelay<String>()
    private let errorMessageRelay = PublishRelay<String>()
    private let disposeBag = DisposeBag()
    private let repository: ProfileRepositoryType

    init(repository: ProfileRepositoryType = ProfileRepository()) {
        self.repository = repository

        output = ProfileViewModelOutput(
            nickname: stateRelay
                .asObservable()
                .map { $0.nickname }
                .distinctUntilChanged(),
            statusMessage: stateRelay
                .asObservable()
                .map { $0.statusMessage }
                .distinctUntilChanged(),
            profileImageName: stateRelay
                .asObservable()
                .map { $0.profileImageName }
                .distinctUntilChanged(),
            isSaving: stateRelay
                .asObservable()
                .map { $0.isSaving }
                .distinctUntilChanged(),
            saveCompleted: saveCompletedRelay.asObservable(),
            errorMessage: errorMessageRelay.asObservable()
        )

        bindInput()
    }

    private func bindInput() {
        input
            .subscribe(with: self) { owner, input in
                switch input {
                case .viewDidLoad:
                    owner.fetchProfile()

                case let .saveButtonTapped(nickname, statusMessage):
                    owner.saveProfile(
                        nickname: nickname,
                        statusMessage: statusMessage
                    )
                }
            }
            .disposed(by: disposeBag)
    }

    private func fetchProfile() {
        repository.fetchProfile()
            .subscribe(with: self) { owner, entity in
                owner.updateState { state in
                    state.nickname = entity.nickname
                    state.statusMessage = entity.statusMessage
                    state.profileImageName = entity.profileImageName
                }
            } onFailure: { owner, error in
                owner.errorMessageRelay.accept(error.localizedDescription)
            }
            .disposed(by: disposeBag)
    }

    private func saveProfile(
        nickname: String,
        statusMessage: String
    ) {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStatusMessage = statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        updateState { state in
            state.isSaving = true
        }

        repository.saveProfile(
            nickname: trimmedNickname,
            profileImageName: stateRelay.value.profileImageName,
            statusMessage: trimmedStatusMessage
        )
        .subscribe(with: self) { owner, entity in
            owner.updateState { state in
                state.nickname = entity.nickname
                state.statusMessage = entity.statusMessage
                state.profileImageName = entity.profileImageName
                state.isSaving = false
            }
            owner.saveCompletedRelay.accept("프로필이 저장되었습니다.")
        } onFailure: { owner, error in
            owner.updateState { state in
                state.isSaving = false
            }
            owner.errorMessageRelay.accept(error.localizedDescription)
        }
        .disposed(by: disposeBag)
    }

    private func updateState(_ transform: (inout State) -> Void) {
        var currentState = stateRelay.value
        transform(&currentState)
        stateRelay.accept(currentState)
    }
}
