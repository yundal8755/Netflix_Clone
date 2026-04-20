//
//  MVIContainer.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import Foundation
import RxSwift
import RxRelay

/// MVI Container.
/// - `State`  : View 에 렌더링될 불변 상태
/// - `Intent` : View 에서 발생한 사용자 의도 (Enum)
/// - `Effect` : 일회성 사이드 이펙트 (네비게이션, 토스트 등)
protocol BaseMVIContainer: AnyObject {
    associatedtype State
    associatedtype Intent

    var state: State { get }
    var stateObservable: Observable<State> { get }

    func send(_ intent: Intent)
}

/// 공통 구현을 제공하는 베이스 Container.
/// 각 화면은 이 클래스를 상속하여 `reduce(state:intent:)` 만 구현하면 된다.
class BaseContainer<State, Intent>: BaseMVIContainer {

    // MARK: - State

    private let stateRelay: BehaviorRelay<State>
    
    var state: State { stateRelay.value }
    
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    // MARK: - Init

    init(initialState: State) {
        self.stateRelay = BehaviorRelay(value: initialState)
    }

    // MARK: - Intent 처리

    /// View 에서 호출하는 단일 진입점.
    func send(_ intent: Intent) {
        handle(intent)
    }

    /// 서브클래스에서 오버라이드하여 Intent 를 처리한다.
    /// 기본 구현은 아무것도 하지 않음.
    func handle(_ intent: Intent) {
        fatalError("Subclass must override handle(_:)")
    }

    // MARK: - 상태/이펙트 방출 헬퍼

    /// 현재 상태를 변형하여 새 상태로 교체한다.
    func reduce(_ mutation: (inout State) -> Void) {
        var newState = stateRelay.value
        mutation(&newState)
        stateRelay.accept(newState)
    }
}

