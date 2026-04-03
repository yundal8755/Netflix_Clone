//
//  HorizontalPosterCell.swift
//  Netflix_Clone
//
//  Created by Codex on 4/3/26.
//

import UIKit
import SnapKit

final class HorizontalPosterCell: UICollectionViewCell {
    static let reuseIdentifier = "HorizontalPosterCell"

    // 포스터 카드 배경 뷰
    private let posterBackgroundView = UIView()

    // 포스터 제목 라벨
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // VIEW
    private func configurationSetView() {
        contentView.addSubview(posterBackgroundView)
        posterBackgroundView.addSubview(titleLabel)
    }

    // LAYOUT
    private func configurationLayout() {
        posterBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    // UI
    private func configurationUI() {
        contentView.backgroundColor = .clear

        posterBackgroundView.layer.cornerRadius = 6
        posterBackgroundView.clipsToBounds = true

        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white
    }
    
    
    func configure(with item: PosterItem) {
        posterBackgroundView.backgroundColor = item.color
        titleLabel.text = item.title
    }
}
