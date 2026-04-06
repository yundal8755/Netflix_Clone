//
//  ProfileView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit
import SnapKit

final class ProfileView: BaseView {
    private enum Metric {
        static let horizontalInset: CGFloat = 24
        static let imageSize: CGFloat = 110
        static let fieldHeight: CGFloat = 52
        static let buttonHeight: CGFloat = 54
        static let stackSpacing: CGFloat = 16
    }

    private let contentStackView = UIStackView()
    private let nicknameTitleLabel = UILabel()
    private let statusTitleLabel = UILabel()
    private let imageContainerView = UIView()
    let profileImageView = UIImageView()
    let nicknameTextField = UITextField()
    let statusMessageTextField = UITextField()
    let saveButton = UIButton(type: .system)

    override func configurationSetView() {
        addSubview(contentStackView)

        imageContainerView.addSubview(profileImageView)

        contentStackView.addArrangedSubview(imageContainerView)
        contentStackView.addArrangedSubview(nicknameTitleLabel)
        contentStackView.addArrangedSubview(nicknameTextField)
        contentStackView.addArrangedSubview(statusTitleLabel)
        contentStackView.addArrangedSubview(statusMessageTextField)
        contentStackView.addArrangedSubview(saveButton)
    }

    override func configurationLayout() {
        contentStackView.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(32)
            make.horizontalEdges.equalToSuperview().inset(Metric.horizontalInset)
        }

        imageContainerView.snp.makeConstraints { make in
            make.height.equalTo(Metric.imageSize)
        }

        profileImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Metric.imageSize)
        }

        nicknameTextField.snp.makeConstraints { make in
            make.height.equalTo(Metric.fieldHeight)
        }

        statusMessageTextField.snp.makeConstraints { make in
            make.height.equalTo(Metric.fieldHeight)
        }

        saveButton.snp.makeConstraints { make in
            make.height.equalTo(Metric.buttonHeight)
        }
    }

    override func configurationUI() {
        backgroundColor = .black

        contentStackView.axis = .vertical
        contentStackView.spacing = Metric.stackSpacing

        imageContainerView.backgroundColor = .clear

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.tintColor = .white
        profileImageView.backgroundColor = UIColor(white: 0.14, alpha: 1)
        profileImageView.layer.cornerRadius = Metric.imageSize / 2
        profileImageView.clipsToBounds = true

        nicknameTitleLabel.text = "Nickname"
        nicknameTitleLabel.textColor = .white
        nicknameTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        statusTitleLabel.text = "Status Message"
        statusTitleLabel.textColor = .white
        statusTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)

        configureTextField(
            nicknameTextField,
            placeholder: "닉네임을 입력해 주세요"
        )

        configureTextField(
            statusMessageTextField,
            placeholder: "상태 메시지를 입력해 주세요"
        )

        saveButton.setTitle("저장", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = UIColor(red: 229 / 255, green: 9 / 255, blue: 20 / 255, alpha: 1)
        saveButton.layer.cornerRadius = 10
        saveButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)

        updateProfileImage(named: "")
    }

    func updateProfileImage(named imageName: String) {
        if let image = UIImage(named: imageName), imageName.isEmpty == false {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }

    private func configureTextField(
        _ textField: UITextField,
        placeholder: String
    ) {
        textField.backgroundColor = UIColor(white: 0.12, alpha: 1)
        textField.textColor = .white
        textField.tintColor = .white
        textField.layer.cornerRadius = 10
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 0))
        textField.leftViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(white: 0.65, alpha: 1)
            ]
        )
    }
}
