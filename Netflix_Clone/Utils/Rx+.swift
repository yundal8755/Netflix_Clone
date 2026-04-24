//
//  Rx+.swift
//  Netflix_Clone
//
//  Created by mac on 4/7/26.
//

import UIKit
import RxSwift
import RxCocoa

// UIViewController일 때에만 .rx.메소드가 가능하도록 구현
public extension Reactive where Base: UIViewController {
    
  var viewDidLoad: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewDidLoad)).map { _ in }
    return ControlEvent(events: source)
  }

  var viewWillAppear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewWillAppear)).map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }
  var viewDidAppear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewDidAppear)).map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  var viewWillDisappear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewWillDisappear)).map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }
  var viewDidDisappear: ControlEvent<Bool> {
    let source = self.methodInvoked(#selector(Base.viewDidDisappear)).map { $0.first as? Bool ?? false }
    return ControlEvent(events: source)
  }

  var viewWillLayoutSubviews: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewWillLayoutSubviews)).map { _ in }
    return ControlEvent(events: source)
  }
  var viewDidLayoutSubviews: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.viewDidLayoutSubviews)).map { _ in }
    return ControlEvent(events: source)
  }

  var willMoveToParentViewController: ControlEvent<UIViewController?> {
    let source = self.methodInvoked(#selector(Base.willMove)).map { $0.first as? UIViewController }
    return ControlEvent(events: source)
  }
  var didMoveToParentViewController: ControlEvent<UIViewController?> {
    let source = self.methodInvoked(#selector(Base.didMove)).map { $0.first as? UIViewController }
    return ControlEvent(events: source)
  }

  var didReceiveMemoryWarning: ControlEvent<Void> {
    let source = self.methodInvoked(#selector(Base.didReceiveMemoryWarning)).map { _ in }
    return ControlEvent(events: source)
  }

  /// Rx observable, triggered when the ViewController appearance state changes (true if the View is being displayed, false otherwise)
  var isVisible: Observable<Bool> {
      let viewDidAppearObservable = self.base.rx.viewDidAppear.map { _ in true }
      let viewWillDisappearObservable = self.base.rx.viewWillDisappear.map { _ in false }
      return Observable<Bool>.merge(viewDidAppearObservable, viewWillDisappearObservable)
  }

  /// Rx observable, triggered when the ViewController is being dismissed
  var isDismissing: ControlEvent<Bool> {
      let source = self.sentMessage(#selector(Base.dismiss)).map { $0.first as? Bool ?? false }
      return ControlEvent(events: source)
  }
}

// MARK: Swift Concurrency + Reactor Kit

extension Observable {
    
    typealias SendType = Send<Element>
    typealias OperationType = @Sendable (_ send: SendType) async throws -> Void
    
    static func run(
        priority: TaskPriority? = nil,
        operation: @escaping OperationType
    ) -> Observable<Element> {
        
        Observable.create { observer in
            let task = Task(priority: priority) {
                do {
                    try await operation(
                        Send { value in
                            observer.onNext(value)
                        }
                    )
                    observer.onCompleted()
                } catch is CancellationError {
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }

            return Disposables.create { task.cancel() }
        }
    }
}

@MainActor
struct Send<Element>: Sendable {
    
    typealias SendType = @MainActor @Sendable (Element) -> Void
    
    private let send: SendType

    init(_ send: @escaping SendType) {
        self.send = send
    }

    func callAsFunction(_ value: Element) {
        guard !Task.isCancelled else { return }
        send(value)
    }
}
