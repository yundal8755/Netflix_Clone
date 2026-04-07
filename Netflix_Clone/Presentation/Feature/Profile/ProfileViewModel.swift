//
//  ProfileViewModel.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import Foundation
import RxRelay
import RxSwift

// MARK: - Input / Output Definitions

enum ProfileViewModelAction {
    case viewDidLoad
    case nicknameChanged(String)
    case statusMessageChanged(String)
    case profileImagePicked(Data)
    case saveButtonTapped
}

struct ProfileViewModelOutput {
    let viewState: Observable<ProfileViewModel.ViewState>
    let saveCompleted: Observable<String>
    let errorMessage: Observable<String>
}

final class ProfileViewModel: BaseViewModel<ProfileViewModelAction, ProfileViewModelOutput> {

    struct PosterContent: Hashable {
        let id: UUID
        let posterItem: PosterItem

        init(id: UUID = UUID(), posterItem: PosterItem) {
            self.id = id
            self.posterItem = posterItem
        }

        static func == (lhs: PosterContent, rhs: PosterContent) -> Bool {
            lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }

    struct ViewState {
        let nickname: String
        let statusMessage: String
        let profileImageName: String
        let isSaving: Bool
        let continueWatching: [PosterContent]
        let myList: [PosterContent]
    }

    private struct State {
        var nickname: String = ""
        var statusMessage: String = ""
        var profileImageName: String = ""
        var isSaving: Bool = false
        var continueWatching: [PosterContent]
        var myList: [PosterContent]

        init(
            continueWatching: [PosterContent],
            myList: [PosterContent]
        ) {
            self.continueWatching = continueWatching
            self.myList = myList
        }
    }

    private let stateRelay: BehaviorRelay<State>
    private let saveCompletedRelay = PublishRelay<String>()
    private let errorMessageRelay = PublishRelay<String>()

    private var currentTask: Task<Void, Never>?
    private var profileImageSaveTask: Task<Void, Never>?

    private let repository: ProfileRepositoryType

    init(
        repository: ProfileRepositoryType = ProfileRepository(),
        continueWatchingItems: [PosterItem] = [],
        myListItems: [PosterItem] = []
    ) {
        self.repository = repository
        let fallbackContinueWatching = Self.makeContinueWatchingContents()
        let fallbackMyList = Self.makeMyListContents()
        let initialContinueWatching = Self.makePosterContents(
            from: continueWatchingItems,
            fallback: fallbackContinueWatching
        )
        let initialMyList = Self.makePosterContents(
            from: myListItems,
            fallback: fallbackMyList
        )
        self.stateRelay = BehaviorRelay(
            value: State(
                continueWatching: initialContinueWatching,
                myList: initialMyList
            )
        )

        let output = ProfileViewModelOutput(
            viewState: stateRelay
                .map { state in
                    ViewState(
                        nickname: state.nickname,
                        statusMessage: state.statusMessage,
                        profileImageName: state.profileImageName,
                        isSaving: state.isSaving,
                        continueWatching: state.continueWatching,
                        myList: state.myList
                    )
                }
                .asObservable(),
            saveCompleted: saveCompletedRelay.asObservable(),
            errorMessage: errorMessageRelay.asObservable()
        )

        super.init(output: output)
    }

    override func send(action: ProfileViewModelAction) {
        switch action {
        case .viewDidLoad:
            fetchProfile()
        case .nicknameChanged(let nickname):
            updateState { state in
                state.nickname = nickname
            }
        case .statusMessageChanged(let statusMessage):
            updateState { state in
                state.statusMessage = statusMessage
            }
        case .profileImagePicked(let imageData):
            updateProfileImage(with: imageData)
        case .saveButtonTapped:
            saveProfile()
        }
    }

    private func fetchProfile() {
        currentTask?.cancel()

        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let entity = try await repository.fetchProfile()
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    self.updateState { state in
                        state.nickname = entity.nickname
                        state.statusMessage = entity.statusMessage
                        state.profileImageName = entity.profileImageName
                    }
                }
            } catch {
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    self.errorMessageRelay.accept(error.localizedDescription)
                }
            }
        }
    }

    private func saveProfile() {
        let currentState = stateRelay.value
        guard currentState.isSaving == false else { return }

        let trimmedNickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStatusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        let currentProfileImageName = currentState.profileImageName

        updateState { state in
            state.isSaving = true
        }

        currentTask?.cancel()

        currentTask = Task { [weak self] in
            guard let self else { return }

            do {
                let entity = try await repository.saveProfile(
                    nickname: trimmedNickname,
                    profileImageName: currentProfileImageName,
                    statusMessage: trimmedStatusMessage
                )
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    self.updateState { state in
                        state.nickname = entity.nickname
                        state.statusMessage = entity.statusMessage
                        state.profileImageName = entity.profileImageName
                        state.isSaving = false
                    }
                    self.saveCompletedRelay.accept("프로필이 저장되었습니다.")
                }
            } catch {
                guard Task.isCancelled == false else { return }

                await MainActor.run {
                    self.updateState { state in
                        state.isSaving = false
                    }
                    self.errorMessageRelay.accept(error.localizedDescription)
                }
            }
        }
    }

    private func updateProfileImage(with imageData: Data) {
        do {
            let savedImagePath = try saveImageToDocuments(data: imageData)
            updateState { state in
                state.profileImageName = savedImagePath
            }
            persistProfileImage(savedImagePath)
        } catch {
            errorMessageRelay.accept("프로필 이미지 저장에 실패했습니다.")
        }
    }

    private func persistProfileImage(_ profileImageName: String) {
        profileImageSaveTask?.cancel()

        let currentState = stateRelay.value
        let nickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let statusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)

        profileImageSaveTask = Task { [weak self] in
            guard let self else { return }

            do {
                _ = try await repository.saveProfile(
                    nickname: nickname,
                    profileImageName: profileImageName,
                    statusMessage: statusMessage
                )
                guard Task.isCancelled == false else { return }
            } catch {
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    self.errorMessageRelay.accept("프로필 이미지 저장에 실패했습니다.")
                }
            }
        }
    }

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

    private func updateState(_ mutation: (inout State) -> Void) {
        var state = stateRelay.value
        mutation(&state)
        stateRelay.accept(state)
    }
}

private extension ProfileViewModel {
    static func makePosterContents(
        from items: [PosterItem],
        fallback: [PosterContent]
    ) -> [PosterContent] {
        guard items.isEmpty == false else { return fallback }
        return items.map { item in
            PosterContent(posterItem: item)
        }
    }

    static func makeContinueWatchingContents() -> [PosterContent] {
        let titles = [
            "The Last Kingdom",
            "Dark City",
            "Silent River",
            "Moonlight Run",
            "Night Shift",
            "Code Black"
        ]

        return titles.enumerated().map { index, title in
            PosterContent(
                posterItem: PosterItem(
                    title: title,
                    posterURL: URL(string: "https://picsum.photos/id/\(index + 101)/300/450")
                )
            )
        }
    }

    static func makeMyListContents() -> [PosterContent] {
        let titles = [
            "Red Notice",
            "Arcane",
            "The Crown",
            "Squid Game",
            "Breaking Point",
            "Wednesday",
            "Extraction",
            "Lucifer",
            "The Witcher",
            "Mindhunter",
            "Beef",
            "Narcos"
        ]

        return titles.enumerated().map { index, title in
            PosterContent(
                posterItem: PosterItem(
                    title: title,
                    posterURL: URL(string: "https://picsum.photos/id/\(index + 131)/300/450")
                )
            )
        }
    }
}
