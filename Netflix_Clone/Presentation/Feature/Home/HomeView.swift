//
//  HomeView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import UIKit
import SnapKit

final class HomeView: BaseView {
    // MARK: - UI Components

    private let topBarView = TopBarView()

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 28
        return stackView
    }()

    private let topBarContainerView = UIView()

    override func configurationSetView() {
        // 상단 앱 바
        addSubview(topBarContainerView)
        topBarContainerView.addSubview(topBarView)
        
        // 본문 스크롤 영역
        addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
    }
    
    override func configurationLayout() {
        topBarContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(topBarContainerView.snp.bottom)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }

        contentStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }

        topBarContainerView.snp.makeConstraints { make in
            make.height.equalTo(32)
        }

        topBarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.horizontalEdges.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    override func configurationUI() {
        backgroundColor = .black
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.showsVerticalScrollIndicator = false
    }

    func configureSections(_ sections: [HomeViewModel.Section]) {
        contentStackView.arrangedSubviews.forEach { subview in
            contentStackView.removeArrangedSubview(subview)
            subview.removeFromSuperview()
        }

        sections.forEach { section in
            let sectionView = HorizontalPosterSectionView(title: section.title, items: section.items)
            contentStackView.addArrangedSubview(sectionView)
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
