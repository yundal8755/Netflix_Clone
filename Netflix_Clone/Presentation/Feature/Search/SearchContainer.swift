//
//  SearchContainer.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import Foundation


// MARK: - State, Intent, Effect

struct SearchState: Equatable { // View 는 이것만 바라봐야 해요
    var inputText: String = ""
    var isValueEmpty: Bool = true
    var recommendedMovies: [ListTileContent] = []
    var searchViewMode: SearchViewMode = .beforeSearch
    var isLoadingRecommended: Bool = false
    
    var effect: SearchEffect?
}

enum SearchIntent { // View는 이것만을 통해 이벤트를 쏴야해요
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


// MARK: - Container

final class SearchContainer: BaseContainer<SearchState, SearchIntent> {
    private let tmdbService: TMDBServiceType
    private let tmdbMapper: TMDBMapperType
    private var recommendationTask: Task<Void, Never>?
    
    init(
        state: SearchState = SearchState(),
        tmdbService: TMDBServiceType = TMDBService(),
        tmdbMapper: TMDBMapperType = TMDBMapper()
    ) {
        self.tmdbService = tmdbService
        self.tmdbMapper = tmdbMapper
        super.init(initialState: state)
    }

    override func handle(_ intent: SearchIntent) {
        reduce { state in
            switch intent {
            case .viewDidLoad:
                handle(.featureEvent(.requestData))
                
            case .inputText(let text):
                state.inputText = text
                state.isValueEmpty = text.isEmpty
                state.searchViewMode = text.isEmpty ? .beforeSearch : .afterSearch
                
            case .search(let text):
                state.inputText = text
                state.isValueEmpty = text.isEmpty
                state.searchViewMode = text.isEmpty ? .beforeSearch : .afterSearch
                
            case .clickContent(let id):
                state.effect = .clickContent(id)
                
            case .backButtonTapped:
                state.effect = .pop
                
            // MARK: Feature Event
            case .featureEvent(.requestData):
                state.isLoadingRecommended = true
                recommendationTask?.cancel()
                
                let task = Task {
                    if Task.isCancelled { return }
                    do {
                        let result = try await fetchRecommendedMovies()
                        handle(.featureEvent(.updateData(result)))
                    } catch {
                        print("ERROR: \(error)")
                    }
                }
                
                recommendationTask = task
                
            case let .featureEvent(.updateData(datas)):
                state.recommendedMovies = datas
                state.isLoadingRecommended = false
            }
        }
        
    }
    
    @MainActor
    deinit {
        recommendationTask?.cancel()
        print("SearchContainer 제거")
    }
}


// MARK: - Logic

extension SearchContainer {
    
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
