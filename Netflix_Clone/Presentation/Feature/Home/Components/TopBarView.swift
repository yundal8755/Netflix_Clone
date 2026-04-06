//
//  TopBarView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import UIKit
import SnapKit

final class TopBarView: BaseView {
    private let menuButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.preferredSymbolConfigurationForImage = .init(pointSize: 16, weight: .regular)
        config.image = UIImage(systemName: "line.3.horizontal")
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        return button
    }()

    private let netflixLabel: UILabel = {
        let label = UILabel()
        label.text = "NETFLIX"
        label.textColor = UIColor(red: 229 / 255, green: 9 / 255, blue: 20 / 255, alpha: 1)
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.shadowColor = .blue
        label.shadowOffset = CGSize(width: 2, height: 5)
        return label
    }()

    let profileButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.preferredSymbolConfigurationForImage = .init(pointSize: 24, weight: .regular)
        config.image = UIImage(systemName: "person.crop.circle.fill")
        config.baseForegroundColor = .white

        let button = UIButton(configuration: config)
        button.accessibilityIdentifier = "home.profile.button"
        return button
    }()

    override func configurationSetView() {
        addSubview(menuButton)
        addSubview(netflixLabel)
        addSubview(profileButton)
    }

    override func configurationLayout() {
        menuButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        netflixLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        profileButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .clear
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
