//
//  AppCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit

final class AppCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []

    var navigationController: UINavigationController? { rootNavigationController }

    private weak var window: UIWindow?

    private let rootNavigationController: UINavigationController

    private var didStart = false

    init(window: UIWindow) {
        self.window = window
        self.rootNavigationController = UINavigationController()
    }
    
    func start() {
        guard didStart == false else { return }
        guard let window else { return }
        didStart = true

        rootNavigationController.setNavigationBarHidden(true, animated: false)
        window.rootViewController = rootNavigationController

        showMainTabFlow()
        
        window.makeKeyAndVisible()
    }

    private func showMainTabFlow() {
        let mainTabCoordinator = MainTabCoordinator(navigationController: rootNavigationController)
        childCoordinators.removeAll()
        addChild(mainTabCoordinator)
        mainTabCoordinator.start()
    }
}
