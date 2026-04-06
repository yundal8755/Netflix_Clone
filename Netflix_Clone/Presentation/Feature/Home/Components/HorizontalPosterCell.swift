//
//  HorizontalPosterCell.swift
//  Netflix_Clone
//
//  Created by Codex on 4/3/26.
//

import UIKit
import SnapKit
import Alamofire

final class HorizontalPosterCell: UICollectionViewCell {
    static let reuseIdentifier = "HorizontalPosterCell"

    private static let imageCache = NSCache<NSString, UIImage>()

    // 포스터 카드 배경 뷰
    private let posterBackgroundView = UIView()
    private let posterImageView = UIImageView()
    private let titleBackgroundView = UIView()

    // 포스터 제목 라벨
    private let titleLabel = UILabel()
    private var imageRequest: DataRequest?
    private var currentPosterURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Methods

    // VIEW
    private func configurationSetView() {
        contentView.addSubview(posterBackgroundView)
        posterBackgroundView.addSubview(posterImageView)
        posterBackgroundView.addSubview(titleBackgroundView)
        posterBackgroundView.addSubview(titleLabel)
    }

    // LAYOUT
    private func configurationLayout() {
        posterBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        posterImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleBackgroundView.snp.makeConstraints { make in
            make.horizontalEdges.bottom.equalToSuperview()
            make.height.equalTo(44)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.bottom.equalToSuperview().inset(8)
        }
    }

    // UI
    private func configurationUI() {
        contentView.backgroundColor = .clear

        posterBackgroundView.layer.cornerRadius = 6
        posterBackgroundView.clipsToBounds = true
        posterBackgroundView.backgroundColor = UIColor(white: 0.12, alpha: 1)

        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.backgroundColor = UIColor(white: 0.18, alpha: 1)
        posterImageView.image = UIImage(systemName: "photo")

        titleBackgroundView.backgroundColor = UIColor(white: 0, alpha: 0.45)

        titleLabel.numberOfLines = 2
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textColor = .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageRequest?.cancel()
        imageRequest = nil
        currentPosterURL = nil
        posterImageView.image = UIImage(systemName: "photo")
    }
    
    
    func configure(with item: PosterItem) {
        titleLabel.text = item.title
        loadPosterImage(from: item.posterURL)
    }

    private func loadPosterImage(from url: URL?) {
        imageRequest?.cancel()
        currentPosterURL = url

        guard let url else {
            posterImageView.image = UIImage(systemName: "photo")
            return
        }

        let cacheKey = url.absoluteString as NSString
        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            posterImageView.image = cachedImage
            return
        }

        posterImageView.image = UIImage(systemName: "photo")

        imageRequest = AF.request(url)
            .validate(statusCode: 200 ..< 300)
            .responseData(queue: .main) { [weak self] response in
                guard let self else { return }
                guard self.currentPosterURL == url else { return }

                switch response.result {
                case .success(let data):
                    if let image = UIImage(data: data) {
                        Self.imageCache.setObject(image, forKey: cacheKey)
                        self.posterImageView.image = image
                    } else {
                        self.posterImageView.image = UIImage(systemName: "photo")
                    }
                case .failure:
                    self.posterImageView.image = UIImage(systemName: "photo")
                }
            }
    }
}
