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
    /// 다음 화면으로 이동
    func next(viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }

    /// 뒤로 이동
    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }

    /// 특정 index의 화면으로 이동
    func backTo(num: Int, animated: Bool = true) {
        guard let navigationController else { return }
        guard navigationController.viewControllers.indices.contains(num) else {
            print("invalid target index: \(num)")
            return
        }

        let target = navigationController.viewControllers[num]
        navigationController.popToViewController(target, animated: animated)
    }

    /// 루트로 이동
    func rootPop(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
    }

    /// 모달 표시
    func present(
        viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        navigationController?.present(viewController, animated: animated, completion: completion)
    }

    /// 현재 모달 닫기
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: animated, completion: completion)
    }

    /// 네비게이션 컨트롤러로 감싼 모달 표시
    func presentWrappedInNavigation(
        _ viewController: UIViewController,
        from presentingViewController: UIViewController? = nil,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        addsCloseButton: Bool = true,
        animated: Bool = true
    ) {
        let modalNavigationController = UINavigationController(rootViewController: viewController)

        if addsCloseButton {
            viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(
                systemItem: .close,
                primaryAction: UIAction { [weak modalNavigationController] _ in
                    modalNavigationController?.dismiss(animated: true)
                }
            )
        }

        modalNavigationController.modalPresentationStyle = modalPresentationStyle

        if let presentingViewController {
            presentingViewController.present(modalNavigationController, animated: animated)
        } else {
            navigationController?.present(modalNavigationController, animated: animated)
        }
    }
}
