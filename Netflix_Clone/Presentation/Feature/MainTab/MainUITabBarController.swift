//
//  MainUITabBarController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import UIKit

/// Main 탭 화면의 UI 책임만 담당하는 전용 UITabBarController입니다.
/// - Coordinator와의 경계:
///   Coordinator는 어떤 화면 흐름을 붙일지 결정하고,
///   이 클래스는 탭바의 외형/아이템 구성처럼 순수 UI 로직만 담당합니다.
final class MainUITabBarController: UITabBarController {

    struct Scene {
        let tab: MainTab
        let rootViewController: UIViewController
    }

    private let scenes: [Scene]
    private let initialTab: MainTab

    init(
        scenes: [Scene],
        initialTab: MainTab = .home
    ) {
        self.scenes = scenes
        self.initialTab = initialTab
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        configureTabScenes()
        selectInitialTab()
    }
}

private extension MainUITabBarController {
    func configureUI() {
        view.backgroundColor = .black

        tabBar.tintColor = .red
        tabBar.unselectedItemTintColor = UIColor(white: 1.0, alpha: 0.72)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black

        tabBar.isTranslucent = false
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    func configureTabScenes() {
        let controllers = scenes.map { scene -> UIViewController in
            scene.rootViewController.tabBarItem = UITabBarItem(
                title: scene.tab.title,
                image: UIImage(systemName: scene.tab.symbolName),
                selectedImage: UIImage(systemName: scene.tab.selectedSymbolName)
            )
            return scene.rootViewController
        }

        setViewControllers(controllers, animated: false)
    }

    func selectInitialTab() {
        guard scenes.isEmpty == false else {
            selectedIndex = 0
            return
        }

        selectedIndex = scenes.firstIndex(where: { $0.tab == initialTab }) ?? 0
    }
}
