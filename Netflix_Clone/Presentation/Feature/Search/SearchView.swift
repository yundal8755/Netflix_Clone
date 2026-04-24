//
//  SearchView.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import UIKit
import SnapKit

final class SearchView: BaseView {
    var searchViewMode: SearchContainer.SearchViewMode = .beforeSearch {
        didSet {
            guard oldValue != searchViewMode else { return }
            renderContent()
        }
    }
    
    let searchTopView = SearchTopView()
    
    private let beforeSearchView = BeforeSearchView()
    private var afterSearchView: AfterSearchView?

    
    // MARK: - Base
    
    override func configurationSetView() {
        addSubview(searchTopView)
        addSubview(beforeSearchView)
    }
    
    override func configurationLayout() {
        searchTopView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(8)
            make.horizontalEdges.equalToSuperview()
        }
        
        beforeSearchView.snp.makeConstraints { make in
            make.top.equalTo(searchTopView.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
    
    override func configurationUI() {}
}


// MARK: - Logic

extension SearchView {
    
    private func renderContent() {
        switch searchViewMode {
            case .beforeSearch:
            removeAfter()
            case .afterSearch:
            setAfter()
        }
    }
    
    private func setAfter() {
        guard afterSearchView == nil else { return }

        let view = AfterSearchView()
        self.afterSearchView = view

        addSubview(view)

        view.snp.makeConstraints { make in
            make.top.equalTo(searchTopView.snp.bottom).offset(4)
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide)
        }
    }
    
    private func removeAfter() {
        guard let afterSearchView else {
            return
        }
        afterSearchView.removeFromSuperview()
        self.afterSearchView = nil
    }
    
    func applyRecommendedItems(_ items: [ListTileContent]) {
        beforeSearchView.apply(items: items)
    }
}
