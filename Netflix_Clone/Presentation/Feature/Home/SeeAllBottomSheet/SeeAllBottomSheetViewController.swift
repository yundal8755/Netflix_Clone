//
//  SeeAllBottomSheetViewController.swift
//  Netflix_Clone
//
//  Created by Codex on 4/15/26.
//

import UIKit

final class SeeAllBottomSheetViewController: BaseViewController<SeeAllBottomSheetView> {
    private let sectionTitle: String
    private let items: [PosterItem]

    init(sectionTitle: String, items: [PosterItem]) {
        self.sectionTitle = sectionTitle
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        mainView.delegate = self
        mainView.update(sectionTitle: sectionTitle, items: items)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let preferredHeight = mainView.preferredHeight(for: view.bounds.width)
        if preferredHeight > 0 {
            preferredContentSize = CGSize(width: view.bounds.width, height: preferredHeight)
        }
    }
}

extension SeeAllBottomSheetViewController: SeeAllBottomSheetViewDelegate {
    func seeAllBottomSheetViewDidTapClose(_ view: SeeAllBottomSheetView) {
        if let customBottomSheet = parent as? CustomBottomSheetViewController {
            customBottomSheet.requestDismissFromContent()
            return
        }
        dismiss(animated: true)
    }

    func seeAllBottomSheetView(_ view: SeeAllBottomSheetView, didSelect item: PosterItem) {
        // Item selection behavior can be extended later (detail push, preview, etc.)
    }
}
