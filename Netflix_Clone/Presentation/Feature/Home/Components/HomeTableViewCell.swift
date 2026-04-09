//
//  HomeSectionTableViewCell.swift
//  Netflix_Clone
//

import UIKit
import SnapKit

final class HomeTableViewCell: UITableViewCell {
    
    private let posterCollectionView = PosterCollectionView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(posterCollectionView)
        
        posterCollectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    func configure(
        with section: HomeViewModel.Section,
        isLikedProvider: ((PosterItem) -> Bool)? = nil,
        onToggleLike: ((PosterItem) -> Void)? = nil
    ) {
        // 스크롤시 이미 만들어진 sectionView에 "데이터만 새로 업데이트 해!" 라고 명령만 내립니다.
        posterCollectionView.updateData(
            title: section.title,
            items: section.items,
            isLikedProvider: isLikedProvider,
            onToggleLike: onToggleLike
        )
    }

    func refreshLikeStates() {
        posterCollectionView.refreshVisibleLikeStates()
    }
}
