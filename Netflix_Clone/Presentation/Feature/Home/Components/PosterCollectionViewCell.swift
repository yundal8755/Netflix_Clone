//
//  HorizontalPosterCell.swift
//  Netflix_Clone
//
//  Created by Codex on 4/3/26.
//

import UIKit
import SnapKit
import Alamofire
import Kingfisher

final class PosterCollectionViewCell: UICollectionViewCell {
    private enum Metric {
        static let cornerRadius: CGFloat = 6
        static let titleBackgroundHeight: CGFloat = 44
        static let titleInset: CGFloat = 8
        static let heartButtonSize: CGFloat = 28
        static let heartInset: CGFloat = 6
    }

    // 재사용 가능한 고정 리소스
    private enum Constant {
        static let placeholderImage = UIImage(systemName: "photo")
    }

    private static let imageCache = NSCache<NSString, UIImage>()
    private let posterBackgroundView = UIView()
    private let posterImageView = UIImageView()
    private let titleBackgroundView = UIView()
    private let titleLabel = UILabel()
    private let heartButton = UIButton(type: .system)
    private var imageRequest: DataRequest?
    private var currentPosterURL: URL?
    private var isLiked = false

    var onTapHeartButton: (() -> Void)?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()

        currentPosterURL = nil
        isLiked = false
        onTapHeartButton = nil

        posterImageView.image = Constant.placeholderImage
        titleLabel.text = nil
        applyHeartStyle(isLiked: false)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
    }


    // MARK: - Methods

    private func configurationSetView() {
        contentView.addSubview(posterBackgroundView)
        posterBackgroundView.addSubview(posterImageView)
        posterBackgroundView.addSubview(titleBackgroundView)
        posterBackgroundView.addSubview(titleLabel)
        posterBackgroundView.addSubview(heartButton)
    }

    private func configurationLayout() {
        posterBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        posterImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleBackgroundView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(Metric.titleBackgroundHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Metric.titleInset)
            make.bottom.equalToSuperview().inset(Metric.titleInset)
        }

        heartButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(Metric.heartInset)
            make.size.equalTo(Metric.heartButtonSize)
        }
    }

    private func configurationUI() {
        contentView.backgroundColor = .clear

        posterBackgroundView.layer.cornerRadius = Metric.cornerRadius
        posterBackgroundView.clipsToBounds = true
        posterBackgroundView.backgroundColor = UIColor(white: 0.12, alpha: 1)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.backgroundColor = UIColor(white: 0.18, alpha: 1)
        posterImageView.image = Constant.placeholderImage

        titleBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.45)

        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white

        heartButton.backgroundColor = UIColor(white: 0, alpha: 0.35)
        heartButton.layer.cornerCurve = .continuous
        heartButton.layer.cornerRadius = Metric.heartButtonSize / 2
        heartButton.tintColor = .white
        heartButton.addTarget(self, action: #selector(didTapHeartButton), for: .touchUpInside)
        heartButton.accessibilityIdentifier = "home.poster.heart.button"
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}


// MARK: - Logic

extension PosterCollectionViewCell {

    func configure(
        with item: PosterItem,
        isLiked: Bool = false,
        showsHeartButton: Bool = true
    ) {
        titleLabel.text = item.title
        accessibilityLabel = item.title
        self.isLiked = isLiked
        heartButton.isHidden = showsHeartButton == false
        applyHeartStyle(isLiked: isLiked)
        loadPosterImage(from: item.posterURL)
    }

    private func loadPosterImage(from url: URL?) {
        self.posterImageView.kf
            .setImage(
                with: url,
                options: [
                    .cacheMemoryOnly, // Ram
                    .transition(.fade(0.5))
                ]
            ) { result in
                switch result {
                case .success(_):
                    print("HAPPY")
                case let .failure(error):
                    print("UnHAPPY \(error.errorCode)")
                }
            }
    }

    func applyHeartStyle(isLiked: Bool) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let symbolName = isLiked ? "heart.fill" : "heart"
        heartButton.setImage(
            UIImage(systemName: symbolName, withConfiguration: symbolConfig),
            for: .normal
        )
        heartButton.tintColor = isLiked
            ? UIColor(red: 229 / 255, green: 9 / 255, blue: 20 / 255, alpha: 1)
            : .white
    }

    func updateLikedState(_ isLiked: Bool) {
        self.isLiked = isLiked
        applyHeartStyle(isLiked: isLiked)
    }

    @objc func didTapHeartButton() {
        onTapHeartButton?()
    }
}
