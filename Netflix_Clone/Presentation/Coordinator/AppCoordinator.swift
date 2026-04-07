//
//  AppCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit

private final class RootNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        topViewController?.prefersStatusBarHidden ?? false
    }

    override var childForStatusBarStyle: UIViewController? {
        topViewController
    }

    override var childForStatusBarHidden: UIViewController? {
        topViewController
    }
}

/// 앱 전역 루트 구성만 담당하는 최상위 Coordinator
final class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    let navigationController: UINavigationController?
    private weak var window: UIWindow?

    init(window: UIWindow) {
        self.window = window
        self.navigationController = RootNavigationController()
    }

    func start() {
        guard let window, let navigationController else { return }

        navigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController

        let homeCoordinator = HomeCoordinator(navigationController: navigationController)
        
        childCoordinators = [homeCoordinator]
        homeCoordinator.start()
    }
}
