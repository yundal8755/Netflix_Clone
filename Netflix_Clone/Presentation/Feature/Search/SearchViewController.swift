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
    private let container = SearchContainer()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindState()
        bindInput()
    }
}

// MARK: - Logic

extension SearchViewController {
    
    // 상태를 구독하겠다
    // State, Effect
    private func bindState() {
        container.stateObservable
            .map{ $0.searchViewMode }
            .distinctUntilChanged()
            .bind(with: self) { owner, mode in
                owner.mainView.searchViewMode = mode
            }
            .disposed(by: disposeBag)
        
        container.stateObservable
            .map{ $0.recommendedMovies }
            .distinctUntilChanged()
            .bind(with: self) { owner, datas in
                owner.mainView.applyRecommendedItems(datas)
            }
            .disposed(by: disposeBag)
        
        container.stateObservable
            .compactMap { $0.effect } // ReactorKit @Pulse 라는 개념이 있답니다.
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
    
    // input을 구독하겠다
    private func bindInput() {
        container.send(.viewDidLoad)
        
        mainView.searchTopView.viewAction
            .bind(with: self) { owner, action in
                switch action {
                case .textChanged(let text):
                    owner.container.send(.inputText(text))
                    
                case .backButtonTapped:
                    owner.container.send(.backButtonTapped)
                }
            }
            .disposed(by: disposeBag)
    }
}
