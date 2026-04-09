//
//  ProfileCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/9/26.
//

import UIKit

final class ProfileCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    
    let navigationController: UINavigationController?

    init() {
        let profileViewController = ProfileViewController()
        let tabNavigationController = UINavigationController(rootViewController: profileViewController)

        self.navigationController = tabNavigationController
    }

    func start() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
