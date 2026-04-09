//
//  LikeCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/9/26.
//

import UIKit

final class LikeCoordinator: Coordinator {
    
    var childCoordinators: [Coordinator] = []
    
    let navigationController: UINavigationController?

    init() {
        let likeViewController = LikeViewController()
        let tabNavigationController = UINavigationController(rootViewController: likeViewController)

        self.navigationController = tabNavigationController
    }

    func start() {
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
}
