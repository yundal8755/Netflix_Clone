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
        static let profileButtonSize: CGFloat = 28
    }

    private let profileRepository: ProfileRepositoryType = ProfileRepository()
    
    let menuButton: UIButton = {
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
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
        button.tintColor = .white
        button.contentMode = .scaleAspectFill
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
            make.size.equalTo(Metric.profileButtonSize)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .clear
        profileButton.layer.cornerRadius = Metric.profileButtonSize / 2
        profileButton.clipsToBounds = true
        profileButton.imageView?.contentMode = .scaleAspectFill

        bindProfileImageUpdates()
        loadProfileImageFromLocalDB()
    }
}

private extension TopBarView {
    func bindProfileImageUpdates() {
        NotificationCenter.default.addObserver(
            forName: .profileDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }

            if let profileImageName = notification.userInfo?[ProfileNotificationUserInfoKey.profileImageName] as? String {
                self.updateProfileImage(named: profileImageName)
                return
            }

            self.loadProfileImageFromLocalDB()
        }
    }

    func loadProfileImageFromLocalDB() {
        Task { [weak self] in
            guard let self else { return }

            do {
                let profile = try await self.profileRepository.fetchProfile()
                await MainActor.run {
                    self.updateProfileImage(named: profile.profileImageName)
                }
            } catch {
                await MainActor.run {
                    self.applyDefaultProfileImage()
                }
            }
        }
    }

    func updateProfileImage(named profileImageName: String) {
        guard let image = image(from: profileImageName) else {
            applyDefaultProfileImage()
            return
        }

        profileButton.setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
    }

    func applyDefaultProfileImage() {
        profileButton.setImage(UIImage(systemName: "person.crop.circle.fill"), for: .normal)
        profileButton.tintColor = .white
    }

    func image(from profileImageName: String) -> UIImage? {
        guard profileImageName.isEmpty == false else { return nil }

        if profileImageName.hasPrefix("/") {
            return UIImage(contentsOfFile: profileImageName)
        }

        if profileImageName.hasPrefix("file://"),
           let url = URL(string: profileImageName) {
            return UIImage(contentsOfFile: url.path)
        }

        return UIImage(named: profileImageName)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
