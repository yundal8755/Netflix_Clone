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
    case profileButtonTapped
}

struct HomeViewModelOutput {
    let sections: Observable<[HomeViewModel.Section]>
    let route: Observable<HomeViewModel.Route>
    let errorMessage: Observable<String>
}


// MARK: - ViewModel
final class HomeViewModel: BaseViewModel<HomeViewModelAction, HomeViewModelOutput> {
    struct Section {
        let title: String
        let items: [PosterItem]
    }

    enum Route {
        case profile
    }
    
    private let sectionsRelay = BehaviorRelay<[Section]>(value: [])
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let routeRelay = PublishRelay<Route>()
    private let errorMessageRelay = PublishRelay<String>()
    private let networkManager: NetworkManagerType

    init(networkManager: NetworkManagerType = NetworkManager()) {
        self.networkManager = networkManager
        
        let output = HomeViewModelOutput(
            sections: sectionsRelay.asObservable(),
            route: routeRelay.asObservable(),
            errorMessage: errorMessageRelay.asObservable()
        )
        
        super.init(output: output)
    }

    override func send(action: HomeViewModelAction) {
        switch action {
        case .viewDidLoad:
            fetchSections()
        case .profileButtonTapped:
            routeRelay.accept(.profile)
        }
    }
}


// MARK: - Network DTO
private extension HomeViewModel {
    // 1. api 호출
    private func fetchSections() {
        // viewDidLoad 이벤트가 중복으로 들어와도 요청을 한 번만 수행하도록 가드합니다.
        guard isLoadingRelay.value == false else { return }
        isLoadingRelay.accept(true)

        Single.zip(
            // 여러 Single이 모두 성공했을 때 결과를 한 번에 결합 -> 하나라도 실패시 전체 실패
            networkManager.fetchPopularMovies(),
            networkManager.fetchTrendingMovies(),
            networkManager.fetchActionMovies(),
            networkManager.fetchUpcomingMovies()
        )
        .subscribe(
            with: self,
            onSuccess: { owner, response in
                owner.isLoadingRelay.accept(false)

                let (popularMovies, trendingMovies, actionMovies, upcomingMovies) = response

                // 상태 데이터 갱신
                owner.sectionsRelay.accept(
                    owner.makeSections(
                        popularMovies: popularMovies,
                        trendingMovies: trendingMovies,
                        actionMovies: actionMovies,
                        upcomingMovies: upcomingMovies
                    )
                )
            },
            onFailure: { owner, error in
                owner.isLoadingRelay.accept(false)

                // 일회성 에러 이벤트 방출
                owner.errorMessageRelay.accept(owner.userFacingErrorMessage(from: error))
            }
        )
        .disposed(by: disposeBag)
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
                title: movie.displayTitle,
                posterURL: movie.posterImageURL
            )
        }
    }
}
