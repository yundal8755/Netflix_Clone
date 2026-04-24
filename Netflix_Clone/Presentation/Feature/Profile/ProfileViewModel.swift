////
////  ProfileViewModel.swift
////  Netflix_Clone
////
////  Created by Codex on 4/6/26.
////
//
//import Foundation
//import RxRelay
//import RxSwift
//
//// MARK: - Input / Output Definitions
//
//enum ProfileViewModelAction {
//    case viewDidLoad
//    case nicknameChanged(String)
//    case statusMessageChanged(String)
//    case profileImagePicked(Data)
//    case saveButtonTapped
//}
//
//struct ProfileViewModelOutput {
//    let viewState: Observable<ProfileViewModel.ViewState>
//    let saveCompleted: Observable<String>
//    let errorMessage: Observable<String>
//}
//
//final class ProfileViewModel: BaseViewModel<ProfileViewModelAction, ProfileViewModelOutput> {
//
//    struct ViewState {
//        let nickname: String
//        let statusMessage: String
//        let profileImageName: String
//        let isSaving: Bool
//    }
//
//    private struct State {
//        var nickname: String = ""
//        var statusMessage: String = ""
//        var profileImageName: String = ""
//        var isSaving: Bool = false
//    }
//
//    private let stateRelay = BehaviorRelay<State>(value: State())
//    private let saveCompletedRelay = PublishRelay<String>()
//    private let errorMessageRelay = PublishRelay<String>()
//
//    private var currentTask: Task<Void, Never>?
//    private var profileImageSaveTask: Task<Void, Never>?
//
//    private let repository: ProfileRepositoryType
//
//    init(repository: ProfileRepositoryType = ProfileRepository()) {
//        self.repository = repository
//
//        let output = ProfileViewModelOutput(
//            viewState: stateRelay
//                .map { state in
//                    ViewState(
//                        nickname: state.nickname,
//                        statusMessage: state.statusMessage,
//                        profileImageName: state.profileImageName,
//                        isSaving: state.isSaving
//                    )
//                }
//                .asObservable(),
//            saveCompleted: saveCompletedRelay.asObservable(),
//            errorMessage: errorMessageRelay.asObservable()
//        )
//
//        super.init(output: output)
//    }
//
//    override func send(action: ProfileViewModelAction) {
//        switch action {
//        case .viewDidLoad:
//            fetchProfile()
//        case .nicknameChanged(let nickname):
//            updateState { state in
//                state.nickname = nickname
//            }
//        case .statusMessageChanged(let statusMessage):
//            updateState { state in
//                state.statusMessage = statusMessage
//            }
//        case .profileImagePicked(let imageData):
//            updateProfileImage(with: imageData)
//        case .saveButtonTapped:
//            saveProfile()
//        }
//    }
//
//    private func fetchProfile() {
//        currentTask?.cancel()
//
//        currentTask = Task { [weak self] in
//            guard let self else { return }
//
//            do {
//                let entity = try await repository.fetchProfile()
//                guard Task.isCancelled == false else { return }
//
//                await MainActor.run {
//                    self.updateState { state in
//                        state.nickname = entity.nickname
//                        state.statusMessage = entity.statusMessage
//                        state.profileImageName = entity.profileImageName
//                    }
//                }
//            } catch {
//                guard Task.isCancelled == false else { return }
//
//                await MainActor.run {
//                    self.errorMessageRelay.accept(error.localizedDescription)
//                }
//            }
//        }
//    }
//
//    private func saveProfile() {
//        let currentState = stateRelay.value
//        guard currentState.isSaving == false else { return }
//
//        let trimmedNickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
//        let trimmedStatusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
//        let currentProfileImageName = currentState.profileImageName
//
//        updateState { state in
//            state.isSaving = true
//        }
//
//        currentTask?.cancel()
//
//        currentTask = Task { [weak self] in
//            guard let self else { return }
//
//            do {
//                let entity = try await repository.saveProfile(
//                    nickname: trimmedNickname,
//                    profileImageName: currentProfileImageName,
//                    statusMessage: trimmedStatusMessage
//                )
//                guard Task.isCancelled == false else { return }
//
//                await MainActor.run {
//                    self.updateState { state in
//                        state.nickname = entity.nickname
//                        state.statusMessage = entity.statusMessage
//                        state.profileImageName = entity.profileImageName
//                        state.isSaving = false
//                    }
//                    self.saveCompletedRelay.accept("프로필이 저장되었습니다.")
//                }
//            } catch {
//                guard Task.isCancelled == false else { return }
//
//                await MainActor.run {
//                    self.updateState { state in
//                        state.isSaving = false
//                    }
//                    self.errorMessageRelay.accept(error.localizedDescription)
//                }
//            }
//        }
//    }
//
//    private func updateProfileImage(with imageData: Data) {
//        do {
//            let savedImagePath = try saveImageToDocuments(data: imageData)
//            updateState { state in
//                state.profileImageName = savedImagePath
//            }
//            persistProfileImage(savedImagePath)
//        } catch {
//            errorMessageRelay.accept("프로필 이미지 저장에 실패했습니다.")
//        }
//    }
//
//    private func persistProfileImage(_ profileImageName: String) {
//        profileImageSaveTask?.cancel()
//
//        let currentState = stateRelay.value
//        let nickname = currentState.nickname.trimmingCharacters(in: .whitespacesAndNewlines)
//        let statusMessage = currentState.statusMessage.trimmingCharacters(in: .whitespacesAndNewlines)
//
//        profileImageSaveTask = Task { [weak self] in
//            guard let self else { return }
//
//            do {
//                _ = try await repository.saveProfile(
//                    nickname: nickname,
//                    profileImageName: profileImageName,
//                    statusMessage: statusMessage
//                )
//                guard Task.isCancelled == false else { return }
//            } catch {
//                guard Task.isCancelled == false else { return }
//                await MainActor.run {
//                    self.errorMessageRelay.accept("프로필 이미지 저장에 실패했습니다.")
//                }
//            }
//        }
//    }
//
//    private func saveImageToDocuments(data: Data) throws -> String {
//        guard let documentsDirectory = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        ).first else {
//            throw NSError(domain: "ProfileImage", code: -1)
//        }
//
//        let fileURL = documentsDirectory.appendingPathComponent("profile_user_image.jpg")
//        try data.write(to: fileURL, options: .atomic)
//        return fileURL.path
//    }
//
//    private func updateState(_ mutation: (inout State) -> Void) {
//        var state = stateRelay.value
//        mutation(&state)
//        stateRelay.accept(state)
//    }
//}
