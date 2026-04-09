//
//  ProfileView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit
import SnapKit

final class ProfileView: BaseView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "마이페이지"
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    } ()
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())

    override func configurationSetView() {
        addSubview(titleLabel)
        addSubview(collectionView)
    }

    override func configurationLayout() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide).offset(16)
            make.horizontalEdges.equalToSuperview().inset(20)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .black

        collectionView.backgroundColor = .black
        collectionView.keyboardDismissMode = .onDrag
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
    }
}

final class ProfileInfoCollectionViewCell: UICollectionViewCell {
    private enum Metric {
        static let containerInset: CGFloat = 20
        static let contentInsetHorizontal: CGFloat = 20
        static let contentInsetVertical: CGFloat = 20
        static let imageSize: CGFloat = 110
        static let fieldHeight: CGFloat = 52
        static let buttonHeight: CGFloat = 52
        static let stackSpacing: CGFloat = 18
        static let textFieldInnerHorizontalPadding: CGFloat = 16
    }

    var onTapProfileImage: (() -> Void)?
    var onNicknameChanged: ((String) -> Void)?
    var onStatusMessageChanged: ((String) -> Void)?
    var onTapSaveButton: (() -> Void)?

    private var isProgrammaticTextUpdate = false

    private let containerView = UIView()
    private let contentStackView = UIStackView()

    private let imageContainerView = UIView()
    private let profileImageView = UIImageView()
    private let cameraBadgeView = UIImageView()

    private let nicknameTitleLabel = UILabel()
    private let statusTitleLabel = UILabel()

    private let nicknameTextField = UITextField()
    private let statusMessageTextField = UITextField()
    private let saveButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
        bindEvents()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTapProfileImage = nil
        onNicknameChanged = nil
        onStatusMessageChanged = nil
        onTapSaveButton = nil
    }

    func configure(
        nickname: String,
        statusMessage: String,
        profileImageName: String,
        isSaving: Bool
    ) {
        isProgrammaticTextUpdate = true

        if nicknameTextField.text != nickname {
            nicknameTextField.text = nickname
        }

        if statusMessageTextField.text != statusMessage {
            statusMessageTextField.text = statusMessage
        }

        saveButton.isEnabled = !isSaving
        saveButton.alpha = isSaving ? 0.6 : 1

        updateProfileImage(with: profileImageName)

        isProgrammaticTextUpdate = false
    }
}

private extension ProfileInfoCollectionViewCell {
    func configurationSetView() {
        contentView.addSubview(containerView)

        containerView.addSubview(contentStackView)

        imageContainerView.addSubview(profileImageView)
        imageContainerView.addSubview(cameraBadgeView)

        contentStackView.addArrangedSubview(imageContainerView)
        contentStackView.addArrangedSubview(nicknameTitleLabel)
        contentStackView.addArrangedSubview(nicknameTextField)
        contentStackView.addArrangedSubview(statusTitleLabel)
        contentStackView.addArrangedSubview(statusMessageTextField)
        contentStackView.addArrangedSubview(saveButton)
    }

    func configurationLayout() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Metric.containerInset)
        }

        contentStackView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(Metric.contentInsetHorizontal)
            make.verticalEdges.equalToSuperview().inset(Metric.contentInsetVertical)
        }

        imageContainerView.snp.makeConstraints { make in
            make.height.equalTo(Metric.imageSize)
        }

        profileImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(Metric.imageSize)
        }

        cameraBadgeView.snp.makeConstraints { make in
            make.trailing.equalTo(profileImageView.snp.trailing).offset(-6)
            make.bottom.equalTo(profileImageView.snp.bottom).offset(-6)
            make.size.equalTo(24)
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

    func configurationUI() {
        contentView.backgroundColor = .clear

        containerView.backgroundColor = UIColor(white: 0.1, alpha: 1)
        containerView.layer.cornerRadius = 18
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor(white: 1, alpha: 0.08).cgColor

        contentStackView.axis = .vertical
        contentStackView.spacing = Metric.stackSpacing
        contentStackView.setCustomSpacing(10, after: nicknameTitleLabel)
        contentStackView.setCustomSpacing(10, after: statusTitleLabel)

        imageContainerView.backgroundColor = .clear
        imageContainerView.isUserInteractionEnabled = true

        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = Metric.imageSize / 2
        profileImageView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        profileImageView.tintColor = .white
        profileImageView.image = UIImage(systemName: "person.crop.circle.fill")

        cameraBadgeView.image = UIImage(systemName: "camera.fill")
        cameraBadgeView.tintColor = .white
        cameraBadgeView.contentMode = .scaleAspectFit
        cameraBadgeView.backgroundColor = .gray
        cameraBadgeView.layer.cornerRadius = 12
        cameraBadgeView.clipsToBounds = true

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
    }

    func bindEvents() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        imageContainerView.addGestureRecognizer(tapGesture)

        nicknameTextField.addTarget(
            self,
            action: #selector(nicknameTextDidChange(_:)),
            for: .editingChanged
        )

        statusMessageTextField.addTarget(
            self,
            action: #selector(statusMessageTextDidChange(_:)),
            for: .editingChanged
        )

        saveButton.addTarget(
            self,
            action: #selector(didTapSaveButton),
            for: .touchUpInside
        )
    }

    func configureTextField(
        _ textField: UITextField,
        placeholder: String
    ) {
        textField.backgroundColor = UIColor(white: 0.12, alpha: 1)
        textField.textColor = .white
        textField.tintColor = .white
        textField.layer.cornerRadius = 10
        textField.leftView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Metric.textFieldInnerHorizontalPadding,
                height: 0
            )
        )
        textField.leftViewMode = .always
        textField.rightView = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Metric.textFieldInnerHorizontalPadding,
                height: 0
            )
        )
        textField.rightViewMode = .always
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(white: 0.65, alpha: 1)
            ]
        )
    }

    func updateProfileImage(with profileImageName: String) {
        if let image = profileImage(from: profileImageName) {
            profileImageView.image = image
        } else {
            profileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        }
    }

    func profileImage(from profileImageName: String) -> UIImage? {
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

    @objc func didTapProfileImage() {
        onTapProfileImage?()
    }

    @objc func nicknameTextDidChange(_ textField: UITextField) {
        guard isProgrammaticTextUpdate == false else { return }
        onNicknameChanged?(textField.text ?? "")
    }

    @objc func statusMessageTextDidChange(_ textField: UITextField) {
        guard isProgrammaticTextUpdate == false else { return }
        onStatusMessageChanged?(textField.text ?? "")
    }

    @objc func didTapSaveButton() {
        onTapSaveButton?()
    }
}
