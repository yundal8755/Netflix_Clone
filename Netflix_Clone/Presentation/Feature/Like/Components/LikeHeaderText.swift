//
//  LikeHeaderText.swift
//  Netflix_Clone
//
//  Created by mac on 4/8/26.
//

import Foundation
import UIKit
import SnapKit

// 섹션 헤더(예: "시청 중인 콘텐츠", "내가 찜한 콘텐츠")를 그리는 재사용 뷰입니다.
final class LikeCollectionSectionHeaderView: UICollectionReusableView {

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        
        titleLabel.snp.makeConstraints { make in
            // 좌우 4pt 여백을 둬 텍스트가 가장자리에 붙지 않게 합니다.
            make.horizontalEdges.equalToSuperview().inset(4)
            // 하단 4pt 여백을 둬 섹션 콘텐츠와 시각적으로 구분합니다.
            make.bottom.equalToSuperview().inset(8)
        }

        backgroundColor = .clear
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
    }

    // 스토리보드/니브 경로는 사용하지 않으므로 명시적으로 막습니다.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 외부에서 헤더 텍스트를 주입하는 메서드입니다.
    func configure(title: String) {
        // 전달받은 문자열을 라벨에 적용합니다.
        titleLabel.text = title
    }
}
