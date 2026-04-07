//
//  BaseViewController.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit

class BaseViewController<V: UIView>: UIViewController {
    let mainView = V()
    
    override func loadView() {
        super.loadView()
        self.view = mainView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Presentation Helpers

    // 공통 알럿 표시 헬퍼:
    // - 화면 전반에서 동일한 스타일의 단일 확인(alert) UI를 재사용하기 위한 메서드
    // - BaseViewController에 두면 Feature VC들에서 중복 코드를 제거할 수 있습니다.
    func presentMessageAlert(
        title: String? = nil,
        message: String,
        okTitle: String = "OK",
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(
            UIAlertAction(
                title: okTitle,
                style: .default,
                handler: { _ in completion?() }
            )
        )
        present(alert, animated: animated)
    }
}
