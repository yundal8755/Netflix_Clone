//
//  SeeAllBottomSheetView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/15/26.
//

import UIKit
import SnapKit

protocol SeeAllBottomSheetViewDelegate: AnyObject {
    func seeAllBottomSheetViewDidTapClose(_ view: SeeAllBottomSheetView)
    func seeAllBottomSheetView(_ view: SeeAllBottomSheetView, didSelect item: PosterItem)
}

final class SeeAllBottomSheetView: BaseView {
    private enum Metric {
        static let horizontalInset: CGFloat = 20
        static let topInset: CGFloat = 16
        static let bottomInset: CGFloat = 20
        static let lineSpacing: CGFloat = 16
        static let interItemSpacing: CGFloat = 12
        static let titleBottomSpacing: CGFloat = 20
        static let titleAreaHeight: CGFloat = 44
        static let posterAspectRatio: CGFloat = 150 / 110
        static let minimumItemWidth: CGFloat = 110
        static let maximumColumnCount: Int = 4
        static let closeButtonSize: CGFloat = 32
    }

    weak var delegate: SeeAllBottomSheetViewDelegate?

    private var sectionTitle: String = ""
    private var items: [PosterItem] = []

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        let configuration = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        button.setImage(UIImage(systemName: "xmark", withConfiguration: configuration), for: .normal)
        button.tintColor = .label
        button.backgroundColor = UIColor(white: 0.9, alpha: 1)
        button.layer.cornerRadius = Metric.closeButtonSize / 2
        return button
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = Metric.lineSpacing
        layout.minimumInteritemSpacing = Metric.interItemSpacing
        layout.sectionInset = .zero
        layout.estimatedItemSize = .zero

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: Metric.bottomInset, right: 0)
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
        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(closeButton)
        addSubview(collectionView)
    }

    override func configurationLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).inset(Metric.topInset)
            make.leading.equalToSuperview().inset(Metric.horizontalInset)
        }

        closeButton.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.trailing.equalToSuperview().inset(Metric.horizontalInset)
            make.size.equalTo(Metric.closeButtonSize)
        }

        countLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(closeButton.snp.leading).offset(-8)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(countLabel.snp.bottom).offset(Metric.titleBottomSpacing)
            make.leading.trailing.equalToSuperview().inset(Metric.horizontalInset)
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }

    override func configurationUI() {
        backgroundColor = .systemBackground
        closeButton.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
    }
}

// MARK: - Logic
extension SeeAllBottomSheetView {
    @objc
    func didTapCloseButton() {
        delegate?.seeAllBottomSheetViewDidTapClose(self)
    }

    func makeItemSize(for availableWidth: CGFloat) -> CGSize {
        let spacing = Metric.interItemSpacing
        let rawColumnCount = Int((availableWidth + spacing) / (Metric.minimumItemWidth + spacing))
        let columnCount = max(2, min(Metric.maximumColumnCount, rawColumnCount))
        let totalSpacing = spacing * CGFloat(columnCount - 1)
        let itemWidth = floor((availableWidth - totalSpacing) / CGFloat(columnCount))
        let itemHeight = (itemWidth * Metric.posterAspectRatio) + Metric.titleAreaHeight

        return CGSize(width: itemWidth, height: itemHeight)
    }

    func preferredHeight(for totalWidth: CGFloat) -> CGFloat {
        let collectionWidth = max(totalWidth - (Metric.horizontalInset * 2), 1)
        let spacing = Metric.interItemSpacing
        let rawColumnCount = Int((collectionWidth + spacing) / (Metric.minimumItemWidth + spacing))
        let columnCount = max(2, min(Metric.maximumColumnCount, rawColumnCount))

        let itemSize = makeItemSize(for: collectionWidth)
        let rowCount = Int(ceil(Double(max(items.count, 1)) / Double(columnCount)))
        let rowsHeight = CGFloat(rowCount) * itemSize.height
        let lineSpacingHeight = CGFloat(max(rowCount - 1, 0)) * Metric.lineSpacing
        let collectionHeight = rowsHeight + lineSpacingHeight + Metric.bottomInset

        let headerHeight = Metric.topInset
            + titleLabel.font.lineHeight
            + 4
            + countLabel.font.lineHeight
            + Metric.titleBottomSpacing

        return headerHeight + collectionHeight
    }
    
    func update(sectionTitle: String, items: [PosterItem]) {
        self.sectionTitle = sectionTitle
        self.items = items

        titleLabel.text = sectionTitle
        countLabel.text = "\(items.count) titles"
        collectionView.reloadData()
    }
}

// MARK: - DataSource, Delegate
extension SeeAllBottomSheetView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }

        cell.configure(with: items[indexPath.item], showsHeartButton: false)
        return cell
    }
}

extension SeeAllBottomSheetView: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width
        guard availableWidth > 1 else {
            return CGSize(width: 1, height: 1)
        }
        return makeItemSize(for: availableWidth)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.seeAllBottomSheetView(self, didSelect: items[indexPath.item])
    }
}
