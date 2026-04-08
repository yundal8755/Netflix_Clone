//
//  AppCoordinator.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit

/// 앱의 최상위 네비게이션 컨트롤러입니다.
/// - 목적:
///   상태바 스타일/숨김 여부를 "현재 최상단 화면(topViewController)" 기준으로 일관되게 위임합니다.
/// - 효과:
///   루트가 `UINavigationController`여도 각 화면의 상태바 정책이 정상 반영됩니다.
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

/// 앱의 전역 흐름을 시작하는 최상위 Coordinator입니다.
/// - 책임:
///   1) 윈도우 루트 설정
///   2) 첫 진입 플로우(현재는 MainTab) 시작
///   3) 자식 Coordinator 생명주기 보관
final class AppCoordinator: Coordinator {

    /// 하위 흐름(Coordinator)을 강하게 보관합니다.
    /// - ARC 관점에서 매우 중요: 보관하지 않으면 흐름 객체가 조기 해제될 수 있습니다.
    var childCoordinators: [Coordinator] = []

    /// Coordinator 프로토콜 요구사항을 충족하는 네비게이션 컨텍스트입니다.
    /// 내부적으로는 `rootNavigationController`를 그대로 노출합니다.
    var navigationController: UINavigationController? { rootNavigationController }

    /// 앱 생명주기와 함께 유지되는 `UIWindow`를 약한 참조로 보관합니다.
    /// - SceneDelegate가 window를 강하게 소유하므로 여기서는 weak로 충분합니다.
    private weak var window: UIWindow?

    /// 앱 루트 네비게이션 컨트롤러(항상 존재)입니다.
    private let rootNavigationController: RootNavigationController

    /// `start()` 중복 호출 방지 플래그입니다.
    /// - 동일 Scene에서 중복 초기화 시 불필요한 화면 재구성을 방지합니다.
    private var didStart = false

    init(window: UIWindow) {
        self.window = window
        self.rootNavigationController = RootNavigationController()
    }

    func start() {
        guard didStart == false else { return }
        guard let window else { return }
        didStart = true

        // 루트 Navigation Bar는 숨기고, 실제 화면에서 필요한 헤더/UI만 노출합니다.
        rootNavigationController.setNavigationBarHidden(true, animated: false)

        // Scene의 루트는 최상위 네비게이션 컨테이너가 담당합니다.
        window.rootViewController = rootNavigationController

        showMainTabFlow()
    }

    /// 앱 메인 탭 흐름을 시작합니다.
    /// - 현재 앱 구조에서 첫 진입 플로우는 MainTab 하나로 고정되어 있습니다.
    private func showMainTabFlow() {
        let mainTabCoordinator = MainTabCoordinator(navigationController: rootNavigationController)
        childCoordinators.removeAll()
        addChild(mainTabCoordinator)
        mainTabCoordinator.start()
    }
}
