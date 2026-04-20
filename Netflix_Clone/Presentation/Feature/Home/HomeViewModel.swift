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
    
    // BehaviorRelay : State를 기억하는 놈
    // 누군가 새로 구독하면 상태를 즉시 알려줌
    // ex) 현재 텍스트가 뭐야? 스위치가 켜졌어?
    private let sectionsRelay = BehaviorRelay<[Section]>(value: [])
    private let likedMovieIDsRelay = BehaviorRelay<Set<Int>>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    
    // PublishRelay : Event를 쏘는 놈
    // 기억x, 화면에 무언가를 일회성으로 실행시킬 때 사용
    // ex) 다음 화면으로 넘어가, Alert 띄워
    private let routeRelay = PublishRelay<HomeCoordinatorCase>()
    private let errorMessageRelay = PublishRelay<String>()
    
    private let tmdbService: TMDBServiceType
    private let tmdbMapper: TMDBMapperType
    private let likedContentRepository: LikedContentRepositoryType
    private var fetchTask: Task<Void, Never>?

    init(
        tmdbService: TMDBServiceType = TMDBService(),
        tmdbMapper: TMDBMapperType = TMDBMapper(),
        likedContentRepository: LikedContentRepositoryType = LikedContentRepository.shared
    ) {
        self.tmdbService = tmdbService
        self.tmdbMapper = tmdbMapper
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
            fetchSections() // api 호출
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
        guard isLoadingRelay.value == false else { return }
        isLoadingRelay.accept(true)
        
        // 이전에 요청한 네트워크 작업 돌고있다면 취소시킴
        fetchTask?.cancel()
        
        // Task {...} : 비동기 코드 실행임을 선언
        fetchTask = Task {
            do {
                // 벙렬 실행
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
                
                // 기존 GCD에서 쓰던 DispatchQueue.main.async의 최신 버전
                // 메인 스레드를 의미
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
        popularMovies: [TMDBMovieEntity],
        trendingMovies: [TMDBMovieEntity],
        actionMovies: [TMDBMovieEntity],
        upcomingMovies: [TMDBMovieEntity]
    ) -> [Section] {
        // 섹션 제목은 엔드포인트 정의(TMDBEndpoint)의 sectionTitle을 재사용
        return [
            Section(title: TMDBSession.popular.sectionTitle, items: mapPosterItems(from: popularMovies)),
            Section(title: TMDBSession.trending.sectionTitle, items: mapPosterItems(from: trendingMovies)),
            Section(title: TMDBSession.action.sectionTitle, items: mapPosterItems(from: actionMovies)),
            Section(title: TMDBSession.upcoming.sectionTitle, items: mapPosterItems(from: upcomingMovies))
        ]
    }

    // Entity -> PosterItem으로 변환 (최대 10개만 노출)
    func mapPosterItems(from movies: [TMDBMovieEntity]) -> [PosterItem] {
        tmdbMapper.mapPosterItems(from: movies)
    }
}

enum TMDBSession: CaseIterable {
    case popular
    case trending
    case action
    case upcoming

    var sectionTitle: String {
        switch self {
        case .popular:
            return "Popular"
        case .trending:
            return "Trend"
        case .action:
            return "Action"
        case .upcoming:
            return "Upcomming"
        }
    }
}
