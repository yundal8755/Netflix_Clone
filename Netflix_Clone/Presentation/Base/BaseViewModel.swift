//
//  BaseViewModel.swift
//  Netflix_Clone
//
//  Created by Codex on 4/7/26.
//

import RxSwift

/// ViewModel의 Action / Output 구성을 강제하는 공통 프로토콜
protocol ViewModelType: AnyObject {
    associatedtype Action
    associatedtype Output

    var output: Output { get }
    func send(action: Action)
}

/// 공통 ViewModel 베이스 클래스
/// - Action / Output 타입을 제네릭으로 강제
/// - disposeBag 수명 관리를 공통화
class BaseViewModel<Action, Output>: ViewModelType {
    let output: Output
    let disposeBag = DisposeBag()

    init(output: Output) {
        self.output = output
    }

    func send(action: Action) {
        assertionFailure("send(action:) must be overridden in subclass")
    }
}
