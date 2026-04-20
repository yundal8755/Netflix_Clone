//
//  HomeCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/9/26.
//

import UIKit

struct SeeAllSheetPayload: Equatable {
    let title: String
    let items: [PosterItem]
}

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinator(_ coordinator: HomeCoordinator, didRequestSeeAll payload: SeeAllSheetPayload)
}

enum HomeCoordinatorCase: Equatable, Hashable {
    
    case searchView
    case example (userID: String)
}

final class HomeCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []
    weak var navigationController: UINavigationController?
    weak var delegate: HomeCoordinatorDelegate?

    init(delegate: HomeCoordinatorDelegate? = nil) {
        self.delegate = delegate
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

    func showSeeAll(for section: HomeViewModel.Section) {
        let payload = SeeAllSheetPayload(title: section.title, items: section.items)
        delegate?.homeCoordinator(self, didRequestSeeAll: payload)
    }
}

// MARK: Route
extension HomeCoordinator {
    private func showSearch() {
        let viewController = SearchViewController()
        viewController.view.backgroundColor = .black
        viewController.hidesBottomBarWhenPushed = true

        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.pushViewController(viewController, animated: true)
    }
}
