//
//  LikeViewModel.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

// Foundation은 URL, 배열, 딕셔너리, NotificationCenter 등 기본 타입/유틸을 제공합니다.
import Foundation
// RxCocoa는 UIKit 컴포넌트와 Rx를 연결하기 위한 확장 집합입니다.
import RxCocoa
// RxRelay는 error/completed 없이 값 전달에 특화된 Relay 타입을 제공합니다.
import RxRelay
// RxSwift는 Observable 기반 반응형 스트림 코어 라이브러리입니다.
import RxSwift

// View에서 ViewModel로 보내는 "의도(Intent)"를 정의합니다.
// MVI에서 Action은 "사용자가 무엇을 했는가"를 나타냅니다.
enum LikeViewAction {
    // 화면이 처음 로딩되었을 때 호출되는 액션입니다.
    case viewDidLoad
    // 상단 새로고침 버튼이 눌렸을 때 호출되는 액션입니다.
    case refreshButtonTapped
    // 외부(Home/Like 등)에서 좋아요 데이터가 변경되었음을 알리는 액션입니다.
    case likedContentChanged
}

// Action을 처리한 뒤 상태를 어떻게 바꿀지 표현하는 "변경 단위"입니다.
// MVI에서 Mutation은 "상태를 어떤 값으로 업데이트할 것인가"를 나타냅니다.
enum LikeViewMutation {
    // 로딩 플래그를 변경합니다.
    case setLoading(Bool)
    // "시청 중인 콘텐츠" 섹션 데이터를 통째로 갱신합니다.
    case setContinueWatching([LikePosterContent])
    // "내가 찜한 콘텐츠" 섹션 데이터를 통째로 갱신합니다.
    case setMyList([LikePosterContent])
    // 에러 메시지 상태를 변경합니다.
    case setErrorMessage(String?)
}

// 컬렉션뷰에서 공통으로 사용하는 포스터 아이템 래퍼 모델입니다.
// Hashable 채택 이유: Diffable Data Source의 식별/변경 추적에 유리합니다.
struct LikePosterContent: Hashable {
    // 섹션 내부에서 아이템을 식별하는 고유 id입니다.
    // 여기서는 movieID를 기본 식별자로 사용합니다.
    let id: Int
    // 실제 셀에 표시할 포스터 데이터(제목, 이미지 URL 등)입니다.
    let posterItem: PosterItem

    // 외부에서 id를 명시하지 않으면 movieID를 id로 사용합니다.
    // 이렇게 하면 호출부가 간결해지고, 기본 식별 규칙이 일관됩니다.
    init(id: Int? = nil, posterItem: PosterItem) {
        // id가 전달되면 그 값을 사용하고, 아니면 posterItem.movieID를 사용합니다.
        self.id = id ?? posterItem.movieID
        // 전달받은 포스터 아이템을 저장합니다.
        self.posterItem = posterItem
    }

    // Equatable 비교 기준을 id 하나로 고정합니다.
    // 이유: 같은 movieID면 같은 콘텐츠로 취급하기 위함입니다.
    static func == (lhs: LikePosterContent, rhs: LikePosterContent) -> Bool {
        // 두 값의 id가 같으면 같은 아이템으로 판단합니다.
        lhs.id == rhs.id
    }

    // Hashable 해시 생성 시에도 id만 반영합니다.
    // Equatable 기준과 Hashable 기준을 맞춰야 컬렉션/디프 동작이 안정적입니다.
    func hash(into hasher: inout Hasher) {
        // id 값을 해시에 반영합니다.
        hasher.combine(id)
    }
}

// 화면 전체 상태(State)를 모아두는 구조체입니다.
// MVI에서 View는 이 State 하나만 바라보고 렌더링합니다.
struct LikeViewState: Equatable {
    // 새로고침 버튼 활성화/로딩 인디케이션 판단용 플래그입니다.
    var isLoading: Bool = false
    // "시청 중인 콘텐츠" 섹션 데이터입니다.
    var continueWatching: [LikePosterContent] = []
    // "내가 찜한 콘텐츠" 섹션 데이터입니다.
    var myList: [LikePosterContent] = []
    // 화면 상태로 보관할 마지막 에러 메시지입니다.
    var errorMessage: String?
}

// ViewController가 구독할 Output 인터페이스입니다.
struct LikeViewModelOutput {
    // 전체 State 스트림입니다.
    let state: Observable<LikeViewState>
    // 토스트/알럿 같은 일회성 에러 노출용 이벤트 스트림입니다.
    let errorMessage: Observable<String>
}

// Like 화면의 비즈니스 로직을 담당하는 ViewModel입니다.
// BaseViewModel<Action, Output>을 상속해 send(action:) 진입점을 표준화합니다.
final class LikeViewModel: BaseViewModel<LikeViewAction, LikeViewModelOutput> {

    // 현재 화면 상태를 저장/방출하는 저장소입니다.
    // BehaviorRelay는 "항상 마지막 상태값"을 보관하므로 View 바인딩에 적합합니다.
    private let stateRelay = BehaviorRelay<LikeViewState>(value: LikeViewState())
    // 일회성 에러 이벤트 전송용 Relay입니다.
    private let errorMessageRelay = PublishRelay<String>()
    // 찜 데이터 읽기/토글을 담당하는 저장소 인터페이스입니다.
    private let likedContentRepository: LikedContentRepositoryType

    // 의존성 주입 초기화입니다.
    // 기본값으로 shared 저장소를 사용하지만, 테스트에서는 목(Mock)으로 대체 가능합니다.
    init(likedContentRepository: LikedContentRepositoryType = LikedContentRepository.shared) {
        // 주입받은 저장소를 필드에 저장합니다.
        self.likedContentRepository = likedContentRepository

        // ViewController가 구독할 Output 객체를 구성합니다.
        let output = LikeViewModelOutput(
            // stateRelay를 Observable로 노출해 외부에서 읽기 전용으로 사용하게 합니다.
            state: stateRelay.asObservable(),
            // errorMessageRelay도 Observable로 노출합니다.
            errorMessage: errorMessageRelay.asObservable()
        )
        // 부모(BaseViewModel) 초기화를 호출합니다.
        super.init(output: output)

        // 저장소 변경 알림(Notification)을 구독해, 외부 변경도 화면 상태에 반영합니다.
        bindLikedContentUpdates()
    }

    // Action 진입점입니다.
    // View에서 들어온 이벤트를 해석해 내부 로직 메서드로 분기합니다.
    override func send(action: LikeViewAction) {
        // 액션 종류별로 처리 경로를 나눕니다.
        switch action {
        case .viewDidLoad:
            // 초기 진입 시 화면 전체 상태를 구성합니다.
            bootstrapState()
        case .refreshButtonTapped:
            // 수동 새로고침은 내 리스트만 다시 읽어오면 충분합니다.
            refreshMyList()
        case .likedContentChanged:
            // 외부 변경 알림이 와도 내 리스트만 다시 읽어오면 됩니다.
            refreshMyList()
        }
    }
}


// MARK: - Business Logic
private extension LikeViewModel {

    // 좋아요 저장소 변경 알림(Notification)을 Rx로 구독하는 메서드입니다.
    func bindLikedContentUpdates() {
        // NotificationCenter의 likedContentDidUpdate 알림을 Observable로 변환합니다.
        NotificationCenter.default.rx.notification(.likedContentDidUpdate)
            // UI/State 동기화를 위해 메인 스레드에서 처리합니다.
            .observe(on: MainScheduler.instance)
            // self를 약한 참조로 캡처해 순환 참조를 피합니다.
            .bind(with: self) { owner, _ in
                // 알림을 받으면 Action 형태로 재진입시켜 흐름을 일관화합니다.
                owner.send(action: .likedContentChanged)
            }
            // disposeBag에 묶어 ViewModel 생명주기와 함께 자동 해제합니다.
            .disposed(by: disposeBag)
    }

    // 화면 최초 진입 시 필요한 상태를 한 번에 세팅합니다.
    func bootstrapState() {
        // 로딩 시작 상태를 먼저 반영합니다.
        apply(.setLoading(true))
        // "시청 중인 콘텐츠" 더미 포스터를 채웁니다.
        apply(.setContinueWatching(Self.makeDummyContinueWatchingContents()))
        // 저장소에서 현재 찜 목록을 읽어 반영합니다.
        apply(.setMyList(makeMyListContents()))
        // 이전 에러 메시지를 초기화합니다.
        apply(.setErrorMessage(nil))
        // 로딩 종료 상태를 반영합니다.
        apply(.setLoading(false))
    }

    // "내가 찜한 콘텐츠" 섹션만 재계산할 때 사용하는 메서드입니다.
    func refreshMyList() {
        // 저장소 최신값으로 myList를 교체합니다.
        apply(.setMyList(makeMyListContents()))
    }

    // 저장소 모델(LikedPoster)을 화면 모델(LikePosterContent)로 변환합니다.
    func makeMyListContents() -> [LikePosterContent] {
        // 저장소 배열을 map으로 순회하며 화면 모델로 변환합니다.
        likedContentRepository.fetchLikedPosters().map { likedPoster in
            // 각 저장소 아이템을 LikePosterContent로 래핑합니다.
            LikePosterContent(
                // 고유 id는 movieID를 사용합니다.
                id: likedPoster.movieID,
                // 셀에서 바로 사용할 PosterItem을 구성합니다.
                posterItem: PosterItem(
                    // 영화 식별 id를 전달합니다.
                    movieID: likedPoster.movieID,
                    // 표시용 제목을 전달합니다.
                    title: likedPoster.title,
                    // 저장된 포스터 URL을 전달합니다.
                    posterURL: likedPoster.posterURL
                )
            )
        }
    }

    // "시청 중인 콘텐츠"용 더미 데이터 생성 함수입니다.
    // 서버 API가 아직 없거나 분리되어 있을 때 레이아웃/흐름 검증용으로 사용합니다.
    static func makeDummyContinueWatchingContents() -> [LikePosterContent] {
        // 더미 제목 + TMDB 포스터 경로 쌍입니다.
        let dummyPosters: [(title: String, posterPath: String)] = [
            // 첫 번째 더미 아이템입니다.
            ("The Last Kingdom", "/qJ2tW6WMUDux911r6m7haRef0WH.jpg"),
            // 두 번째 더미 아이템입니다.
            ("Dark City", "/8cdWjvZQUExUUTzyp4t6EDMubfO.jpg"),
            // 세 번째 더미 아이템입니다.
            ("Silent River", "/gEU2QniE6E77NI6lCU6MxlNBvIx.jpg"),
            // 네 번째 더미 아이템입니다.
            ("Moonlight Run", "/oYuLEt3zVCKq57qu2F8dT7NIa6f.jpg"),
            // 다섯 번째 더미 아이템입니다.
            ("Night Shift", "/7WsyChQLEftFiDOVTGkv3hFpyyt.jpg"),
            // 여섯 번째 더미 아이템입니다.
            ("Code Black", "/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg")
        ]

        // 배열을 순회하며 화면 모델 배열로 변환합니다.
        return dummyPosters.enumerated().map { index, data in
            // posterPath가 "/"로 시작하지 않는 경우를 방어적으로 보정합니다.
            let normalizedPath = data.posterPath.hasPrefix("/")
                // 이미 "/"가 있으면 그대로 사용합니다.
                ? data.posterPath
                // 없으면 앞에 "/"를 붙여 URL 경로 규칙을 맞춥니다.
                : "/\(data.posterPath)"
            // 한 개의 더미 포스터 모델을 반환합니다.
            return LikePosterContent(
                // 더미는 실제 movieID와 충돌 방지를 위해 음수 id를 사용합니다.
                id: -(index + 1),
                // 셀 바인딩용 PosterItem을 구성합니다.
                posterItem: PosterItem(
                    // 동일하게 음수 movieID를 설정합니다.
                    movieID: -(index + 1),
                    // 제목을 그대로 전달합니다.
                    title: data.title,
                    // TMDB base URL + normalizedPath로 최종 포스터 URL을 구성합니다.
                    posterURL: URL(string: "https://image.tmdb.org/t/p/w500\(normalizedPath)")
                )
            )
        }
    }

    // Mutation을 실제 state에 반영하고, 필요시 일회성 이벤트를 방출합니다.
    func apply(_ mutation: LikeViewMutation) {
        // 현재 state 값을 로컬 변수로 복사합니다.
        var state = stateRelay.value
        // reduce 함수로 mutation을 적용합니다.
        reduce(state: &state, mutation: mutation)
        // 변경된 state를 relay에 반영해 View로 방출합니다.
        stateRelay.accept(state)

        // mutation이 "에러 메시지 설정(비nil)"인 경우에만 일회성 에러 이벤트를 보냅니다.
        if case let .setErrorMessage(message?) = mutation {
            // 에러 이벤트 스트림으로 메시지를 전송합니다.
            errorMessageRelay.accept(message)
        }
    }

    // 실제 상태 변경 규칙을 정의하는 순수 함수 형태의 reducer입니다.
    func reduce(state: inout LikeViewState, mutation: LikeViewMutation) {
        // mutation 케이스에 따라 state 일부를 갱신합니다.
        switch mutation {
        case .setLoading(let isLoading):
            // 로딩 플래그를 갱신합니다.
            state.isLoading = isLoading

        case .setContinueWatching(let items):
            // 시청중 섹션 데이터를 통째로 교체합니다.
            state.continueWatching = items

        case .setMyList(let items):
            // 내 리스트 섹션 데이터를 통째로 교체합니다.
            state.myList = items

        case .setErrorMessage(let message):
            // 상태 내 에러 메시지를 갱신합니다.
            state.errorMessage = message
        }
    }
}
