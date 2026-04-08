//
//  ViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit
import RxSwift
import RxCocoa
import NSObject_Rx

protocol HomeViewControllerDelegate: AnyObject {
    func didTapProfileButton()
}

final class HomeViewController: BaseViewController<HomeView> {
    
    private let viewModel: HomeViewModel
    private let likedContentRepository: LikedContentRepositoryType
    
    init(
        viewModel: HomeViewModel = HomeViewModel(),
        likedContentRepository: LikedContentRepositoryType = LikedContentRepository.shared
    ) {
        self.viewModel = viewModel
        self.likedContentRepository = likedContentRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupTableView()
        bindInput()
        bindOutput()
        viewModel.send(action: .viewDidLoad)
    }
}


// MARK: - UI Logic
extension HomeViewController {

    private func setupTableView() {
        mainView.homeTableView.register(
            HomeTableViewCell.self,
            forCellReuseIdentifier: HomeTableViewCell.reuseIdentifier
        )

        mainView.homeTableView.contentInset.bottom = 98
        mainView.homeTableView.verticalScrollIndicatorInsets.bottom = 98
    }

    private func route(to route: HomeViewModel.Route) {
        switch route {
        case .search:
            presentMessageAlert(message: "검색 기능은 곧 추가될 예정입니다.")
        }
    }
}


// MARK: - Business Logic
extension HomeViewController {
    
    func bindInput() {
        mainView.topBarView.searchButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.viewModel.send(action: .searchButtonTapped)
            }
            .disposed(by: rx.disposeBag)

        NotificationCenter.default.rx.notification(.likedContentDidUpdate)
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, _ in
                owner.refreshVisibleLikeStates()
            }
            .disposed(by: rx.disposeBag)
    }
    
    private func bindOutput() {
        viewModel.output.sections
            .observe(on: MainScheduler.instance)
            .bind(
                to: mainView.homeTableView.rx.items(
                    cellIdentifier: HomeTableViewCell.reuseIdentifier,
                    cellType: HomeTableViewCell.self
                )
            ) { _, item, cell in
                cell.configure(
                    with: item,
                    isLikedProvider: { [weak self] posterItem in
                        self?.likedContentRepository.isLiked(movieID: posterItem.movieID) ?? false
                    },
                    onToggleLike: { [weak self] posterItem in
                        self?.likedContentRepository.toggle(
                            movieID: posterItem.movieID,
                            title: posterItem.title,
                            posterURL: posterItem.posterURL
                        ) ?? false
                    }
                )
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.route
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, route in
                owner.route(to: route)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.presentMessageAlert(message: message)
            }
            .disposed(by: rx.disposeBag)
    }

    func refreshVisibleLikeStates() {
        mainView.homeTableView.visibleCells
            .compactMap { $0 as? HomeTableViewCell }
            .forEach { $0.refreshLikeStates() }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
