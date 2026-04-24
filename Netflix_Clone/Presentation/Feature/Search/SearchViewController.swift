//
//  SearchViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import UIKit
import RxSwift
import RxCocoa

final class SearchViewController: BaseViewController<SearchView> {
    private let store = Store(SearchContainer())
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindState()
        bindIntent()
    }
}

// MARK: - Logic

extension SearchViewController {
    
    // 결과를 내보내는 것 (뷰의 상태)
    private func bindState() {
        store.stateObservable
            .map{ $0.searchViewMode }
            .distinctUntilChanged()
            .bind(with: self) { owner, mode in
                owner.mainView.searchViewMode = mode
            }
            .disposed(by: disposeBag)

        store.stateObservable
            .map{ $0.recommendedMovies }
            .distinctUntilChanged()
            .bind(with: self) { owner, datas in
                owner.mainView.applyRecommendedItems(datas)
            }
            .disposed(by: disposeBag)

        store.stateObservable
            // ReactorKit @Pulse 라는 개념이 있답니다.
            .compactMap { $0.effect }
            .bind(with: self) { owner, effect in
                switch effect {
                case .clickContent:
                    break
                case .pop:
                    owner.navigationController?.popViewController(animated: true)
                case .showError(let message):
                    owner.presentMessageAlert(message: message)
                }
            }
            .disposed(by: disposeBag)
    }

    // 뷰의 액션만 모아둠
    private func bindIntent() {
        store.send(.viewDidLoad)

        // 검색창 뷰 액션
        mainView.searchTopView.viewAction
            .bind(with: self) { owner, action in
                switch action {
                case .textChanged(let text):
                    owner.store.send(.inputText(text))

                case .backButtonTapped:
                    owner.store.send(.backButtonTapped)
                }
            }
            .disposed(by: disposeBag)
    }
}
