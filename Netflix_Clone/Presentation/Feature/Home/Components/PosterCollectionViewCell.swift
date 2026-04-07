//
//  HorizontalPosterCell.swift
//  Netflix_Clone
//
//  Created by Codex on 4/3/26.
//

import UIKit
import SnapKit
import Alamofire

final class PosterCollectionViewCell: UICollectionViewCell {

    // 레이아웃/디자인 수치를 한 곳에서 관리
    private enum Metric {
        /// 포스터 카드 모서리 둥글기
        static let cornerRadius: CGFloat = 6
        /// 하단 타이틀 오버레이 배경 높이
        static let titleBackgroundHeight: CGFloat = 44
        /// 타이틀 텍스트 내부 여백
        static let titleInset: CGFloat = 8
    }

    // 재사용 가능한 고정 리소스
    private enum Constant {
        /// 네트워크 이미지가 없거나 실패했을 때 사용할 기본 이미지
        static let placeholderImage = UIImage(systemName: "photo")
    }

    /// 이미지 URL 문자열 기준으로 캐싱해서 중복 다운로드를 줄입니다.
    /// static으로 두면 셀 인스턴스가 달라도 동일 캐시를 공유합니다.
    private static let imageCache = NSCache<NSString, UIImage>()

    /// 카드 전체 배경 컨테이너
    private let posterBackgroundView = UIView()
    /// 포스터 이미지 본체
    private let posterImageView = UIImageView()
    /// 하단 반투명 오버레이
    private let titleBackgroundView = UIView()
    /// 영화 제목 라벨
    private let titleLabel = UILabel()

    /// 현재 진행 중인 이미지 요청 (재사용 시 취소하기 위해 참조 유지)
    private var imageRequest: DataRequest?
    /// 셀이 "지금 보여줘야 하는 URL"을 추적하기 위한 값
    /// 비동기 응답이 늦게 도착했을 때, 잘못된 셀에 이미지가 꽂히는 문제를 방지합니다.
    private var currentPosterURL: URL?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 셀이 재사용 풀로 돌아가기 직전 호출됩니다.
    /// 이전 요청/데이터 상태를 정리하지 않으면 "이미지 섞임" 문제가 생길 수 있습니다.
    override func prepareForReuse() {
        super.prepareForReuse()
        // 이전 네트워크 요청 취소
        imageRequest?.cancel()
        imageRequest = nil
        // 현재 URL 추적값 초기화
        currentPosterURL = nil
        // UI를 기본 상태로 리셋
        posterImageView.image = Constant.placeholderImage
        titleLabel.text = nil
    }
    
    /// 코드 기반 생성자
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurationSetView()
        configurationLayout()
        configurationUI()
    }


    // MARK: - Methods

    /// 화면 트리에 서브뷰를 붙이는 단계
    private func configurationSetView() {
        contentView.addSubview(posterBackgroundView)
        posterBackgroundView.addSubview(posterImageView)
        posterBackgroundView.addSubview(titleBackgroundView)
        posterBackgroundView.addSubview(titleLabel)
    }

    /// 오토레이아웃 제약 설정
    /// - 이미지는 카드 전체를 채우고
    /// - 하단 오버레이 + 타이틀은 하단에 겹쳐 배치합니다.
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
    }

    /// 색상/폰트/접근성 등 스타일 구성
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
        
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}


// MARK: - Business Logic

extension PosterCollectionViewCell {
    /// 셀 외부에서 데이터를 주입하는 진입점
    /// 텍스트를 먼저 반영하고, 이미지는 비동기로 로딩합니다.
    func configure(with item: PosterItem) {
        titleLabel.text = item.title
        accessibilityLabel = item.title
        loadPosterImage(from: item.posterURL)
    }

    /// 포스터 이미지를 로딩합니다.
    /// 처리 순서:
    /// 1) 이전 요청 취소
    /// 2) 현재 URL 추적값 저장
    /// 3) 캐시 히트면 즉시 반영
    /// 4) 캐시 미스면 네트워크 요청
    /// 5) 응답 시 현재 URL과 일치하는지 확인 후 반영
    private func loadPosterImage(from url: URL?) {
        // 기존 요청이 남아 있으면 취소 (재사용 셀 안전성)
        imageRequest?.cancel()
        imageRequest = nil

        // 이 셀이 "지금 의도하는 이미지 URL" 기록
        currentPosterURL = url

        // URL 자체가 없으면 placeholder 유지
        guard let url else {
            posterImageView.image = Constant.placeholderImage
            return
        }

        // URL 문자열을 캐시 키로 사용
        let cacheKey = url.absoluteString as NSString

        // 메모리 캐시 히트면 즉시 표시 후 종료
        if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
            posterImageView.image = cachedImage
            return
        }

        // 캐시 미스 시 로딩 전 placeholder
        posterImageView.image = Constant.placeholderImage

        // 네트워크 요청 시작
        imageRequest = AF.request(url)
            .validate(statusCode: 200 ..< 300)
            .responseData(queue: .main) { [weak self] response in
                guard let self else { return }
                // 셀이 재사용되어 다른 URL을 표시 중이면, 늦게 도착한 응답은 폐기
                guard self.currentPosterURL == url else { return }
                self.imageRequest = nil

                switch response.result {
                case .success(let data):
                    // 이미지 디코딩 성공 시 캐시에 저장 후 표시
                    if let image = UIImage(data: data) {
                        Self.imageCache.setObject(image, forKey: cacheKey)
                        self.posterImageView.image = image
                    } else {
                        // 데이터가 이미지로 변환되지 않으면 fallback
                        self.posterImageView.image = Constant.placeholderImage
                    }
                case .failure:
                    // 요청 실패 시 fallback
                    self.posterImageView.image = Constant.placeholderImage
                }
            }
    }
}
