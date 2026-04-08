//
//  TopBarView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import UIKit
import SnapKit

final class TopBarView: BaseView {

    private enum Metric {
        static let searchButtonSize: CGFloat = 28
    }

    private let netflixLabel: UILabel = {
        let label = UILabel()
        label.text = "NETFLIX"
        label.textColor = UIColor(red: 229 / 255, green: 9 / 255, blue: 20 / 255, alpha: 1)
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.shadowColor = .blue
        label.shadowOffset = CGSize(width: 2, height: 5)
        return label
    }()

    let searchButton: UIButton = {
        let button = UIButton(type: .custom)
        let imageConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        button.setImage(UIImage(systemName: "magnifyingglass", withConfiguration: imageConfig), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor(white: 1, alpha: 0.14)
        button.accessibilityIdentifier = "home.search.button"
        return button
    }()

    override func configurationSetView() {
        addSubview(netflixLabel)
        addSubview(searchButton)
    }

    override func configurationLayout() {
        netflixLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        searchButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(Metric.searchButtonSize)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .clear
        searchButton.layer.cornerRadius = Metric.searchButtonSize / 2
        searchButton.clipsToBounds = true
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
