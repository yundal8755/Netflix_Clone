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
    case continueWatching
    case myList

    var headerTitle: String? {
        switch self {
        case .profileInfo:
            return nil
        case .continueWatching:
            return "시청 중인 콘텐츠"
        case .myList:
            return "내가 찜한 콘텐츠"
        }
    }
}

final class ProfileViewController: BaseViewController<ProfileView> {
    private enum ItemIdentifier {
        static let profileInfo = "profile-info"
        static let continueWatchingPrefix = "continue-"
        static let myListPrefix = "my-list-"
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Int, String>

    private let viewModel: ProfileViewModel

    private var dataSource: DataSource?
    private var currentViewState: ProfileViewModel.ViewState?

    private var continueWatchingMap: [UUID: PosterItem] = [:]
    private var myListMap: [UUID: PosterItem] = [:]

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

        mainView.collectionView.register(
            PosterCollectionViewCell.self,
            forCellWithReuseIdentifier: PosterCollectionViewCell.reuseIdentifier
        )

        mainView.collectionView.register(
            ProfileCollectionSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ProfileCollectionSectionHeaderView.reuseIdentifier
        )
    }

    func setupDataSource() {
        dataSource = DataSource(collectionView: mainView.collectionView) { [weak self] collectionView, indexPath, item in
            guard let self else { return UICollectionViewCell() }

            if item == ItemIdentifier.profileInfo {
                guard let cell = collectionView.dequeueReusableCell(
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

            if item.hasPrefix(ItemIdentifier.continueWatchingPrefix) {
                let idString = item.replacingOccurrences(
                    of: ItemIdentifier.continueWatchingPrefix,
                    with: ""
                )
                let uuid = UUID(uuidString: idString)
                return self.makePosterCell(
                    collectionView: collectionView,
                    indexPath: indexPath,
                    posterItem: uuid.flatMap { self.continueWatchingMap[$0] }
                )
            }

            let idString = item.replacingOccurrences(
                of: ItemIdentifier.myListPrefix,
                with: ""
            )
            let uuid = UUID(uuidString: idString)

            return self.makePosterCell(
                collectionView: collectionView,
                indexPath: indexPath,
                posterItem: uuid.flatMap { self.myListMap[$0] }
            )
        }

        dataSource?.supplementaryViewProvider = { collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader else { return nil }
            guard let section = ProfileCollectionSection(rawValue: indexPath.section),
                  let title = section.headerTitle else {
                return nil
            }

            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: ProfileCollectionSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? ProfileCollectionSectionHeaderView else {
                return nil
            }

            headerView.configure(title: title)
            return headerView
        }
    }

    func makePosterCell(
        collectionView: UICollectionView,
        indexPath: IndexPath,
        posterItem: PosterItem?
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PosterCollectionViewCell.reuseIdentifier,
            for: indexPath
        ) as? PosterCollectionViewCell else {
            return UICollectionViewCell()
        }

        if let posterItem {
            cell.configure(with: posterItem)
        }

        return cell
    }

    func setupBindings() {
        bindInput()
        bindOutput()
    }

    func bindInput() {
//        rx.viewWillAppear
//            .bind(with: self) { owner, _ in
//                owner.navigationController?.setNavigationBarHidden(false, animated: false)
//            }
//            .disposed(by: rx.disposeBag)
//        rx.viewWillDisappear
//            .map { $0 }
//            .bind(with: self) { owner, _ in
//                owner.navigationController?.setNavigationBarHidden(true, animated: false)
//            }
//            .disposed(by: rx.disposeBag)
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
        continueWatchingMap = Dictionary(uniqueKeysWithValues: state.continueWatching.map { ($0.id, $0.posterItem) })
        myListMap = Dictionary(uniqueKeysWithValues: state.myList.map { ($0.id, $0.posterItem) })
        applySnapshot()
    }

    func applySnapshot() {
        guard let dataSource,
              let state = currentViewState else { return }

        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections(ProfileCollectionSection.allCases.map(\.rawValue))
        snapshot.appendItems([ItemIdentifier.profileInfo], toSection: ProfileCollectionSection.profileInfo.rawValue)
        snapshot.appendItems(
            state.continueWatching.map { ItemIdentifier.continueWatchingPrefix + $0.id.uuidString },
            toSection: ProfileCollectionSection.continueWatching.rawValue
        )
        snapshot.appendItems(
            state.myList.map { ItemIdentifier.myListPrefix + $0.id.uuidString },
            toSection: ProfileCollectionSection.myList.rawValue
        )
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
            case .continueWatching:
                return self.makeContinueWatchingSection()
            case .myList:
                return self.makeMyListSection()
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

    func makeContinueWatchingSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.4),
            heightDimension: .fractionalWidth(0.6)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 28, trailing: 20)
        section.interGroupSpacing = 12
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }

    func makeMyListSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0 / 3.0),
            heightDimension: .fractionalHeight(1)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalWidth(0.5)
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSize,
            repeatingSubitem: item,
            count: 3
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 12
        section.boundarySupplementaryItems = [makeSectionHeader()]
        return section
    }

    func makeSectionHeader() -> NSCollectionLayoutBoundarySupplementaryItem {
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.pinToVisibleBounds = true
        header.zIndex = 2
        return header
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
