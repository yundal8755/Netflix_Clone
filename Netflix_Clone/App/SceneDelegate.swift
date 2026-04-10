//
//  SceneDelegate.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit
import Kingfisher
import SwiftyBeaver

let Logger = SwiftyBeaver.self

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 300 * 1024 * 1024   // 300MB
        cache.memoryStorage.config.countLimit = 300
        cache.memoryStorage.config.expiration = .days(7)
        
        cache.diskStorage.config.sizeLimit = 1_000 * 1024 * 1024         // 1GB
        cache.diskStorage.config.expiration = .days(7)
        
        // 2) 전역 기본 옵션
        KingfisherManager.shared.defaultOptions = [
            .targetCache(cache),
            .cacheOriginalImage
        ]
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let appCoordinator = AppCoordinator(window: window)
        self.appCoordinator = appCoordinator
        
        appCoordinator.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
}
