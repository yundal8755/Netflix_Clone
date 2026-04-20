//
//  ListTileCollectionViewCell.swift
//  Netflix_Clone
//
//  Created by mac on 4/20/26.
//

import UIKit
import SnapKit

final class ListTileCollectionViewCell: UICollectionViewCell {
    static let cellID = "ListTileCollectionViewCell"

    private let tileView = ListTileView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(tileView)
        tileView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(0)
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
        }

        let bg = UIBackgroundConfiguration.clear()
        backgroundConfiguration = bg
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: ListTileContent) {
        tileView.configure(with: item)
    }
}
