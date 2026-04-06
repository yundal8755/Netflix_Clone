//
//  SceneDelegate.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // 1. iOS가 준 scene 정보 확인
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // 2. 앱의 전체 틀이 될 window를 제작
        let window = UIWindow(windowScene: windowScene)
        
        // 3. ViewController 생성
        let vc = HomeViewController()
        
        // 4. 창의 첫 페이지로 네비게이션을 지정
        let nav = UINavigationController(rootViewController: vc)
        window.rootViewController = nav
        
        // 5. 창을 메모리에 유지
        self.window = window
        
        // 6. 화면에 창을 띄우기. 이 순간 뷰 생명주기가 시작됨
        // 뷰 생명주기의 시작 = 첫 ViewController에서 loadView() 호출
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
