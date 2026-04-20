//
//  CustomBottomSheetViewController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/16/26.
//

import UIKit
import SnapKit

final class CustomBottomSheetViewController: UIViewController {
    private enum Metric {
        static let cornerRadius: CGFloat = 20
        static let topInset: CGFloat = 80
        static let dimAlpha: CGFloat = 0.3
        static let animationDuration: TimeInterval = 0.28
        static let fallbackHeightRatio: CGFloat = 0.6
        static let dismissProgressThreshold: CGFloat = 0.24
        static let dismissVelocityThreshold: CGFloat = 1200
        static let topDragActivationHeight: CGFloat = 96
    }

    private let contentViewController: UIViewController

    private let dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0
        return view
    }()

    private let sheetContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.layer.cornerRadius = Metric.cornerRadius
        view.layer.cornerCurve = .continuous
        return view
    }()

    private var hasAnimatedPresentation = false
    private var hasPreparedInitialState = false
    private var isDismissing = false
    private var sheetHeightConstraint: Constraint?
    private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        gesture.delegate = self
        return gesture
    }()

    init(contentViewController: UIViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureLayout()
        configureChild()
        configureGesture()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animatePresentationIfNeeded()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSheetHeightIfNeeded(animated: hasAnimatedPresentation)
        prepareInitialStateIfNeeded()
    }

    func requestDismissFromContent() {
        dismissBottomSheet()
    }
}

private extension CustomBottomSheetViewController {
    func configureHierarchy() {
        view.backgroundColor = .clear
        view.addSubview(dimmingView)
        view.addSubview(sheetContainerView)
    }

    func configureLayout() {
        dimmingView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        sheetContainerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide).inset(Metric.topInset)
            sheetHeightConstraint = make.height.equalTo(1).constraint
        }
    }

    func configureChild() {
        addChild(contentViewController)
        sheetContainerView.addSubview(contentViewController.view)
        contentViewController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        contentViewController.didMove(toParent: self)
    }

    func configureGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapDimmingView))
        dimmingView.addGestureRecognizer(tapGesture)
        sheetContainerView.addGestureRecognizer(panGestureRecognizer)
    }

    func animatePresentationIfNeeded() {
        guard hasAnimatedPresentation == false else { return }
        hasAnimatedPresentation = true
        updateSheetHeightIfNeeded(animated: false)
        view.layoutIfNeeded()

        if hasPreparedInitialState == false {
            let offset = sheetContainerView.bounds.height + view.safeAreaInsets.bottom
            sheetContainerView.transform = CGAffineTransform(translationX: 0, y: offset)
            dimmingView.alpha = 0
        }

        UIView.animate(
            withDuration: Metric.animationDuration,
            delay: 0,
            options: [.curveEaseOut]
        ) {
            self.dimmingView.alpha = Metric.dimAlpha
            self.sheetContainerView.transform = .identity
        }
    }

    @objc
    func didTapDimmingView() {
        dismissBottomSheet()
    }

    func dismissBottomSheet() {
        guard isDismissing == false else { return }
        isDismissing = true

        let offset = sheetContainerView.bounds.height + view.safeAreaInsets.bottom
        UIView.animate(
            withDuration: Metric.animationDuration,
            delay: 0,
            options: [.curveEaseIn]
        ) {
            self.dimmingView.alpha = 0
            self.sheetContainerView.transform = CGAffineTransform(translationX: 0, y: offset)
        } completion: { _ in
            self.dismiss(animated: false)
        }
    }

    @objc
    func handleSheetPan(_ gesture: UIPanGestureRecognizer) {
        let translationY = gesture.translation(in: view).y
        let velocityY = gesture.velocity(in: view).y
        let sheetTravelDistance = max(sheetContainerView.bounds.height + view.safeAreaInsets.bottom, 1)

        switch gesture.state {
        case .began, .changed:
            let downwardTranslation = max(translationY, 0)
            let upwardTranslation = min(translationY, 0) * 0.18
            let appliedTranslation = downwardTranslation + upwardTranslation

            sheetContainerView.transform = CGAffineTransform(translationX: 0, y: appliedTranslation)

            let progress = min(max(downwardTranslation / sheetTravelDistance, 0), 1)
            dimmingView.alpha = Metric.dimAlpha * (1 - progress)

        case .ended, .cancelled, .failed:
            let downwardProgress = max(translationY, 0) / sheetTravelDistance
            let shouldDismiss = downwardProgress > Metric.dismissProgressThreshold
                || velocityY > Metric.dismissVelocityThreshold

            if shouldDismiss {
                dismissBottomSheet()
                return
            }

            UIView.animate(
                withDuration: 0.32,
                delay: 0,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.3
            ) {
                self.sheetContainerView.transform = .identity
                self.dimmingView.alpha = Metric.dimAlpha
            }

        default:
            break
        }
    }

    func updateSheetHeightIfNeeded(animated: Bool) {
        let maxHeight = view.bounds.height - (view.safeAreaInsets.top + Metric.topInset)
        guard maxHeight > 0 else { return }

        let targetHeight = min(max(resolveContentHeight(), 1), maxHeight)
        sheetHeightConstraint?.update(offset: targetHeight)

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut]) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    func prepareInitialStateIfNeeded() {
        guard hasAnimatedPresentation == false else { return }

        let offset = sheetContainerView.bounds.height + view.safeAreaInsets.bottom
        sheetContainerView.transform = CGAffineTransform(translationX: 0, y: offset)
        dimmingView.alpha = 0
        hasPreparedInitialState = true
    }

    func resolveContentHeight() -> CGFloat {
        if contentViewController.preferredContentSize.height > 0 {
            return contentViewController.preferredContentSize.height
        }

        let fittingTargetSize = CGSize(
            width: view.bounds.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let fittingSize = contentViewController.view.systemLayoutSizeFitting(
            fittingTargetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )

        if fittingSize.height > 0 {
            return fittingSize.height
        }

        return view.bounds.height * Metric.fallbackHeightRatio
    }
}

extension CustomBottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === panGestureRecognizer else { return true }
        guard let panGesture = gestureRecognizer as? UIPanGestureRecognizer else { return true }

        let velocity = panGesture.velocity(in: view)
        guard abs(velocity.y) > abs(velocity.x) else { return false }

        let location = panGesture.location(in: sheetContainerView)
        return location.y <= Metric.topDragActivationHeight
    }
}
