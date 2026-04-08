//
//  MainTabView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import UIKit
import SnapKit

final class MainTabView: BaseView {
    let contentContainerView = UIView()

    override func configurationSetView() {
        addSubview(contentContainerView)
    }

    override func configurationLayout() {
        contentContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .clear
        contentContainerView.backgroundColor = .blue
    }
}
