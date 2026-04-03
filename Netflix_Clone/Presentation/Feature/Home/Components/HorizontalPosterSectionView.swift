//
//  HorizontalPosterSectionView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/2/26.
//

import UIKit
import SnapKit

// 가로 무한 스크롤 섹션 컴포넌트
final class HorizontalPosterSectionView: BaseView {
    // MARK: - Constants

    // 포스터 셀 크기
    private enum Metric {
        static let posterWidth: CGFloat = 110
        static let posterHeight: CGFloat = 150
        static let horizontalInset: CGFloat = 20
        static let interItemSpacing: CGFloat = 8
        static let infiniteMultiplier: Int = 300
    }

    // MARK: - Properties

    private let sectionTitle: String
    private let items: [PosterItem]
    private var didSetInitialOffset = false

    // headerStackView (제목, see all)
    private let titleLabel = UILabel()
    private let seeAllLabel = UILabel()
    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, seeAllLabel])
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        return stackView
    }()

    // 가로 스크롤 컬렉션뷰
    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metric.interItemSpacing
        layout.minimumInteritemSpacing = Metric.interItemSpacing
        layout.itemSize = CGSize(width: Metric.posterWidth, height: Metric.posterHeight)
        return layout
    }()
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.contentInset = UIEdgeInsets(top: 0, left: Metric.horizontalInset, bottom: 0, right: Metric.horizontalInset)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(HorizontalPosterCell.self, forCellWithReuseIdentifier: HorizontalPosterCell.reuseIdentifier)
        return collectionView
    }()
    
    // Init
    init(title: String, items: [PosterItem]) {
        self.sectionTitle = title
        self.items = items
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Life Cycle
    override func layoutSubviews() {
        super.layoutSubviews()

        // 첫 레이아웃 시 가운데 인덱스로 이동해서 양쪽으로 길게 스크롤 가능한 상태를 만듦
        setInitialOffsetIfNeeded()
    }
    
    // 초기 스크롤 위치를 섹션 데이터의 중간 지점으로 이동
    private func setInitialOffsetIfNeeded() {
        guard !didSetInitialOffset else { return }
        guard !items.isEmpty else { return }
        guard collectionView.bounds.width > 0 else { return }

        didSetInitialOffset = true

        let middleIndex = (items.count * Metric.infiniteMultiplier) / 2
        let indexPath = IndexPath(item: middleIndex, section: 0)

        collectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }

    // 양 끝으로 너무 이동했을 때 가운데로 다시 옮겨 무한처럼 보이게 보정
    private func recenterIfNeeded() {
        guard !items.isEmpty else { return }

        let totalItemCount = items.count * Metric.infiniteMultiplier
        guard totalItemCount > 0 else { return }

        let visibleCenter = CGPoint(
            x: collectionView.contentOffset.x + (collectionView.bounds.width / 2),
            y: collectionView.bounds.height / 2
        )

        guard let centerIndexPath = collectionView.indexPathForItem(at: visibleCenter) else { return }

        let lowerBound = items.count * 40
        let upperBound = totalItemCount - (items.count * 40)

        guard centerIndexPath.item < lowerBound || centerIndexPath.item > upperBound else { return }

        let normalizedIndex = centerIndexPath.item % items.count
        let newIndex = (totalItemCount / 2) + normalizedIndex
        let newIndexPath = IndexPath(item: newIndex, section: 0)

        collectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
    }

    // MARK: - Overrides
    
    // VIEW
    override func configurationSetView() {
        addSubview(headerStackView)
        addSubview(collectionView)
    }
    
    // LAYOUT
    override func configurationLayout() {
        headerStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(Metric.horizontalInset)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerStackView.snp.bottom).offset(10)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(Metric.posterHeight)
            make.bottom.equalToSuperview()
        }
    }
    
    // UI
    override func configurationUI() {
        backgroundColor = .clear

        titleLabel.text = sectionTitle
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)

        seeAllLabel.text = "See all"
        seeAllLabel.textColor = .white
        seeAllLabel.font = .systemFont(ofSize: 14, weight: .semibold)
    }
}

// MARK: - extension

// UICollectionViewDataSource
extension HorizontalPosterSectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard !items.isEmpty else { return 0 }
        return items.count * Metric.infiniteMultiplier
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HorizontalPosterCell.reuseIdentifier,
            for: indexPath
        ) as? HorizontalPosterCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item % items.count]
        cell.configure(with: item)

        return cell
    }
}

// UICollectionViewDelegate
extension HorizontalPosterSectionView: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recenterIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            recenterIfNeeded()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
