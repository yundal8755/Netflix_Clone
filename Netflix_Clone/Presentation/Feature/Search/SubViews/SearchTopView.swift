//
//  SearchTopView.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Then

enum SearchTopViewAction: Equatable {
    case textChanged(String)
    case backButtonTapped
}

final class SearchTopView: BaseView {
    
    let viewAction = BehaviorRelay<SearchTopViewAction>(value: .textChanged(""))
    private let disposBag = DisposeBag()
    
    private enum Metric {
        static let iconFrameWidth: Int = 36
        static let iconWidth: Int = 24
    }
    
    private let backBtn = UIButton(type: .system).then {
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        $0.setImage(image, for: .normal)
        $0.tintColor = .white
    }
    
    private let textfield = UITextField().then {
        $0.backgroundColor = UIColor(white: 1, alpha: 0.15)
        $0.layer.cornerRadius = 12
        $0.textColor = .white
        $0.tintColor = .white
        $0.clearButtonMode = .whileEditing
        $0.returnKeyType = .search
        $0.attributedPlaceholder = NSAttributedString(
            string: "시리즈, 영화, 게임을 검색해 보세요...",
            attributes: [.foregroundColor: UIColor(white: 1, alpha: 0.75)]
        )

        // MARK: leftview
        let leftViewContainer = UIView(
            frame: CGRect(
                x: 0,
                y: 0,
                width: Metric.iconFrameWidth + 4,
                height: Metric.iconFrameWidth
            )
        )
        let iconView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iconView.tintColor = UIColor(white: 1, alpha: 0.75)
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(
            x: 12,
            y: 0,
            width: Metric.iconWidth,
            height: Metric.iconWidth
        )
        iconView.center.y = leftViewContainer.bounds.midY
        leftViewContainer.addSubview(iconView)

        $0.leftView = leftViewContainer
        $0.leftViewMode = .always
    }
    
    // MARK: - Base
    
    override func configurationSetView() {
        addSubview(backBtn)
        addSubview(textfield)
    }
    
    override func configurationLayout() {
        backBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(8)
        }
        
        backBtn.setContentHuggingPriority(.required, for: .horizontal)
        
        textfield.snp.makeConstraints { make in
            make.centerY.equalTo(backBtn)
            make.leading.equalTo(backBtn.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(4)
        }
    }
    
    override func configurationUI() {
        textfield.backgroundColor = .gray.withAlphaComponent(0.3)
        subscribe()
    }
}

// MARK: - Logic

extension SearchTopView {
    
    private func subscribe() {
        textfield.rx.text
            .compactMap { $0 }
            .bind(with: self) { owner, text in
                owner.viewAction.accept(.textChanged(text))
            }
            .disposed(by: disposBag)
        
        backBtn.rx.tap
            .bind(with: self) { owner, _ in
                owner.viewAction.accept(.backButtonTapped)
            }
            .disposed(by: disposBag)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview {
    SearchViewController()
}
#endif
