//
//  HomeViewModel.swift
//  Netflix_Clone
//
//  Created by mac on 4/3/26.
//

import Foundation
import RxSwift
import RxRelay // 네트워크 에러 발생시 버튼 클릭 이벤트가 UI에서 죽지 않는 장치

// 현재는 Input, Output
// 후에는 State, Action -> SwiftUI TCA
// 더 후에는 State, Mutation, Reduce -> ReactorKit

// MARK: - Action & Output
enum HomeViewModelAction {
    case viewDidLoad
    case viewWillAppear
    case searchButtonTapped
    case posterHeartTapped(PosterItem)
}

struct HomeViewModelOutput {
    let sections: Observable<[HomeViewModel.Section]>
    let likedMovieIDs: Observable<Set<Int>>
    let route: Observable<HomeCoordinatorCase>
    let errorMessage: Observable<String>
}


// MARK: - ViewModel
final class HomeViewModel: BaseViewModel<HomeViewModelAction, HomeViewModelOutput> {
    struct Section {
        let title: String
        let items: [PosterItem]
    }
    
    // 지속 상태라서 Behavior로 분리
    private let sectionsRelay = BehaviorRelay<[Section]>(value: [])
    private let likedMovieIDsRelay = BehaviorRelay<Set<Int>>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // 순간 신호라서 Publish로 분리
    private let routeRelay = PublishRelay<HomeCoordinatorCase>()
    private let errorMessageRelay = PublishRelay<String>()
    
    private let tmdbService: TMDBServiceType
    private let likedContentRepository: LikedContentRepositoryType
    private var fetchTask: Task<Void, Never>?

    init(
        tmdbService: TMDBServiceType = TMDBService(),
        likedContentRepository: LikedContentRepositoryType = LikedContentRepository.shared
    ) {
        self.tmdbService = tmdbService
        self.likedContentRepository = likedContentRepository
        
        let output = HomeViewModelOutput(
            sections: sectionsRelay.asObservable(),
            likedMovieIDs: likedMovieIDsRelay.asObservable(),
            route: routeRelay.asObservable(),
            errorMessage: errorMessageRelay.asObservable()
        )
        
        super.init(output: output)
    }

    override func send(action: HomeViewModelAction) {
        switch action {
        case .viewDidLoad:
            refreshLikedMovieIDs()
            fetchSections()
        case .viewWillAppear:
            refreshLikedMovieIDs()
        case .searchButtonTapped:
            routeRelay.accept(.searchView)
        case .posterHeartTapped(let posterItem):
            likedContentRepository.toggle(
                movieID: posterItem.movieID,
                title: posterItem.title,
                posterURL: posterItem.posterURL
            )
            refreshLikedMovieIDs()
        }
    }
}


// MARK: - Network DTO
private extension HomeViewModel {
    func refreshLikedMovieIDs() {
        let likedIDs = Set(likedContentRepository.fetchLikedPosters().map(\.movieID))
        likedMovieIDsRelay.accept(likedIDs)
    }

    // 1. api 호출
    private func fetchSections() {
        // viewDidLoad 이벤트가 중복으로 들어와도 요청을 한 번만 수행하도록 가드합니다.
        guard isLoadingRelay.value == false else { return }
        isLoadingRelay.accept(true)
        
        // TODO : GCD랑 Concurrency
        fetchTask?.cancel()
        
        // TODO : GCD랑 Concurrency
        fetchTask = Task {
            do {
                async let popular = tmdbService.requestPopular()
                async let trending = tmdbService.requestTrending()
                async let action = tmdbService.requestAction()
                async let upcoming = tmdbService.requestUpcoming()

                let response = try await (popular, trending, action, upcoming)
                
                let sections = makeSections(
                    popularMovies: response.0,
                    trendingMovies: response.1,
                    actionMovies: response.2,
                    upcomingMovies: response.3
                )

                await MainActor.run {
                    isLoadingRelay.accept(false)
                    sectionsRelay.accept(sections)
                }
            } catch {
                await MainActor.run {
                    isLoadingRelay.accept(false)
                    errorMessageRelay.accept(self.userFacingErrorMessage(from: error))
                }
            }
        }
    }
    
    // 에러 메시지
    func userFacingErrorMessage(from error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           description.isEmpty == false {
            return description
        }

        let description = error.localizedDescription
        return description.isEmpty ? "요청 중 알 수 없는 오류가 발생했습니다." : description
    }
    
    // 2. 각 카테고리 API 결과를 화면용 섹션 배열로 조합
    func makeSections(
        popularMovies: [TMDBMovieDTO],
        trendingMovies: [TMDBMovieDTO],
        actionMovies: [TMDBMovieDTO],
        upcomingMovies: [TMDBMovieDTO]
    ) -> [Section] {
        // 섹션 제목은 엔드포인트 정의(TMDBEndpoint)의 sectionTitle을 재사용
        return [
            Section(title: TMDBEndpoint.popular.sectionTitle, items: mapPosterItems(from: popularMovies)),
            Section(title: TMDBEndpoint.trending.sectionTitle, items: mapPosterItems(from: trendingMovies)),
            Section(title: TMDBEndpoint.action.sectionTitle, items: mapPosterItems(from: actionMovies)),
            Section(title: TMDBEndpoint.upcoming.sectionTitle, items: mapPosterItems(from: upcomingMovies))
        ]
    }

    // DTO -> PosterItem으로 변환 (최대 10개만 노출)
    func mapPosterItems(from movies: [TMDBMovieDTO]) -> [PosterItem] {
        movies.prefix(10).map { movie in
            PosterItem(
                movieID: movie.id,
                title: movie.displayTitle,
                posterURL: movie.posterImageURL
            )
        }
    }
}
