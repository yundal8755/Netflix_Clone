//
//  BaseView.swift
//  Netflix_Clone
//
//  Created by mac on 4/1/26.
//

import UIKit

protocol BaseViewProtocol: UIView {
    func configurationSetView()
    func configurationLayout()
    func configurationUI()
}

class BaseView: UIView, BaseViewProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configurationSetView() {}
    func configurationLayout() {}
    func configurationUI() {}
}
