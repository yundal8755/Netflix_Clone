//
//  LikeView.swift
//  Netflix_Clone
//
//  Created by Codex on 4/8/26.
//

import UIKit
import SnapKit

// Like 화면의 루트 View입니다.
// BaseView를 상속해서 "뷰 추가 -> 레이아웃 -> UI 스타일" 순서로 일관된 초기화 구조를 따릅니다.
final class LikeView: BaseView {

    // 레이아웃 관련 숫자(여백/높이)를 한 곳에서 관리하기 위한 내부 상수 집합입니다.
    private enum Metric {
        // 화면 좌우 기본 여백입니다.
        static let horizontalInset: CGFloat = 20
        // "새로고침" 버튼의 고정 높이입니다.
        static let refreshButtonHeight: CGFloat = 32
    }

    // 화면 상단의 메인 타이틀 라벨입니다.
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "좋아요"
        label.textColor = .white
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()

    // 타이틀 하단의 보조 텍스트 라벨입니다.
    // ViewController에서 저장 개수(예: "찜한 콘텐츠 3개")를 동적으로 바꿔야 하므로 internal(let)로 노출합니다.
    let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "찜한 콘텐츠"
        label.textColor = UIColor(white: 1, alpha: 0.78)
        label.font = .systemFont(ofSize: 15, weight: .regular)
        return label
    }()

    // 좋아요 화면의 핵심 콘텐츠를 보여줄 컬렉션뷰입니다.
    // 실제 레이아웃은 ViewController에서 Compositional Layout로 주입합니다.
    let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    )


    // MARK: - Methods

    // "어떤 뷰를 화면 트리에 올릴지" 정의하는 단계입니다.
    override func configurationSetView() {
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(collectionView)
    }

    // "각 뷰를 어디에 배치할지" 정의하는 Auto Layout 단계입니다.
    override func configurationLayout() {
        // 타이틀 라벨 제약입니다.
        titleLabel.snp.makeConstraints { make in
            // 안전 영역 상단에서 10pt 아래에 배치합니다.
            make.top.equalTo(safeAreaLayoutGuide).inset(10)
            // 좌측은 화면 기준 20pt 여백을 둡니다.
            make.leading.equalToSuperview().inset(Metric.horizontalInset)
        }

        // 서브 타이틀 라벨 제약입니다.
        subtitleLabel.snp.makeConstraints { make in
            // 메인 타이틀 아래 4pt 간격으로 배치합니다.
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            // 좌측 시작점을 titleLabel과 맞춰 정렬감을 만듭니다.
            make.leading.equalTo(titleLabel)
        }

        // 컬렉션뷰 제약입니다.
        collectionView.snp.makeConstraints { make in
            // 서브 타이틀 아래 14pt 간격을 둡니다.
            make.top.equalTo(subtitleLabel.snp.bottom).offset(14)
            // 좌/우/하단을 부모에 붙여 남은 영역을 모두 콘텐츠 영역으로 사용합니다.
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }

    // "색상/스크롤 속성/기본 시각 스타일"을 설정하는 단계입니다.
    override func configurationUI() {
        // Like 화면의 기본 배경을 검정으로 설정해 포스터가 강조되도록 합니다.
        backgroundColor = .black

        // 컬렉션뷰 배경은 투명으로 둬 루트 배경색을 그대로 사용합니다.
        collectionView.backgroundColor = .clear
        // 드래그 시 키보드를 내리는 정책을 설정합니다.
        // 현재 텍스트 입력은 없지만, 확장 시 일관된 UX를 위해 미리 설정해 둡니다.
        collectionView.keyboardDismissMode = .onDrag
        // 세로 스크롤이 콘텐츠보다 작아도 바운스를 허용해 iOS 기본 감각을 유지합니다.
        collectionView.alwaysBounceVertical = true
        // 세로 스크롤 인디케이터를 숨겨 시각적 군더더기를 줄입니다.
        collectionView.showsVerticalScrollIndicator = false
    }
}
