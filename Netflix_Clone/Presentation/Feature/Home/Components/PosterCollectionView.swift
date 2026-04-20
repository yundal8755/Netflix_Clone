//
//  PosterCollectionView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/2/26.
//

import UIKit
import SnapKit

struct PosterItem: Equatable {
    let movieID: Int
    let title: String
    let posterURL: URL?
}

protocol PosterCollectionViewDelegate: AnyObject {
    func posterCollectionViewDidTapSeeAll(_ posterCollectionView: PosterCollectionView)
}

final class PosterCollectionView: BaseView {
    private enum Metric {
        static let posterWidth: CGFloat = 110
        static let posterHeight: CGFloat = 150
        static let horizontalInset: CGFloat = 20
        static let interItemSpacing: CGFloat = 8
        static let infiniteMultiplier: Int = 300
        static let recenterThresholdMultiplier: Int = 40
    }
    private var items: [PosterItem] = []
    
    private var isLikedProvider: ((PosterItem) -> Bool)?
    private var onToggleLike: ((PosterItem) -> Void)?
    weak var delegate: PosterCollectionViewDelegate?

    private var didSetInitialOffset = false
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 28, weight: .bold)
        
        return label
    }()
    
    private let seeAllBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("See all", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.tintColor = .white
        
        return button
    }()

    private lazy var headerStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, seeAllBtn])
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        return stackView
    }()

    private var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Metric.interItemSpacing
        layout.minimumInteritemSpacing = Metric.interItemSpacing
        layout.itemSize = CGSize(width: Metric.posterWidth, height: Metric.posterHeight)
        
        return layout
    }()

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

    // MARK: - UI
    
    override func configurationSetView() {
        addSubview(headerStackView)
        addSubview(posterCollectionView)
    }

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

    override func configurationUI() {
        backgroundColor = .clear
        seeAllBtn.addTarget(self, action: #selector(didTapSeeAllButton), for: .touchUpInside)
    }
}


// MARK: - Logic

extension PosterCollectionView {
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
        didSetInitialOffset = false
        posterCollectionView.reloadData()
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

    private func setInitialOffsetIfNeeded() {
        guard didSetInitialOffset == false else { return }
        guard items.isEmpty == false else { return }
        guard posterCollectionView.bounds.width > 0 else { return }

        didSetInitialOffset = true

        let middleIndex = (items.count * Metric.infiniteMultiplier) / 2
        let indexPath = IndexPath(item: middleIndex, section: 0)

        posterCollectionView.scrollToItem(at: indexPath, at: .left, animated: false)
    }

    private func recenterIfNeeded() {
        guard items.isEmpty == false else { return }

        let totalItemCount = items.count * Metric.infiniteMultiplier
        guard totalItemCount > 0 else { return }

        let visibleCenter = CGPoint(
            x: posterCollectionView.contentOffset.x + (posterCollectionView.bounds.width / 2),
            y: posterCollectionView.bounds.height / 2
        )

        guard let centerIndexPath = posterCollectionView.indexPathForItem(at: visibleCenter) else { return }

        let threshold = items.count * Metric.recenterThresholdMultiplier
        let lowerBound = threshold
        let upperBound = totalItemCount - threshold
        guard centerIndexPath.item < lowerBound || centerIndexPath.item > upperBound else { return }
        let normalizedIndex = centerIndexPath.item % items.count
        let newIndex = (totalItemCount / 2) + normalizedIndex
        let newIndexPath = IndexPath(item: newIndex, section: 0)
        posterCollectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: false)
    }

    @objc
    private func didTapSeeAllButton() {
        delegate?.posterCollectionViewDidTapSeeAll(self)
    }
}


// MARK: - datsource, delegate

// DataSource : 뷰가 화면을 그리기 위해 필요한 재료를 제공해줌
extension PosterCollectionView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard items.isEmpty == false else { return 0 }
        return items.count * Metric.infiniteMultiplier
    }

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
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        recenterIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            recenterIfNeeded()
        }
    }
}
