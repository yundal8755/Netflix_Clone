//
//  HomeCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/7/26.
//

import UIKit

protocol HomeCoordinating: Coordinator {
    func showProfile(
        from presentingViewController: UIViewController,
        continueWatchingItems: [PosterItem],
        myListItems: [PosterItem]
    )
}

/// Home feature flow 전담 Coordinator
final class HomeCoordinator: HomeCoordinating {

    var childCoordinators: [Coordinator] = []
    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        let homeViewController = HomeViewController()
        homeViewController.coordinator = self
        navigationController?.setViewControllers([homeViewController], animated: false)
    }

    func showProfile(
        from presentingViewController: UIViewController,
        continueWatchingItems: [PosterItem],
        myListItems: [PosterItem]
    ) {
        let profileViewModel = ProfileViewModel(
            continueWatchingItems: continueWatchingItems,
            myListItems: myListItems
        )
        let profileViewController = ProfileViewController(viewModel: profileViewModel) { [weak self] in
            guard let self else { return }
            // On Dismiss
            navigationController?.setNavigationBarHidden(true, animated: true)
        }

        if navigationController != nil {
            navigationController?.setNavigationBarHidden(false, animated: false)
            next(viewController: profileViewController, animated: true)
            return
        }

        presentWrappedInNavigation(
            profileViewController,
            from: presentingViewController
        )
    }
}
