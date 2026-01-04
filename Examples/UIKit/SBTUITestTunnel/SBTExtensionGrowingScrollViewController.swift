//
//  SBTExtensionGrowingScrollViewController.swift
//  SBTUITestTunnel_Example
//

// Reproduces a lazy-loading scroll view where:
//   - the target element is already part of the view hierarchy (so the server
//     finds it as a subview on the first pass), and
//   - the scroll view's contentSize starts smaller than the target's Y
//     position, and grows in response to scrolling.
//
// This is exactly the scenario where the server's first computed offset gets
// clamped to the current maxContentOffset. Without the growth-retry fix, the
// scroll stops short and the target never reaches the visible area.

import UIKit

final class SBTExtensionGrowingScrollViewController: UIViewController, UIScrollViewDelegate {
    private let scrollView = UIScrollView()

    private let rowHeight: CGFloat = 80
    private let totalRows = 100
    private let initialVisibleRows = 30
    private let rowsPerGrowth = 15

    private var currentMaxRow = 30

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        scrollView.accessibilityIdentifier = "growingScrollView"
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        view.addSubview(scrollView)

        // All rows are added to the hierarchy up front, so findSubviewWithIdentifier:
        // will match the target on the first pass. The scroll view's contentSize,
        // however, initially covers only the first `initialVisibleRows` rows — so
        // the target's frame lies outside the scrollable area until it grows.
        for index in 0 ..< totalRows {
            let label = UILabel()
            label.text = "\(index)"
            label.accessibilityIdentifier = "\(index)"
            label.textAlignment = .center
            label.backgroundColor = (index % 2 == 0) ? .systemGray5 : .systemGray4
            label.isUserInteractionEnabled = true
            scrollView.addSubview(label)
        }

        currentMaxRow = initialVisibleRows
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutRows()
        updateContentSize()
    }

    private func layoutRows() {
        let width = scrollView.bounds.width
        for (index, label) in scrollView.subviews.enumerated() {
            label.frame = CGRect(x: 0, y: CGFloat(index) * rowHeight, width: width, height: rowHeight)
        }
    }

    private func updateContentSize() {
        scrollView.contentSize = CGSize(
            width: scrollView.bounds.width,
            height: CGFloat(currentMaxRow) * rowHeight
        )
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard currentMaxRow < totalRows else { return }

        let distanceFromBottom = scrollView.contentSize.height - scrollView.bounds.height - scrollView.contentOffset.y
        if distanceFromBottom <= rowHeight {
            currentMaxRow = min(totalRows, currentMaxRow + rowsPerGrowth)
            updateContentSize()
        }
    }
}
