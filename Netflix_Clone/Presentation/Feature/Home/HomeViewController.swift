//
//  ViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import NSObject_Rx

final class HomeViewController: BaseViewController<HomeView> {
    
    private let viewModel: HomeViewModel
    weak var coordinator: HomeCoordinating?
    private var currentSections: [HomeViewModel.Section] = []
    
    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
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
        
        setupTableView() // 셀 등록
        bindInput()
        bindOutput()
        viewModel.send(action: .viewDidLoad) // VM에 viewDidLoad 액션 전달
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // view가 화면에 나타나기 직전에 호출 (다른 화면 갔다가 돌아올 때마다 계속 호출됨)
        // Home 화면 복귀 시에도 네비게이션 바가 항상 숨겨지도록 재적용
        
        super.viewWillAppear(animated)
//        setNeedsStatusBarAppearanceUpdate()
    }
}


// MARK: - UI Logic
extension HomeViewController {

    private func setupTableView() {
        mainView.homeTableView.register(
            HomeTableViewCell.self,
            forCellReuseIdentifier: HomeTableViewCell.reuseIdentifier
        )
    }

    private func route(to route: HomeViewModel.Route) {
        switch route {
        case .profile:
            routeToProfile()
        }
    }

    private func routeToProfile() {
        let (continueWatchingItems, myListItems) = makeProfileItems()

        if let coordinator {
            coordinator.showProfile(
                from: self,
                continueWatchingItems: continueWatchingItems,
                myListItems: myListItems
            )
            return
        }
    }

    private func makeProfileItems() -> (continueWatching: [PosterItem], myList: [PosterItem]) {
        let allItems = currentSections.flatMap(\.items)
        guard allItems.isEmpty == false else { return ([], []) }

        let continueWatching = Array(allItems.prefix(10))
        let myListCandidate = Array(allItems.dropFirst(10).prefix(30))
        let myList = myListCandidate.isEmpty ? allItems : myListCandidate
        return (continueWatching, myList)
    }
}


// MARK: - Business Logic
extension HomeViewController {
    
    func bindInput() {
        // case 1) 프로필 버튼 클릭시
        mainView.topBarView.profileButton.rx.tap
            .bind(with: self) { owner, _ in
                owner.viewModel.send(action: .profileButtonTapped)
            }
            .disposed(by: rx.disposeBag)
    }
    
    private func bindOutput() {
        // case 1) sections 상태 구독
        viewModel.output.sections
            .observe(on: MainScheduler.instance)
            .bind(
                to: mainView.homeTableView.rx.items(
                    cellIdentifier: HomeTableViewCell.reuseIdentifier,
                    cellType: HomeTableViewCell.self
                )
            ) { _, item, cell in
                cell.configure(with: item)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.sections
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, sections in
                owner.currentSections = sections
            }
            .disposed(by: rx.disposeBag)
        
        // case 2) 일회성 네비게이션 트리거 처리
        viewModel.output.route
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, route in
                owner.route(to: route)
            }
            .disposed(by: rx.disposeBag)

        // case 3) errorMessage 이벤트 표시
        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.presentMessageAlert(message: message)
            }
            .disposed(by: rx.disposeBag)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
