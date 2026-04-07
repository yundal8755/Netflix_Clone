//
//  UIView+.swift
//  Netflix_Clone
//
//  Created by mac on 4/6/26.
//

import UIKit.UIView

extension UIView {
    
    static var reuseIdentifier: String {
        return "Cell_\(Self.description())";
    }
}
