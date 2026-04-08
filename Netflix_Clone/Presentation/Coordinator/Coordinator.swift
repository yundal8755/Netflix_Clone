//
//  Coordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit

/// 앱의 "화면 흐름(Flow)"을 담당하는 객체가 따라야 하는 공통 규약입니다.
///
/// 왜 `AnyObject` 제약이 필요한가?
/// - Coordinator는 보통 부모/자식 관계를 맺고 생명주기를 관리합니다.
/// - 이때 자식 제거 시 `===`(참조 동일성 비교)가 필요하므로 클래스 타입이어야 합니다.
/// - 또한 ViewController 쪽에서 `weak var coordinator`로 순환 참조를 피하려면
///   참조 타입(클래스) 프로토콜이어야 합니다.
protocol Coordinator: AnyObject {
    /// 현재 Coordinator가 강하게 보유하는 하위 Coordinator 목록입니다.
    /// - 중요한 이유:
    ///   하위 Coordinator를 배열에 보관하지 않으면, `start()` 직후 ARC에 의해
    ///   즉시 해제되어 화면 흐름이 중간에 끊길 수 있습니다.
    var childCoordinators: [Coordinator] { get set }

    /// 이 Coordinator가 화면 전환을 수행할 네비게이션 컨텍스트입니다.
    /// - 일부 Coordinator는 네비게이션이 필요 없을 수 있어 Optional로 둡니다.
    /// - 예: 순수 모달 라우팅 Coordinator, 탭 내부 컨테이너 Coordinator 등
    var navigationController: UINavigationController? { get }

    /// Coordinator가 담당하는 흐름의 시작점(첫 화면 진입)을 실행합니다.
    /// - 관례:
    ///   이 메서드 안에서 첫 화면을 구성하고 push/present/setRoot 합니다.
    func start()
}

extension Coordinator {
    /// 하위 Coordinator를 부모 목록에 등록합니다.
    /// - 중복 등록을 피하기 위해 동일 인스턴스는 한 번만 추가합니다.
    func addChild(_ coordinator: Coordinator) {
        guard childCoordinators.contains(where: { $0 === coordinator }) == false else { return }
        childCoordinators.append(coordinator)
    }

    /// 하위 Coordinator를 부모 목록에서 제거합니다.
    /// - 역할:
    ///   흐름 종료된 Coordinator를 정리해 메모리 누수를 방지합니다.
    /// - 주의:
    ///   이 메서드는 "화면에서 사라지는 시점"과 맞물려 호출되어야 효과가 있습니다.
    func removeChild(_ coordinator: Coordinator?) {
        guard let coordinator else { return }
        childCoordinators.removeAll { $0 === coordinator }
    }

    /// 이전 호환성을 위한 별칭 메서드입니다.
    /// - 기존 코드에서 `childDidFinish`를 쓰는 경우를 그대로 지원합니다.
    func childDidFinish(_ child: Coordinator?) {
        removeChild(child)
    }

    /// 네비게이션 스택의 다음 화면으로 push 합니다.
    /// - 기본 동작:
    ///   현재 `navigationController`를 사용해 `pushViewController`를 호출합니다.
    func next(viewController: UIViewController, animated: Bool = true) {
        navigationController?.pushViewController(viewController, animated: animated)
    }

    /// 네비게이션 스택에서 한 단계 뒤로 이동(pop)합니다.
    func back(animated: Bool = true) {
        navigationController?.popViewController(animated: animated)
    }

    /// 네비게이션 스택의 특정 index 화면으로 이동(popTo)합니다.
    /// - parameter num:
    ///   `navigationController.viewControllers` 배열 index
    /// - 사용 예:
    ///   멀티 스텝 흐름에서 특정 시작 화면으로 되돌아갈 때
    func backTo(num: Int, animated: Bool = true) {
        guard let navigationController else { return }
        guard navigationController.viewControllers.indices.contains(num) else {
            print("invalid target index: \(num)")
            return
        }

        let target = navigationController.viewControllers[num]
        navigationController.popToViewController(target, animated: animated)
    }

    /// 네비게이션 스택 루트 화면으로 이동(popToRoot)합니다.
    func rootPop(animated: Bool = true) {
        navigationController?.popToRootViewController(animated: animated)
    }

    /// 현재 네비게이션 컨텍스트 위에 모달을 표시합니다.
    func present(
        viewController: UIViewController,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        navigationController?.present(viewController, animated: animated, completion: completion)
    }

    /// 현재 표시 중인 모달을 닫습니다.
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: animated, completion: completion)
    }

    /// 지정한 ViewController를 새 UINavigationController로 감싸 모달 표시합니다.
    /// - 장점:
    ///   모달 내부에서도 push 기반 추가 이동을 구성할 수 있습니다.
    /// - `addsCloseButton == true`:
    ///   좌상단 닫기 버튼을 자동으로 주입해 dismiss 경로를 제공합니다.
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
