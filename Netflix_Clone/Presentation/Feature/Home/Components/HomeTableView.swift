//
//  HomeTableView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/7/26.
//

import UIKit

final class HomeTableView: UITableView {

    init() {
        super.init(frame: .zero, style: .plain)
        configurationUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configurationUI() {
        backgroundColor = .clear
        separatorStyle = .none
        showsVerticalScrollIndicator = false
        rowHeight = UITableView.automaticDimension
        estimatedRowHeight = 210
        contentInset = UIEdgeInsets(
            top: 8,
            left: 0,
            bottom: 20,
            right: 0
        )
    }
}

