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

final class HomeViewController: BaseViewController<HomeView> {
    
    private let viewModel: HomeViewModel
    weak var coordinator: HomeCoordinator?
    private var likedMovieIDs: Set<Int> = []
    
    private var aEvent = 3
    
    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupBindings()
        viewModel.send(action: .viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.send(action: .viewWillAppear)
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
}


// MARK: - Business Logic
extension HomeViewController {
    
    // Rx 파이프라인 연결
    func setupBindings() {
        bindInput()
        bindOutput()
    }
 
    func bindInput() {
        mainView.topBarView.searchButton.rx.tap
            .bind(with: self) { owner, event in // 결과에 대한
                owner.viewModel.send(action: .searchButtonTapped)
            }
//            .withUnretained(self)
//            .bind { owner, _ in
//                owner.viewModel.send(action: .searchButtonTapped)
//            }
            .disposed(by: rx.disposeBag)
    }
    
    private func bindOutput() {
        viewModel.output.sections
            .observe(on: MainScheduler.instance)
            .bind(
                to: mainView.homeTableView.rx.items( // Steam 을 바로 전달 ->
                    cellIdentifier: HomeTableViewCell.reuseIdentifier,
                    cellType: HomeTableViewCell.self
                )
            ) { _, item, cell in
                cell.delegate = self
                cell.configure(
                    with: item,
                    isLikedProvider: { [weak self] posterItem in
                        self?.likedMovieIDs.contains(posterItem.movieID) ?? false
                    },
                    onToggleLike: { [weak self] posterItem in
                        self?.viewModel.send(action: .posterHeartTapped(posterItem))
                    }
                )
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.likedMovieIDs
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, likedMovieIDs in
                owner.likedMovieIDs = likedMovieIDs
                owner.refreshVisibleLikeStates()
            }
            .disposed(by: rx.disposeBag)
        
        // Dispatch -> SwiftConcurrency
        DispatchQueue.global().async {
            // 1번 암탉 쓰레드 UI 쓰레드가 아니에요 X번
            // owner.coordinator?.goRoute(route) -> UI 를 동작해야하는 함수이죠
            // 앱이 꺼질 꺼에요
            DispatchQueue.main.async { // MainThread 를 보장 할래요
                // owner.coordinator?.goRoute(route)
            }
            
//            DispatchQueue.global(qos: .background).async { [unowned self] in // 절대 옵셔널 아님
////                coordinator
//            }
            
        }

        viewModel.output.route
            // .observe(on:) :
            .observe(on: MainScheduler.instance)
            
            // 스트림
            .subscribe(with: self) { owner, route in
                owner.coordinator?.goRoute(route)
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

extension HomeViewController: HomeTableViewCellDelegate {
    func homeTableViewCell(_ cell: HomeTableViewCell, didTapSeeAll section: HomeViewModel.Section) {
        coordinator?.showSeeAll(for: section)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
