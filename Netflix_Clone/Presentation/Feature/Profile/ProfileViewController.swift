//
//  ProfileViewController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/6/26.
//

import UIKit
import PhotosUI
import RxCocoa
import RxRelay
import RxSwift
import NSObject_Rx

private enum ProfileCollectionSection: Int, CaseIterable {
    case profileInfo
}

final class ProfileViewController: BaseViewController<ProfileView> {
    private enum ItemIdentifier {
        static let profileInfo = "profile-info"
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Int, String>

    private let viewModel: ProfileViewModel

    private var dataSource: DataSource?
    private var currentViewState: ProfileViewModel.ViewState?

    private let nicknameChangedRelay = PublishRelay<String>()
    private let statusMessageChangedRelay = PublishRelay<String>()
    private let saveButtonTappedRelay = PublishRelay<Void>()
    private let profileImagePickedRelay = PublishRelay<Data>()

    var onDismiss: (() -> Void)?

    init(
        viewModel: ProfileViewModel = ProfileViewModel(),
        onDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        false
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "마이페이지"
        navigationItem.largeTitleDisplayMode = .never
        configureNavigationBarAppearance()

        setupCollectionView()
        setupDataSource()
        setupBindings()

        viewModel.send(action: .viewDidLoad)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBarAppearance()
        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        restoreNavigationBarAppearance()
    }
}

private extension ProfileViewController {
    func setupCollectionView() {
        mainView.collectionView.collectionViewLayout = makeLayout()

        mainView.collectionView.register(
            ProfileInfoCollectionViewCell.self,
            forCellWithReuseIdentifier: ProfileInfoCollectionViewCell.reuseIdentifier
        )
    }

    func setupDataSource() {
        dataSource = DataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }

            guard item == ItemIdentifier.profileInfo,
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ProfileInfoCollectionViewCell.reuseIdentifier,
                    for: indexPath
                  ) as? ProfileInfoCollectionViewCell else {
                return UICollectionViewCell()
            }

            if let state = self.currentViewState {
                cell.configure(
                    nickname: state.nickname,
                    statusMessage: state.statusMessage,
                    profileImageName: state.profileImageName,
                    isSaving: state.isSaving
                )
            }

            cell.onTapProfileImage = { [weak self] in
                self?.presentPhotoPicker()
            }

            cell.onNicknameChanged = { [weak self] nickname in
                self?.nicknameChangedRelay.accept(nickname)
            }

            cell.onStatusMessageChanged = { [weak self] statusMessage in
                self?.statusMessageChangedRelay.accept(statusMessage)
            }

            cell.onTapSaveButton = { [weak self] in
                self?.saveButtonTappedRelay.accept(())
            }

            return cell
        }
    }

    func setupBindings() {
        bindInput()
        bindOutput()
    }

    func bindInput() {
        rx.viewDidDisappear
            .map { $0 }
            .bind(with: self) { owner, _ in
                owner.onDismiss?()
            }
            .disposed(by: rx.disposeBag)

        nicknameChangedRelay
            .distinctUntilChanged()
            .bind(with: self) { owner, nickname in
                owner.viewModel.send(action: .nicknameChanged(nickname))
            }
            .disposed(by: rx.disposeBag)

        statusMessageChangedRelay
            .distinctUntilChanged()
            .bind(with: self) { owner, statusMessage in
                owner.viewModel.send(action: .statusMessageChanged(statusMessage))
            }
            .disposed(by: rx.disposeBag)

        saveButtonTappedRelay
            .bind(with: self) { owner, _ in
                owner.viewModel.send(action: .saveButtonTapped)
            }
            .disposed(by: rx.disposeBag)

        profileImagePickedRelay
            .bind(with: self) { owner, imageData in
                owner.viewModel.send(action: .profileImagePicked(imageData))
            }
            .disposed(by: rx.disposeBag)
    }

    func bindOutput() {
        viewModel.output.viewState
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, state in
                owner.render(state: state)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.saveCompleted
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.view.endEditing(true)
                owner.presentMessageAlert(message: message)
            }
            .disposed(by: rx.disposeBag)

        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(with: self) { owner, message in
                owner.presentMessageAlert(message: message)
            }
            .disposed(by: rx.disposeBag)
    }

    func render(state: ProfileViewModel.ViewState) {
        currentViewState = state
        applySnapshot()
    }

    func applySnapshot() {
        guard let dataSource else { return }

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections(ProfileCollectionSection.allCases.map(\.rawValue))
        snapshot.appendItems([ItemIdentifier.profileInfo], toSection: ProfileCollectionSection.profileInfo.rawValue)
        snapshot.reconfigureItems([ItemIdentifier.profileInfo])

        let shouldAnimate = mainView.window != nil
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
    }

    func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self,
                  let section = ProfileCollectionSection(rawValue: sectionIndex) else {
                return nil
            }

            switch section {
            case .profileInfo:
                return self.makeProfileInfoSection()
            }
        }
    }

    func makeProfileInfoSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(460)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 0, bottom: 22, trailing: 0)
        return section
    }

    func presentPhotoPicker() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }

    func configureNavigationBarAppearance() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.prefersLargeTitles = false
        navigationBar.tintColor = .white
        navigationBar.barStyle = .black
        navigationBar.isTranslucent = false
        navigationBar.transform = .identity
        navigationBar.alpha = 1
    }

    func restoreNavigationBarAppearance() {
        navigationController?.navigationBar.transform = .identity
        navigationController?.navigationBar.alpha = 1
    }
}

extension ProfileViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        dismiss(animated: true)

        guard let itemProvider = results.first?.itemProvider else { return }
        guard itemProvider.canLoadObject(ofClass: UIImage.self) else { return }

        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let self,
                  let image = object as? UIImage else { return }

            let imageData = image.jpegData(compressionQuality: 0.85) ?? image.pngData()
            guard let imageData else { return }

            DispatchQueue.main.async {
                self.profileImagePickedRelay.accept(imageData)
            }
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    ProfileViewController() {}
}
#endif
