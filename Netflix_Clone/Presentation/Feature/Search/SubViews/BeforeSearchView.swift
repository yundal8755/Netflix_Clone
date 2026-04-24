import UIKit
import SnapKit
import Then

final class BeforeSearchView: BaseView {
    private typealias SectionID = Int
    private typealias ItemID = Int
    private typealias DataSource = UICollectionViewDiffableDataSource<SectionID, ItemID>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<SectionID, ItemID>

    private let mainSection = 0
    private var itemsByID: [ItemID: ListTileContent] = [:]

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: BeforeSearchView.makeLayout()).then {
        $0.backgroundColor = .clear
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceVertical = true
        $0.register(
            ListTileCollectionViewCell.self,
            forCellWithReuseIdentifier: ListTileCollectionViewCell.cellID
        )
    }

    private lazy var dataSource: DataSource = {
        DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, itemID in
            guard let self,
                  let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ListTileCollectionViewCell.cellID,
                    for: indexPath
                  ) as? ListTileCollectionViewCell,
                  let item = self.itemsByID[itemID] else {
                return UICollectionViewCell()
            }
            
            cell.configure(with: item)
            return cell
        }
    }()
    
    // MARK: - Base
    
    override func configurationSetView() {
        addSubview(collectionView)
    }

    override func configurationLayout() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func configurationUI() {
        backgroundColor = .black
        apply(items: [], animated: false)
    }
}

// MARK: - Logic

extension BeforeSearchView {
    
    func apply(items: [ListTileContent], animated: Bool = true) {
        itemsByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        var snapshot = Snapshot()
        snapshot.appendSections([mainSection])
        snapshot.appendItems(items.map(\.id),toSection: mainSection)

        dataSource.apply(snapshot, animatingDifferences: animated)
    }
    
    static func makeLayout() -> UICollectionViewLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.showsSeparators = false
        config.backgroundColor = .clear

        return UICollectionViewCompositionalLayout.list(using: config)
    }
}


