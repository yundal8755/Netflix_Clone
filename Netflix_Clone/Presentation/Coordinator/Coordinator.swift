//
//  Coordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit


protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController? { get }
    func start()
}

extension Coordinator {
    
    func addChild(_ coordinator: Coordinator) {
        guard childCoordinators.contains(where: { $0 === coordinator }) == false else { return }
        childCoordinators.append(coordinator)
    }

    func removeChild(_ coordinator: Coordinator?) {
        guard let coordinator else { return }
        childCoordinators.removeAll { $0 === coordinator }
    }

    func childDidFinish(_ child: Coordinator?) {
        removeChild(child)
    }

    func next(viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }

    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }

    func backTo(num: Int, animated: Bool = true) {
        guard let navigationController else { return }
        guard navigationController.viewControllers.indices.contains(num) else {
            print("invalid target index: \(num)")
            return
        }

        let target = navigationController.viewControllers[num]
        navigationController.popToViewController(target, animated: animated)
    }

    func rootPop(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
    }

    func present(
        viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        navigationController?.present(viewController, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: animated, completion: completion)
    }
}
