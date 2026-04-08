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
        // UILabel 인스턴스를 생성합니다.
        let label = UILabel()
        // 타이틀 텍스트를 설정합니다.
        label.text = "좋아요"
        // 어두운 배경 위 가독성을 위해 흰색 텍스트를 사용합니다.
        label.textColor = .white
        // 화면 헤더임을 강조하기 위해 큰 Bold 폰트를 사용합니다.
        label.font = .systemFont(ofSize: 30, weight: .bold)
        // 구성한 라벨을 반환합니다.
        return label
    }()

    // 타이틀 하단의 보조 텍스트 라벨입니다.
    // ViewController에서 저장 개수(예: "찜한 콘텐츠 3개")를 동적으로 바꿔야 하므로 internal(let)로 노출합니다.
    let subtitleLabel: UILabel = {
        // UILabel 인스턴스를 생성합니다.
        let label = UILabel()
        // 초기 표시 문구를 설정합니다.
        label.text = "찜한 콘텐츠"
        // 메인 타이틀보다 강조도를 낮추기 위해 반투명 흰색을 사용합니다.
        label.textColor = UIColor(white: 1, alpha: 0.78)
        // 본문 성격의 Regular 폰트를 사용합니다.
        label.font = .systemFont(ofSize: 15, weight: .regular)
        // 구성한 라벨을 반환합니다.
        return label
    }()

    // 사용자가 수동으로 목록을 다시 읽고 싶을 때 누르는 버튼입니다.
    // ViewController에서 Rx 바인딩으로 탭 이벤트를 구독해야 하므로 internal(let)로 노출합니다.
    let refreshButton: UIButton = {
        // 시스템 타입 버튼을 생성합니다.
        let button = UIButton(type: .system)
        // 기본 상태 텍스트를 설정합니다.
        button.setTitle("새로고침", for: .normal)
        // 텍스트 색을 흰색으로 설정해 어두운 배경에서 대비를 확보합니다.
        button.setTitleColor(.white, for: .normal)
        // 버튼 타이틀 폰트를 약간 굵게 설정해 탭 가능성을 높입니다.
        button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        // 완전 불투명 대신 반투명 배경을 사용해 레이어 위계를 부드럽게 만듭니다.
        button.backgroundColor = UIColor(white: 1, alpha: 0.12)
        // 코너 곡선 방식을 continuous로 설정해 더 부드러운 모서리를 만듭니다.
        button.layer.cornerCurve = .continuous
        // 높이의 절반을 반지름으로 설정해 pill 형태를 만듭니다.
        button.layer.cornerRadius = Metric.refreshButtonHeight / 2
        // 구성한 버튼을 반환합니다.
        return button
    }()

    // 좋아요 화면의 핵심 콘텐츠를 보여줄 컬렉션뷰입니다.
    // 실제 레이아웃은 ViewController에서 Compositional Layout로 주입합니다.
    let collectionView = UICollectionView(
        // 생성 시점에는 프레임을 .zero로 두고 Auto Layout으로 크기를 결정합니다.
        frame: .zero,
        // 생성 시 임시 레이아웃을 넣고, viewDidLoad에서 실제 레이아웃으로 교체합니다.
        collectionViewLayout: UICollectionViewLayout()
    )


    // MARK: - Methods

    // "어떤 뷰를 화면 트리에 올릴지" 정의하는 단계입니다.
    override func configurationSetView() {
        // 상단 메인 타이틀을 루트에 추가합니다.
        addSubview(titleLabel)
        // 서브 타이틀을 루트에 추가합니다.
        addSubview(subtitleLabel)
        // 새로고침 버튼을 루트에 추가합니다.
        addSubview(refreshButton)
        // 컬렉션뷰를 루트에 추가합니다.
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

        // 새로고침 버튼 제약입니다.
        refreshButton.snp.makeConstraints { make in
            // 우측은 화면 기준 20pt 여백을 둡니다.
            make.trailing.equalToSuperview().inset(Metric.horizontalInset)
            // 세로 위치를 titleLabel과 맞춰 한 줄 헤더처럼 보이게 합니다.
            make.centerY.equalTo(titleLabel)
            // 버튼 높이를 고정합니다.
            make.height.equalTo(Metric.refreshButtonHeight)
            // 버튼 너비를 고정해 레이아웃 흔들림을 줄입니다.
            make.width.equalTo(88)
        }

        // 서브 타이틀 라벨 제약입니다.
        subtitleLabel.snp.makeConstraints { make in
            // 메인 타이틀 아래 4pt 간격으로 배치합니다.
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            // 좌측 시작점을 titleLabel과 맞춰 정렬감을 만듭니다.
            make.leading.equalTo(titleLabel)
            // 우측은 refreshButton과 겹치지 않도록 lessThanOrEqual 제약을 사용합니다.
            make.trailing.lessThanOrEqualTo(refreshButton.snp.leading).offset(-8)
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
