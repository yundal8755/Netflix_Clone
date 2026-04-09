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

    private typealias TabFlow = (tab: MainTab, coordinator: Coordinator)

    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    func start() {
        let flows: [TabFlow] = [
            (.home, HomeCoordinator()),
            (.likes, LikeCoordinator()),
            (.profile, ProfileCoordinator())
        ]

        childCoordinators.removeAll()
        flows.forEach { flow in
            addChild(flow.coordinator)
            flow.coordinator.start()
        }

        let tabController = MainUITabBarController(
            scenes: makeTabScenes(flows: flows),
            initialTab: .home
        )

        // App 루트 네비게이션 바는 숨기고, 각 탭 내부 네비게이션이 헤더를 관리합니다.
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.setViewControllers([tabController], animated: false)
    }
}

private extension MainTabCoordinator {
    private func makeTabScenes(flows: [TabFlow]) -> [MainUITabBarController.Scene] {
        return flows.compactMap { flow in
            guard let rootViewController = flow.coordinator.navigationController else { return nil }
            return MainUITabBarController.Scene(
                tab: flow.tab,
                rootViewController: rootViewController
            )
        }
    }
}
