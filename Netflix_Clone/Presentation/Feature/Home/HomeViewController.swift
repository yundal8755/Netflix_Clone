//
//  ViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit

final class HomeViewController: BaseViewController<HomeView> {
    private let viewModel = HomeViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        bindViewModel()
        viewModel.send(.viewDidLoad)
    }
}

private extension HomeViewController {
    func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            switch state {
            case let .loaded(sections):
                self?.mainView.configureSections(sections)
            }
        }
    }
}
