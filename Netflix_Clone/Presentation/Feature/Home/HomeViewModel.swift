//
//  HomeViewModel.swift
//  Netflix_Clone
//
//  Created by mac on 4/3/26.
//

import Foundation
import RxSwift
import RxRelay // 네트워크 에러 발생시 버튼 클릭 이벤트가 UI에서 죽지 않는 장치

// MARK: - Input , Output
// INPUT
enum HomeViewModelInput {
    case viewDidLoad
    case profileButtonTapped
    case sectionSelected(index: Int)
    case didFinishRouting
}

// OUTPUT
// 상속도 필요없고 데이터를 직접 들고 있는 게 아니라서 struct 사용함
// class에 비해 훨씬 가벼움
// Q1. Input과 달리 Output은 struct인 이유
// A1. input은 하나의 사건만 존재하지만, output은 여러 사건이 존재할 수 있는 상태이므로 enum이 될 수 없음
struct HomeViewModelOutput {
    // Observable: 상태관리할 데이터 - 앞으로 데이터 바뀔 때마다 여기로 새 데이터 흘려보낼게
    let sections: Observable<[HomeViewModel.Section]>
    let route: Observable<HomeViewModel.Route>
    let errorMessage: Observable<String>
}



// MARK: - HomeViewModel
final class HomeViewModel {
    struct Section {
        let title: String
        let items: [PosterItem]
    }

    enum Route {
        case profile
    }

    private struct State {
        var sections: [Section]
        var route: Route?
        var errorMessage: String?

        static func initial() -> State {
            State(sections: [], route: nil, errorMessage: nil)
        }
    }
    
    // PublishRelay<T> : 구독한 이후에 발생하는 이벤트만 전달함
    let input = PublishRelay<HomeViewModelInput>()
    let output: HomeViewModelOutput
    
    // BehaviorRelay<T> : 생성할 때 초기값 반드시 필요하고, 구독하는 순간 가장 최신값 하나를 바로 던짐
    // State에 쓰는 이유 -> 화면은 항상 어떤 상태(데이터)인지 보여줘야 하고, .value를 통해 직접 값 꺼내기 위해
    private let stateRelay = BehaviorRelay<State>(value: .initial())
    private let disposeBag = DisposeBag()
    private let networkManager: NetworkManagerType

    init(networkManager: NetworkManagerType = NetworkManager()) {
        self.networkManager = networkManager

        // 1. 출력 스트림(Observable)을 미리 정의함
        // output을 먼저 정의하는 이유 : Swift 자체가 output이 값을 갖기 전에 input 가질 수 없도록 제한함
        output = HomeViewModelOutput(
            // stateRelay를 관찰하고 있다가 sections 값 바뀌면 자동 발화
            sections: stateRelay
                // 읽기/쓰기 다 가능한 Relay를 읽기 전용인 Obsevable로 변환함
                // 이유 -> vc에서 마음대로 accept로 조작하면 안되기 때문에 캡슐화하는 작업
                .asObservable()
            
                // 들어온 데이터를 원하는 형태로 변형함
                // $0은 전체 State를 의미하며, 그 안의 sections만 쏙 골라냄
                .map { $0.sections },
            route: stateRelay
                .asObservable()
                .map { $0.route }
                // 옵셔널값중 nil은 걸러내고, 값이 있는 것만 통과시킴
                .compactMap { $0 },
            errorMessage: stateRelay
                .asObservable()
                .map { $0.errorMessage }
                .compactMap { $0 }
                .distinctUntilChanged()
        )
        
        // 2. 해당 메서드 호출
        bindInput()
    }

    private func bindInput() {
        // 3. 뷰모델이 input을 받을 준비를 함
        // 이제 ViewController로 다시 이동
        input
            // subscribe : 경청하겠다
            // owner = self 자신
            .subscribe(with: self) { owner, input in
                switch input {
                
                // HomeViewController로부터 viewDidLoad가 실행됐을 때
                case .viewDidLoad:
                    owner.fetchSections()

                case .profileButtonTapped:
                    owner.updateState { state in
                        state.route = .profile
                    }

                case .sectionSelected:
                    break

                case .didFinishRouting:
                    owner.updateState { state in
                        state.route = nil
                    }
                }
            }
            .disposed(by: disposeBag)
    }

    private func fetchSections() {
        Single.zip(
            networkManager.fetchPopularMovies(),
            networkManager.fetchTrendingMovies(),
            networkManager.fetchActionMovies(),
            networkManager.fetchUpcomingMovies()
        )
        .map { [weak self] popularMovies, trendingMovies, actionMovies, upcomingMovies in
            guard let self else { return [] }

            return self.makeSections(
                popularMovies: popularMovies,
                trendingMovies: trendingMovies,
                actionMovies: actionMovies,
                upcomingMovies: upcomingMovies
            )
        }
        .subscribe(
            with: self,
            onSuccess: { (owner: HomeViewModel, sections: [HomeViewModel.Section]) in
                owner.updateState { state in
                    state.sections = sections
                    state.errorMessage = nil
                }
            },
            onFailure: { (owner: HomeViewModel, error: Error) in
                owner.updateState { state in
                    state.errorMessage = error.localizedDescription
                }
            }
        )
        .disposed(by: disposeBag)
    }
    
    // BehaviorRelay에 새 State 저장
    // 구독중인 output이 자동 발화
    private func updateState(_ transform: (inout State) -> Void) {
        var currentState = stateRelay.value // 1. 현재 값 복사
        transform(&currentState)            // 2. 값 수정 (inout이라 원본이 바뀜)
        stateRelay.accept(currentState)     // 3. 바뀐 값으로 교체
    }
}



// MARK: - Private Methods (Data Generation)
// HomeView 아이템 목록들에 대한 더미데이터
private extension HomeViewModel {
    
    func makeSections(
        popularMovies: [TMDBMovieDTO],
        trendingMovies: [TMDBMovieDTO],
        actionMovies: [TMDBMovieDTO],
        upcomingMovies: [TMDBMovieDTO]
    ) -> [Section] {
        return [
            Section(title: TMDBEndpoint.popular.sectionTitle, items: mapPosterItems(from: popularMovies)),
            Section(title: TMDBEndpoint.trending.sectionTitle, items: mapPosterItems(from: trendingMovies)),
            Section(title: TMDBEndpoint.action.sectionTitle, items: mapPosterItems(from: actionMovies)),
            Section(title: TMDBEndpoint.upcoming.sectionTitle, items: mapPosterItems(from: upcomingMovies))
        ]
    }

    func mapPosterItems(from movies: [TMDBMovieDTO]) -> [PosterItem] {
        movies.prefix(10).map { movie in
            PosterItem(
                title: movie.displayTitle,
                posterURL: movie.posterImageURL
            )
        }
    }
}
