//
//  ProfileViewController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit
import RxCocoa
import RxSwift
import NSObject_Rx

final class ProfileViewController: BaseViewController<ProfileView> {
    private let viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Profile"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .black

        setupBindings()
        viewModel.input.accept(.viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupBindings() {
        bindInput()
        bindOutput()
    }

    private func bindInput() {
        mainView.saveButton.rx.tap
            .withLatestFrom(
                Observable.combineLatest(
                    mainView.nicknameTextField.rx.text.orEmpty,
                    mainView.statusMessageTextField.rx.text.orEmpty
                )
            )
            .map { values in
                ProfileViewModelInput.saveButtonTapped(
                    nickname: values.0,
                    statusMessage: values.1
                )
            }
            .bind(to: viewModel.input)
            .disposed(by: rx.disposeBag)
    }

    private func bindOutput() {
        viewModel.output.nickname
            .observe(on: MainScheduler.instance)
            .bind(to: mainView.nicknameTextField.rx.text)
            .disposed(by: rx.disposeBag)

        viewModel.output.statusMessage
            .observe(on: MainScheduler.instance)
            .bind(to: mainView.statusMessageTextField.rx.text)
            .disposed(by: rx.disposeBag)

        viewModel.output.profileImageName
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, imageName in
                owner.mainView.updateProfileImage(named: imageName)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.isSaving
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, isSaving in
                owner.mainView.saveButton.isEnabled = !isSaving
                owner.mainView.saveButton.alpha = isSaving ? 0.6 : 1
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.saveCompleted
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.view.endEditing(true)
                owner.presentAlert(message: message)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.presentAlert(message: message)
            }
            .disposed(by: rx.disposeBag)
    }

    private func presentAlert(message: String) {
        let alertController = UIAlertController(
            title: "알림",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "확인", style: .default))
        present(alertController, animated: true)
    }
}
