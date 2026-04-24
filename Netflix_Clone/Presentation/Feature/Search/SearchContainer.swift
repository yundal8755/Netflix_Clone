//
//  SearchContainer.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import Foundation


// MARK: - Container

final class SearchContainer: BaseMVIContainer {

    // MARK: State
    // View는 이것만 바라봐야 해요
    // 화면을 그릴 때 필요한 값을 한 곳에 모아둔 현재 상태
    struct State: Equatable {
        var inputText: String = ""
        var isValueEmpty: Bool = true
        var recommendedMovies: [ListTileContent] = []
        var searchViewMode: SearchViewMode = .beforeSearch
        var isLoadingRecommended: Bool = false

        var effect: SearchEffect?
    }

    // MARK: Intent
    // View는 이것만을 통해 이벤트를 쏴야해요
    // 사용자의 행동이나 생명주기 이벤트를 Container로 전달하는 통로
    enum Intent {
        case viewDidLoad
        case inputText(String) // 입력시
        case search(String) // 검색시
        case clickContent(Int) // 컨텐츠 클릭시
        case backButtonTapped

        case featureEvent(FeatureEvent)
    }
    
    enum SearchViewMode: Equatable {
        case beforeSearch
        case afterSearch
    }

    enum SearchEffect: Equatable {
        case clickContent(Int)
        case pop
        case showError(String)
    }

    enum FeatureEvent: Equatable {
        case requestData
        case updateData([ListTileContent])
    }

    let initialState: State
    private let tmdbService: TMDBServiceType
    private let tmdbMapper: TMDBMapperType
    private var recommendationTask: Task<Void, Never>?

    init(
        state: State = State(),
        tmdbService: TMDBServiceType = TMDBService(),
        tmdbMapper: TMDBMapperType = TMDBMapper()
    ) {
        self.initialState = state
        self.tmdbService = tmdbService
        self.tmdbMapper = tmdbMapper
    }

    @MainActor
    deinit {
        recommendationTask?.cancel()
        print("SearchContainer 제거")
    }
}


// MARK: - Logic

extension SearchContainer {

    // Intent를 실제 상태 변화나 비동기 작업으로 변환하는 곳
    func handle(_ intent: Intent, store: Store<SearchContainer>) {
        store.reduce { state in
            switch intent {
            case .viewDidLoad:
                store.send(.featureEvent(.requestData))

            case .inputText(let text):
                updateInputText(state: &state ,text)

            case .search(let text):
                updateInputText(state: &state, text)

            case .clickContent(let id):
                state.effect = .clickContent(id)

            case .backButtonTapped:
                state.effect = .pop

            // MARK: Feature Event
            case .featureEvent(.requestData):
                state.isLoadingRecommended = true // 동기적
                
                let task = Task {
                    if Task.isCancelled { return }
                    do {
                        let result = try await requestRecommendedMovies()
                        store.send(.featureEvent(.updateData(result)))
                    } catch {
                        print(error)
                    }
                }
                recommendationTask = task
            case let .featureEvent(.updateData(datas)):
                state.recommendedMovies = datas
                state.isLoadingRecommended = false
            }
        }
        
    }

    // 검색어 입력과 검색 실행은 같은 상태 값을 바꿔서 공통 처리함
    private func updateInputText(state: inout State, _ text: String) {
        state.inputText = text
        state.isValueEmpty = text.isEmpty
        state.searchViewMode = text.isEmpty ? .beforeSearch : .afterSearch
    }

    // 추천 영화 요청은 상태 변경과 비동기 작업 시작을 분리해서 처리함
    private func requestRecommendedMovies() async throws -> [ListTileContent] {
        let result = try await fetchRecommendedMovies()
        return result
    }

    private func fetchRecommendedMovies() async throws -> [ListTileContent] {
        let movies = try await tmdbService.requestPopular()
        let items = movies.prefix(20).map {
            ListTileContent(
                id: $0.id,
                title: $0.title ?? $0.name ?? "Untitled",
                posterUrl: self.tmdbMapper.mapPosterURL(from: $0.posterPath),
                playUrl: nil
            )
        }
        return items
    }
}
