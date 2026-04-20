import UIKit
import SnapKit
import Kingfisher

struct ListTileContent: Hashable {
    let id: Int
    let title: String
    let posterUrl: URL?
    let playUrl: URL?
}

final class ListTileView: BaseView {
    private enum Metric {
        static let horizontalInset: CGFloat = 12
        static let interItemSpacing: CGFloat = 12
        static let thumbnailHeight: CGFloat = 72
        static let playButtonSize: CGFloat = 52
        static let cornerRadius: CGFloat = 8
    }
    
    private let thumbnailView = UIImageView()
    private let titleLabel = UILabel()
    private let playImageView = UIImageView()
    

    // MARK: - Base
    
    override func configurationSetView() {
        addSubview(thumbnailView)
        addSubview(titleLabel)
        addSubview(playImageView)
    }

    override func configurationLayout() {
        thumbnailView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Metric.horizontalInset)
            make.centerY.equalToSuperview()
            make.height.equalTo(Metric.thumbnailHeight)
            make.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(thumbnailView.snp.height).multipliedBy(16.0 / 9.0)
        }

        playImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Metric.horizontalInset)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailView.snp.trailing).offset(Metric.interItemSpacing)
            make.trailing.equalTo(playImageView.snp.leading).offset(-Metric.interItemSpacing)
            make.centerY.equalToSuperview()
        }
    }

    override func configurationUI() {
        setThumbnailView() // 썸네일
        setTitleLabel() // 타이틀
        setPlayImageView() // 재생라벨
    }
}

// MARK: UI Component
extension ListTileView {
    
    private func setThumbnailView() {
        thumbnailView.layer.cornerRadius = 6
        thumbnailView.clipsToBounds = true
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.backgroundColor = .darkGray
    }
    
    private func setTitleLabel() {
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 14, weight: .regular)
        titleLabel.numberOfLines = 1
    }
    
    private func setPlayImageView() {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let image = UIImage(systemName: "play.circle", withConfiguration: config)
        playImageView.image = image
        playImageView.tintColor = .white
        playImageView.contentMode = .center
    }
}

extension ListTileView {
    // TODO
    // 1. with의 의미가 무엇인가
    //
    func configure(with content: ListTileContent) {
        titleLabel.text = content.title

        thumbnailView.kf.setImage(
            with: content.posterUrl,
            options: [
                .cacheMemoryOnly,
                .transition(.fade(0.25))
            ]
        )
    }

    func resetForReuse() {
        thumbnailView.kf.cancelDownloadTask()
        titleLabel.text = nil
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    SearchViewController()
}
#endif
