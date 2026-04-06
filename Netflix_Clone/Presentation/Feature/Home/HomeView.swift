//
//  HomeView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import UIKit
import SnapKit

final class HomeView: BaseView {
    let topBarView = TopBarView()
    let sectionsTableView = UITableView(frame: .zero, style: .plain)
    private let topBarContainerView = UIView()
    
    
    // MARK: - Methods
    
    // VIEW
    override func configurationSetView() {
        // 상단 바
        addSubview(topBarContainerView)
        topBarContainerView.addSubview(topBarView)
        
        // 콘텐츠 body
        addSubview(sectionsTableView)
    }
    
    // LAYOUT
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

        sectionsTableView.snp.makeConstraints { make in
            make.top.equalTo(topBarContainerView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
    
    // UI
    override func configurationUI() {
        backgroundColor = .black

        topBarContainerView.backgroundColor = .clear

        sectionsTableView.backgroundColor = .clear
        sectionsTableView.separatorStyle = .none
        sectionsTableView.showsVerticalScrollIndicator = false
        sectionsTableView.rowHeight = UITableView.automaticDimension
        sectionsTableView.estimatedRowHeight = 210
        sectionsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 20, right: 0)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
