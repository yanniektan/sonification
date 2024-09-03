//
//  PaddedLabel.swift
//  AudioARMindfulness2
//
//  Created by Katherine Chen on 9/3/24.
//

import UIKit

class PaddedLabel: UILabel {
    var textInsets = UIEdgeInsets.zero

    override func drawText(in rect: CGRect) {
        let insetsRect = rect.inset(by: textInsets)
        super.drawText(in: insetsRect)
    }

    override var intrinsicContentSize: CGSize {
        let intrinsicContentSize = super.intrinsicContentSize
        let width = intrinsicContentSize.width + textInsets.left + textInsets.right
        let height = intrinsicContentSize.height + textInsets.top + textInsets.bottom
        return CGSize(width: width, height: height)
    }
}
