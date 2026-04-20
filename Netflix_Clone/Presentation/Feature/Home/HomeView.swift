//
//  HomeView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import SnapKit
import UIKit


final class HomeView: BaseView {
    let topBarView = TopBarView()
    private let topBarContainerView = UIView()
    let homeTableView = HomeTableView()

    // MARK: - configurationSetView
    override func configurationSetView() {
        addSubview(topBarContainerView)
        topBarContainerView.addSubview(topBarView)

        addSubview(homeTableView)
    }

    // MARK: - configurationLayout
    override func configurationLayout() {
        topBarContainerView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
            make.height.equalTo(40)
        }

        topBarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }

        homeTableView.snp.makeConstraints { make in
            make.top.equalTo(topBarContainerView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - configurationUI
    override func configurationUI() {
        backgroundColor = .black

        topBarContainerView.backgroundColor = .clear
        homeTableView.backgroundColor = .clear
    }
}

#if DEBUG
    @available(iOS 17.0, *)
    #Preview {
        HomeViewController()
    }
#endif
