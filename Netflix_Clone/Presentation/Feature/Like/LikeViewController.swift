//
//  LikeViewController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import UIKit
import RxSwift
import NSObject_Rx

// 컬렉션뷰 섹션 인덱스를 안전하게 관리하기 위한 열거형입니다.
// rawValue를 Int로 사용해 DiffableDataSource 섹션 키로 바로 활용합니다.
private enum LikeCollectionSection: Int, CaseIterable {
    // "시청 중인 콘텐츠" 섹션입니다.
    case continueWatching
    // "내가 찜한 콘텐츠" 섹션입니다.
    case myList

    // 섹션 헤더에 표시할 텍스트를 반환하는 계산 프로퍼티입니다.
    var headerTitle: String {
        // 어떤 섹션인지에 따라 다른 타이틀을 반환합니다.
        switch self {
        case .continueWatching:
            // continueWatching 섹션의 헤더 제목입니다.
            return "시청 중인 콘텐츠"
        case .myList:
            // myList 섹션의 헤더 제목입니다.
            return "내가 찜한 콘텐츠"
        }
    }
}

// Like 화면을 담당하는 ViewController입니다.
// BaseViewController<LikeView>를 통해 mainView를 타입 안전하게 사용할 수 있습니다.
final class LikeViewController: BaseViewController<LikeView> {

    // Diffable Data Source item 식별자 문자열 접두사를 모아둔 내부 상수입니다.
    private enum ItemIdentifier {
        // continueWatching 아이템 문자열 앞에 붙는 접두사입니다.
        static let continueWatchingPrefix = "continue-"
        // myList 아이템 문자열 앞에 붙는 접두사입니다.
        static let myListPrefix = "my-list-"
    }

    // DataSource 타입 별칭입니다.
    // 섹션은 Int, 아이템은 String 식별자를 사용합니다.
    private typealias DataSource = UICollectionViewDiffableDataSource<Int, String>

    // 화면 상태를 공급하는 ViewModel입니다.
    private let viewModel: LikeViewModel

    // 컬렉션뷰에 데이터를 공급할 Diffable DataSource 인스턴스입니다.
    private var dataSource: DataSource?
    // 최근 렌더링에 사용된 상태 스냅샷입니다.
    private var currentState = LikeViewState()

    // continueWatching 아이템 id -> PosterItem 매핑 캐시입니다.
    // cellProvider에서 문자열 식별자를 다시 PosterItem으로 복원할 때 사용합니다.
    private var continueWatchingMap: [Int: PosterItem] = [:]
    // myList 아이템 id -> PosterItem 매핑 캐시입니다.
    private var myListMap: [Int: PosterItem] = [:]

    // 의존성 주입 초기화입니다.
    init(
        // 기본 ViewModel을 주입하되, 테스트에서는 외부 인스턴스를 넣을 수 있습니다.
        viewModel: LikeViewModel = LikeViewModel()
    ) {
        // 주입받은 ViewModel을 저장합니다.
        self.viewModel = viewModel
        // 부모 초기화를 호출합니다.
        super.init(nibName: nil, bundle: nil)
    }

    // 스토리보드 경로는 사용하지 않으므로 명시적으로 막습니다.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 뷰가 메모리에 로드된 직후 한 번 호출됩니다.
    override func viewDidLoad() {
        // 부모 구현을 먼저 호출합니다.
        super.viewDidLoad()

        // 컬렉션뷰 레이아웃/등록을 설정합니다.
        setupCollectionView()
        // Diffable Data Source를 구성합니다.
        setupDataSource()
        // 사용자 입력 이벤트를 ViewModel 액션으로 연결합니다.
        bindInput()
        // ViewModel 출력 상태를 화면 렌더링으로 연결합니다.
        bindOutput()

        // 초기 데이터 로딩 액션을 보냅니다.
        viewModel.send(action: .viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.send(action: .viewWillAppear)
    }
}

// ViewController 내부 구현을 private extension으로 분리해 가독성을 높입니다.
private extension LikeViewController {

    // 컬렉션뷰의 레이아웃, 셀/헤더 등록을 담당합니다.
    func setupCollectionView() {
        // compositional layout을 만들어 컬렉션뷰에 적용합니다.
        mainView.collectionView.collectionViewLayout = makeLayout()

        // 포스터 셀 클래스를 재사용 식별자로 등록합니다.
        mainView.collectionView.register(
            PosterCollectionViewCell.self,
            forCellWithReuseIdentifier: PosterCollectionViewCell.reuseIdentifier
        )

        // 섹션 헤더 뷰 클래스를 supplementary kind로 등록합니다.
        mainView.collectionView.register(
            LikeCollectionSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: LikeCollectionSectionHeaderView.reuseIdentifier
        )
    }

    // Diffable Data Source의 cellProvider/supplementaryProvider를 구성합니다.
    func setupDataSource() {
        // 컬렉션뷰와 연결된 data source를 생성합니다.
        dataSource = DataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, item in
            // self가 해제되었으면 빈 셀을 반환합니다.
            guard let self else { return UICollectionViewCell() }

            // item 식별자가 continue 섹션 접두사로 시작하는지 확인합니다.
            if item.hasPrefix(ItemIdentifier.continueWatchingPrefix) {
                // 접두사를 제거해 숫자 id 문자열만 추출합니다.
                let idString = item.replacingOccurrences(
                    of: ItemIdentifier.continueWatchingPrefix,
                    with: ""
                )
                // 문자열 id를 Int로 변환합니다.
                let id = Int(idString)
                // id로 map에서 PosterItem을 찾아 셀을 생성합니다.
                return self.makePosterCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    posterItem: id.flatMap { self.continueWatchingMap[$0] },
                    showsHeartButton: false
                )
            }

            // 위 조건이 아니면 myList 섹션 아이템으로 처리합니다.
            let idString = item.replacingOccurrences(
                of: ItemIdentifier.myListPrefix,
                with: ""
            )
            // 문자열 id를 Int로 변환합니다.
            let id = Int(idString)

            // myList용 셀을 생성하며 하트 버튼을 노출합니다.
            return self.makePosterCell(
                collectionView: collectionView,
                indexPath: indexPath,
                posterItem: id.flatMap { self.myListMap[$0] },
                showsHeartButton: true
            )
        }

        // supplementary(헤더) 공급자를 설정합니다.
        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            // 헤더 kind가 아니면 처리하지 않습니다.
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            // 섹션 인덱스를 enum으로 안전하게 변환합니다.
            guard let section = LikeCollectionSection(rawValue: indexPath.section) else {
                return nil
            }

            // 등록된 헤더 뷰를 dequeue합니다.
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LikeCollectionSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? LikeCollectionSectionHeaderView else {
                // 캐스팅 실패 시 nil 반환합니다.
                return nil
            }

            // 섹션별 헤더 타이틀을 적용합니다.
            headerView.configure(title: section.headerTitle)
            // 구성 완료된 헤더를 반환합니다.
            return headerView
        }
    }

    // 하나의 포스터 셀을 생성/설정하는 공통 메서드입니다.
    func makePosterCell(
        // 셀을 dequeue할 컬렉션뷰입니다.
        collectionView: UICollectionView,
        // 현재 셀의 indexPath입니다.
        indexPath: IndexPath,
        // 표시할 포스터 아이템(없으면 빈 셀 상태 유지)입니다.
        posterItem: PosterItem?,
        // 하트 버튼 노출 여부입니다.
        showsHeartButton: Bool
    ) -> UICollectionViewCell {
        // 등록된 재사용 식별자로 셀을 꺼내고 타입 캐스팅합니다.
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            // 캐스팅 실패 시 기본 빈 셀 반환합니다.
            return UICollectionViewCell()
        }

        // 매핑 실패로 posterItem이 없으면 탭 핸들러를 제거하고 반환합니다.
        guard let posterItem else {
            // 재사용 셀의 이전 핸들러 잔존을 방지합니다.
            cell.onTapHeartButton = nil
            return cell
        }

        // 하트 버튼을 보여줘야 하는 섹션인지 분기합니다.
        if showsHeartButton {
            // 현재 state의 liked id 집합으로 하트 상태를 계산합니다.
            let isLiked = currentState.likedMovieIDs.contains(posterItem.movieID)
            // 하트 노출 + 현재 좋아요 상태를 적용해 셀을 구성합니다.
            cell.configure(with: posterItem, isLiked: isLiked, showsHeartButton: true)
            // 하트 탭 시 좋아요 토글을 실행하는 클로저를 연결합니다.
            cell.onTapHeartButton = { [weak self] in
                self?.viewModel.send(action: .heartButtonTapped(posterItem))
            }
        } else {
            // 하트 버튼이 필요 없는 섹션은 버튼을 숨기고 일반 구성만 합니다.
            cell.configure(with: posterItem, showsHeartButton: false)
            // 탭 핸들러도 제거해 불필요 동작을 막습니다.
            cell.onTapHeartButton = nil
        }

        // 구성된 셀을 반환합니다.
        return cell
    }

    // View 입력 이벤트(버튼 탭)를 ViewModel Action으로 연결합니다.
    func bindInput() {}

    // ViewModel 출력(state/error)을 구독해 화면에 반영합니다.
    func bindOutput() {
        // 전체 상태 스트림을 구독합니다.
        viewModel.output.state
            // UI 업데이트는 메인 스레드에서 수행합니다.
            .observe(on: MainScheduler.instance)
            // 상태가 올 때마다 render를 호출합니다.
            .subscribe(with: self) { owner, state in
                owner.render(state)
            }
            // 구독 해제를 disposeBag에 위임합니다.
            .disposed(by: rx.disposeBag)

        // 일회성 에러 메시지 스트림을 구독합니다.
        viewModel.output.errorMessage
            // 알럿 표시도 메인 스레드에서 수행합니다.
            .observe(on: MainScheduler.instance)
            // 메시지를 알럿으로 표시합니다.
            .subscribe(with: self) { owner, message in
                owner.presentMessageAlert(message: message)
            }
            // 구독 해제를 disposeBag에 위임합니다.
            .disposed(by: rx.disposeBag)
    }

    // 전달받은 상태를 화면에 반영하는 렌더 함수입니다.
    func render(_ state: LikeViewState) {
        // 최신 상태를 캐시합니다.
        currentState = state

        // continueWatching 배열을 id 기반 딕셔너리로 변환합니다.
        continueWatchingMap = Dictionary(
            uniqueKeysWithValues: state.continueWatching.map { ($0.id, $0.posterItem) }
        )
        // myList 배열을 id 기반 딕셔너리로 변환합니다.
        myListMap = Dictionary(
            uniqueKeysWithValues: state.myList.map { ($0.id, $0.posterItem) }
        )

        // 현재 찜 개수를 계산합니다.
        let likedCount = state.myList.count
        // 개수에 따라 문구를 분기합니다.
        let countText = likedCount == 0
            // 0개면 기본 문구를 보여줍니다.
            ? "찜한 콘텐츠"
            // 1개 이상이면 개수를 포함한 문구를 보여줍니다.
            : "찜한 콘텐츠 \(likedCount)개"
        // 보조 타이틀 라벨에 문구를 반영합니다.
        mainView.subtitleLabel.text = countText

        // 마지막으로 diffable snapshot을 적용해 컬렉션뷰를 갱신합니다.
        applySnapshot()
    }

    // currentState를 기반으로 Diffable Snapshot을 만들어 적용합니다.
    func applySnapshot() {
        // dataSource가 준비되지 않았으면 아무 동작도 하지 않습니다.
        guard let dataSource else { return }

        // 비어 있는 snapshot을 생성합니다.
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        // 섹션 순서를 추가합니다.
        snapshot.appendSections(LikeCollectionSection.allCases.map(\.rawValue))
        // continueWatching 아이템 식별자 목록을 해당 섹션에 추가합니다.
        snapshot.appendItems(
            currentState.continueWatching.map { ItemIdentifier.continueWatchingPrefix + String($0.id) },
            toSection: LikeCollectionSection.continueWatching.rawValue
        )
        // myList 아이템 식별자 목록을 해당 섹션에 추가합니다.
        snapshot.appendItems(
            currentState.myList.map { ItemIdentifier.myListPrefix + String($0.id) },
            toSection: LikeCollectionSection.myList.rawValue
        )

        // window가 붙은 뒤에는 애니메이션 차이를 보여주고, 초기 로딩은 자연스럽게 즉시 반영합니다.
        dataSource.apply(snapshot, animatingDifferences: mainView.window != nil)
    }

    // 섹션별 레이아웃을 반환하는 compositional layout 팩토리입니다.
    func makeLayout() -> UICollectionViewCompositionalLayout {
        // 섹션 인덱스마다 서로 다른 레이아웃을 반환합니다.
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            // self가 해제되었거나 섹션 변환 실패 시 nil 반환합니다.
            guard let self,
                  let section = LikeCollectionSection(rawValue: sectionIndex) else {
                return nil
            }

            // 섹션 타입에 맞는 레이아웃 생성 메서드를 호출합니다.
            switch section {
            case .continueWatching:
                return self.makeContinueWatchingSection()
            case .myList:
                return self.makeMyListSection()
            }
        }
    }

    // "시청 중인 콘텐츠" 섹션 레이아웃을 생성합니다.
    func makeContinueWatchingSection() -> NSCollectionLayoutSection {
        // 아이템 크기: 그룹 기준 가로/세로 100%를 채웁니다.
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        // 위 크기로 아이템을 생성합니다.
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        // 그룹 크기: 섹션 너비의 40%, 높이는 너비의 60%로 설정합니다.
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.4),
            heightDimension: .fractionalWidth(0.6)
        )
        // 아이템 1개를 담는 세로 그룹을 만듭니다.
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        // 그룹 기반 섹션을 생성합니다.
        let section = NSCollectionLayoutSection(group: group)
        // 섹션 내부 여백을 설정합니다.
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        // 그룹 간 간격을 설정합니다.
        section.interGroupSpacing = 12
        // 가로 연속 스크롤(그룹 리딩 경계 스냅) 동작을 설정합니다.
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        // 상단 헤더를 붙입니다.
        section.boundarySupplementaryItems = [makeSectionHeader()]
        // 완성된 섹션을 반환합니다.
        return section
    }

    // "내가 찜한 콘텐츠" 섹션 레이아웃을 생성합니다.
    func makeMyListSection() -> NSCollectionLayoutSection {
        // 아이템 크기: 가로 1/3, 세로는 그룹 높이 100%를 채웁니다.
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalHeight(1)
        )
        // 위 크기로 아이템을 생성합니다.
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        // 아이템 안쪽 여백을 설정해 셀 사이 여백을 균일하게 맞춥니다.
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        // 그룹 크기: 섹션 전체 너비, 높이는 너비의 50% 비율입니다.
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(0.5)
        )
        // 동일 아이템을 3개 반복 배치하는 가로 그룹을 생성합니다.
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 3
        )

        // 그룹 기반 섹션을 생성합니다.
        let section = NSCollectionLayoutSection(group: group)
        // 섹션 안쪽 여백을 설정합니다.
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        // 행(그룹) 간 세로 간격을 설정합니다.
        section.interGroupSpacing = 12
        // 상단 헤더를 붙입니다.
        section.boundarySupplementaryItems = [makeSectionHeader()]
        // 완성된 섹션을 반환합니다.
        return section
    }

    // 공통 섹션 헤더 레이아웃 객체를 생성합니다.
    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        // 헤더 크기: 가로 100%, 높이 44pt입니다.
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(44)
        )
        // 상단 정렬의 boundary supplementary item을 생성합니다.
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        // 스크롤 중에도 헤더를 상단에 고정(pinning)합니다.
        header.pinToVisibleBounds = true
        // zIndex를 올려 셀 위에 헤더가 안정적으로 보이게 합니다.
        header.zIndex = 2
        // 구성된 헤더 레이아웃을 반환합니다.
        return header
    }
}

#if DEBUG
// iOS 17 이상에서 SwiftUI Preview로 현재 ViewController를 확인할 수 있습니다.
@available(iOS 17.0, *)
#Preview {
    // 기본 생성자를 사용해 Like 화면 미리보기를 구성합니다.
    LikeViewController()
}
#endif
