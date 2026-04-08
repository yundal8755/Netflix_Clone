//
//  MainTabCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import UIKit

final class MainTabCoordinator: Coordinator {

    var childCoordinators: [Coordinator] = []

    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        let tabController = MainUITabBarController(
            scenes: makeTabScenes(),
            initialTab: .home
        )

        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setViewControllers([tabController], animated: false)
    }
}

private extension MainTabCoordinator {
    func makeTabScenes() -> [MainUITabBarController.Scene] {
        [
            MainUITabBarController.Scene(tab: .home, rootViewController: HomeViewController()),
            MainUITabBarController.Scene(tab: .likes, rootViewController: LikeViewController()),
            MainUITabBarController.Scene(tab: .profile, rootViewController: ProfileViewController())
        ]
    }
}
