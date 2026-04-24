//
//  MVIContainer.swift
//  Netflix_Clone
//
//  Created by mac on 4/16/26.
//

import Foundation
import RxSwift
import RxRelay

protocol BaseMVIContainer: AnyObject {
    // protocol 내부에서 사용할 타입의 임시 이름표
    // 제네릭처럼 보이지만 BaseMVIContainer<State, Intent> 형태로 쓰는 문법은 아님
    // 이 프로토콜을 채택하는 객체가 직접 State, Intent 타입을 정해주면 됨
    // ex) final class SearchContainer { struct State {} enum Intent {} }
    associatedtype State
    associatedtype Intent

    // Store가 처음 들고 시작할 상태
    var initialState: State { get }

    // Store에서 Intent를 받으면 Container가 상태 변경과 비동기 작업을 처리함
    func handle(_ intent: Intent, store: Store<Self>)
}

// Container 자체를 BaseContainer<State, Intent>로 만들면
// 사용처 클래스 선언이 final class SearchContainer: BaseContainer<SearchState, SearchIntent> 처럼 바깥 타입을 들고 있게 됨
// 원하는 구조는 final class SearchContainer 내부에 State, Intent를 넣는 형태라서
// 제네릭은 View가 직접 만지지 않는 Store 내부 상태 저장소에만 숨겨둠
final class Store<Container: BaseMVIContainer> {
    typealias State = Container.State
    typealias Intent = Container.Intent

    private let stateRelay: BehaviorRelay<State>
    private let container: Container

    // MARK: State
    // 변수 뒤에 {}가 붙는 문법을 연산 프로퍼티라고 부름
    // 메모리에 값 저장하지 않는 함수
    // Store는 현재 상태와 상태 스트림만 View에 공개함
    var state: State { stateRelay.value }
    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    init(_ container: Container) {
        self.container = container
        self.stateRelay = BehaviorRelay(value: container.initialState)
    }

    // MARK: Intent
    // View에서 호출하는 단일 진입점
    func send(_ intent: Intent) {
        container.handle(intent, store: self)
    }

    // MARK: 상태 변경
    // 현재 상태를 변형하여 새 상태로 교체한다.
    // Feature의 handle 내부에서만 쓰는 것을 의도함
    // inout: 함수 내부에서 값 수정 가능 (타입은 안됨)
    func reduce(_ mutation: (inout State) -> Void) {
        var newState = stateRelay.value
        mutation(&newState)
        stateRelay.accept(newState)
    }
}
