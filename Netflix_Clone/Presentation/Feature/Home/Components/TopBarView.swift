//
//  TopBarView.swift
//  Netflix_Clone
//
//  Created by mac on 4/2/26.
//

import UIKit
import SnapKit

final class TopBarView: BaseView {
    // 메뉴 버튼
    private let menuButton: UIButton = {
        var config = UIButton.Configuration.plain()
        
        config.preferredSymbolConfigurationForImage = .init(pointSize: 16, weight: .regular)
        config.image = UIImage(systemName: "line.3.horizontal")
        config.baseForegroundColor = .white
        
        let button = UIButton(configuration: config)
        
        return button
    }()
    
    // NETFLIX 텍스트
    private let netflixLabel: UILabel = {
        let label = UILabel()
        
        label.text = "NETFLIX"
        label.textColor = UIColor(red: 229 / 255, green: 9 / 255, blue: 20 / 255, alpha: 1)
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.shadowColor = .blue
        label.shadowOffset = CGSize(width: 2, height: 5)
        
        return label
    }()
    
    // 프로필 이미지
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        
        // 이미지 주입
        imageView.image = UIImage(systemName: "person.crop.circle.fill")
        imageView.tintColor = .white
        
        // 이미지 배치 방식 (Flutter의 BoxFit과 비슷)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 14
        
        // scaleAspectFill 등을 쓸 때나 cornerRadius 줄 때 true로 설정해야함
        imageView.clipsToBounds = true
        
        // 
        imageView.isUserInteractionEnabled = true
        
        return imageView
    }()

    
    // MARK: - Methods
    
    // VIEW
    override func configurationSetView() {
        // 부모인 TopBarView는 자식을 강하게 참고
        // 부모가 메모리에서 사라지지 않는 한 자식도 안전하게 메모리에 붙어있음
        // 순서대로 쌓이는 구조
        addSubview(menuButton)
        addSubview(netflixLabel)
        addSubview(profileImageView)
    }
    
    // LAYOUT
    override func configurationLayout() {
        // snp.makeConstraints{ make in ...}
        // 해당 뷰에 대한 제약조건을 작성하겠다는 선언
        // make: 해당 객체는 레이아웃을 잡으려는 뷰 자신을 가리키는 대리인
        menuButton.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        
        netflixLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        profileImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(28)
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
    
    // UI
    override func configurationUI() {
        backgroundColor = .clear
    }
    
    // 프로필 이미지 클릭시
    private func setUpProfileTapGesture() {
    
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    HomeViewController()
}
#endif
