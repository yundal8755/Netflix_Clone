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
}

