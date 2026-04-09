//
//  HomeCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/9/26.
//

import UIKit

/// Home Route Views
enum HomeCoordinatorCase: Equatable, Hashable {
    
    case searchView
    
    case example (userID: String)
}

final class HomeCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController?

    init() {
        let homeViewController = HomeViewController()
        let tabNavigationController = UINavigationController(rootViewController: homeViewController)

        self.navigationController = tabNavigationController
        homeViewController.coordinator = self
    }

    func start() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func goRoute(_ route: HomeCoordinatorCase) {
        switch route {
        case .searchView:
            showSearch()
            
        default :
            break
        }
    }
}

// MARK: -- Private --

// MARK: Route
extension HomeCoordinator {
    private func showSearch() {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .red
        viewController.title = "검색"
        viewController.hidesBottomBarWhenPushed = true

        navigationController?.setNavigationBarHidden(false, animated: false)
        next(viewController: viewController)
    }
}
