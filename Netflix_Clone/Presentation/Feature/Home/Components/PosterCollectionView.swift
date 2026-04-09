//
//  PosterCollectionView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/2/26.
//

import UIKit
import SnapKit

/// 포스터 한 장을 화면에 그리기 위한 최소 데이터 모델입니다.
/// - `title`: 카드 하단 오버레이에 노출할 텍스트
/// - `posterURL`: 원격 이미지 주소 (nil이면 placeholder 표시)
struct PosterItem: Equatable {
    let movieID: Int
    let title: String
    let posterURL: URL?
}

final class PosterCollectionView: BaseView {

    // 레이아웃/무한 스크롤 파라미터를 한 곳에서 관리하기 위한 상수 묶음
    private enum Metric {
        /// 포스터 셀 1장의 가로 크기
        static let posterWidth: CGFloat = 110
        /// 포스터 셀 1장의 세로 크기
        static let posterHeight: CGFloat = 150
        /// 좌우 콘텐츠 인셋 (헤더/컬렉션 공통 여백)
        static let horizontalInset: CGFloat = 20
        /// 포스터 카드 간 간격
        static let interItemSpacing: CGFloat = 8
        /// 무한 스크롤 착시를 위해 실제 데이터 개수를 몇 배로 부풀릴지 결정
        static let infiniteMultiplier: Int = 300
        /// 양 끝 영역 임계치 계산에 사용할 배수
        static let recenterThresholdMultiplier: Int = 40
    }

    /// 화면에 현재 바인딩된 포스터 데이터 원본
    private var items: [PosterItem] = []
    private var isLikedProvider: ((PosterItem) -> Bool)?
    private var onToggleLike: ((PosterItem) -> Void)?
    /// 초기 중앙 정렬을 이미 수행했는지 여부 (중복 실행 방지)
    private var didSetInitialOffset = false

    /// 섹션 타이틀 라벨
    private let titleLabel = UILabel()
    /// "See all" 라벨
    private let seeAllLabel = UILabel()

    /// 헤더 영역: 왼쪽 제목 + 오른쪽 See all
    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, seeAllLabel])
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        return stackView
    }()

    /// 가로 스크롤 포스터 리스트 레이아웃
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metric.interItemSpacing
        layout.minimumInteritemSpacing = Metric.interItemSpacing
        layout.itemSize = CGSize(width: Metric.posterWidth, height: Metric.posterHeight)
        
        return layout
    }()

    /// 포스터 리스트 본체
    /// - DataSource/Delegate를 자기 자신으로 설정해 셀 바인딩과 스크롤 이벤트를 내부에서 처리
    private lazy var posterCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: Metric.horizontalInset,
            bottom: 0,
            right: Metric.horizontalInset
        )
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PosterCollectionViewCell.self,
            forCellWithReuseIdentifier: PosterCollectionViewCell.reuseIdentifier
        )
        
        return collectionView
    }()

    // MARK: - BaseView 구성 단계

    /// 화면 트리에 실제 뷰를 올리는 단계입니다.
    /// 이 단계가 없으면 제약을 걸어도 화면에 보이지 않습니다.
    override func configurationSetView() {
        addSubview(headerStackView)
        addSubview(posterCollectionView)
    }

    /// Auto Layout 제약을 정의합니다.
    /// - 헤더는 상단 고정 + 좌우 인셋
    /// - 컬렉션뷰는 헤더 아래에 배치하고 고정 높이로 노출
    override func configurationLayout() {
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(Metric.horizontalInset)
        }

        posterCollectionView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(Metric.posterHeight)
            make.bottom.equalToSuperview()
        }
    }

    /// 색/폰트/텍스트 등 시각적인 스타일을 설정합니다.
    override func configurationUI() {
        backgroundColor = .clear

        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        seeAllLabel.text = "See all"
        seeAllLabel.textColor = .white
        seeAllLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    }
}


// MARK: - Business Logic

extension PosterCollectionView {
    /// 외부에서 새 섹션 데이터를 전달할 때 호출됩니다.
    /// 동일 데이터라면 `reloadData()`를 생략해 불필요한 렌더링 비용을 줄입니다.
    func updateData(
        title: String,
        items: [PosterItem],
        isLikedProvider: ((PosterItem) -> Bool)? = nil,
        onToggleLike: ((PosterItem) -> Void)? = nil
    ) {
        self.items = items
        self.isLikedProvider = isLikedProvider
        self.onToggleLike = onToggleLike
        titleLabel.text = title

        // 데이터가 바뀌면 중앙 정렬 기준도 다시 잡아야 하므로 플래그 초기화
        didSetInitialOffset = false

        // 컬렉션뷰에게 "데이터 바뀌었으니 셀 다시 구성" 요청
        posterCollectionView.reloadData()
        // 레이아웃 재계산 예약 (다음 렌더 사이클에서 반영)
        setNeedsLayout()
    }

    func refreshVisibleLikeStates() {
        guard items.isEmpty == false else { return }

        let visibleIndexPaths = posterCollectionView.indexPathsForVisibleItems

        for indexPath in visibleIndexPaths {
            guard let cell = posterCollectionView.cellForItem(at: indexPath) as? PosterCollectionViewCell else {
                continue
            }

            let item = items[indexPath.item % items.count]
            let isLiked = isLikedProvider?(item) ?? false
            cell.updateLikedState(isLiked)
        }
    }

    /// 첫 렌더링 시점에 스크롤 위치를 중앙 근처로 이동시켜,
    /// 사용자가 좌/우 어느 방향으로도 충분히 스크롤할 수 있는 것처럼 보이게 만듭니다.
    private func setInitialOffsetIfNeeded() {
        // 이미 세팅했다면 중복 수행하지 않음
        guard didSetInitialOffset == false else { return }
        // 데이터가 없으면 인덱스 계산 불가
        guard items.isEmpty == false else { return }
        // 아직 뷰 크기가 계산되지 않았으면 스크롤 이동 불안정
        guard posterCollectionView.bounds.width > 0 else { return }

        didSetInitialOffset = true

        // (아이템 수 * 배수)의 정중앙 인덱스로 이동
        let middleIndex = (items.count * Metric.infiniteMultiplier) / 2
        let indexPath = IndexPath(item: middleIndex, section: 0)
        // 사용자가 눈치채지 않도록 애니메이션 없이 이동
        posterCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }

    /// 스크롤 위치가 양 끝 임계치에 가까워졌을 때, 같은 콘텐츠를 유지한 채 중앙으로 순간 이동합니다.
    /// 핵심은 `item % items.count`로 "원본 데이터 인덱스"를 유지하는 것입니다.
    private func recenterIfNeeded() {
        guard items.isEmpty == false else { return }

        // 부풀린 총 아이템 수
        let totalItemCount = items.count * Metric.infiniteMultiplier
        guard totalItemCount > 0 else { return }

        // 현재 화면 중심점 좌표 계산
        let visibleCenter = CGPoint(
            x: posterCollectionView.contentOffset.x + (posterCollectionView.bounds.width / 2),
            y: posterCollectionView.bounds.height / 2
        )

        // 화면 중심에 걸친 셀 인덱스 탐색
        guard let centerIndexPath = posterCollectionView.indexPathForItem(at: visibleCenter) else { return }

        // "너무 끝으로 갔는지" 판별할 임계 구간 계산
        let threshold = items.count * Metric.recenterThresholdMultiplier
        let lowerBound = threshold
        let upperBound = totalItemCount - threshold

        // 아직 안전 구간이면 재중앙 정렬 생략
        guard centerIndexPath.item < lowerBound || centerIndexPath.item > upperBound else { return }

        // 현재 보고 있는 셀이 원본 데이터에서 몇 번째인지 복원
        let normalizedIndex = centerIndexPath.item % items.count
        // 같은 원본 아이템을 가리킨 채 중앙 근처로 목표 인덱스 계산
        let newIndex = (totalItemCount / 2) + normalizedIndex
        let newIndexPath = IndexPath(item: newIndex, section: 0)
        // 시각적 이질감 없이 즉시 이동
        posterCollectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
    }
}


// MARK: - datsource, delegate

// DataSource : 뷰가 화면을 그리기 위해 필요한 재료를 제공해줌
extension PosterCollectionView: UICollectionViewDataSource {
    
    /// 질문: "셀을 총 몇 개 그릴까요?"
    /// 답변: 실제 데이터보다 크게 반환해 무한 스크롤처럼 보이게 처리
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard items.isEmpty == false else { return 0 }
        return items.count * Metric.infiniteMultiplier
    }

    /// 질문: "N번째 위치에 어떤 셀을 보여줄까요?"
    /// 답변: 재사용 셀을 꺼내고, 부풀린 인덱스를 원본 인덱스로 정규화해 데이터 바인딩
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard items.isEmpty == false else { return UICollectionViewCell() }

        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }

        // 예: 2503번째 셀 요청 -> items.count가 10이면 실제 데이터는 3번째
        let item = items[indexPath.item % items.count]
        cell.configure(
            with: item,
            isLiked: isLikedProvider?(item) ?? false
        )
        cell.onTapHeartButton = { [weak self] in
            self?.onToggleLike?(item)
        }
        return cell
    }
}

// Delegate : 터치, 스크롤 등 이벤트를 처리해줌
extension PosterCollectionView: UICollectionViewDelegate {
    /// 관성 스크롤이 완전히 멈춘 시점
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recenterIfNeeded()
    }

    /// 드래그 종료 시점
    /// - decelerate == false: 즉시 멈췄으니 여기서 바로 보정
    /// - decelerate == true: 이후 `scrollViewDidEndDecelerating`에서 보정
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            recenterIfNeeded()
        }
    }
}
