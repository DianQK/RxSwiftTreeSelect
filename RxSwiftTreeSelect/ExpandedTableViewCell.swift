//
//  ExpandedTableViewCell.swift
//  PDF-Expert-Contents
//
//  Created by DianQK on 17/09/2016.
//  Copyright © 2016 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ExpandedTableViewCell: UITableViewCell {

    @IBOutlet private weak var expandMarkImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet weak var selectButton: UIButton!

    var attributedText: NSAttributedString? {
        get {
            return titleLabel?.attributedText
        }
        set(attributedText) {
            titleLabel.attributedText = attributedText
        }
    }

    var level: Int = 0 {
        didSet {
            let left = CGFloat(level * 15) + 15 + 15 + 10
            separatorInset = UIEdgeInsets(top: 0, left: left, bottom: 0, right: 0)
        }
    }

    var isExpanded: Bool = false {
        didSet {
            guard canExpanded, isExpanded != oldValue else { return }
            var from = CATransform3DIdentity
            var to = CATransform3DRotate(from, CGFloat.pi / 2, 0, 0, 1)

            if !isExpanded {
                (from, to) = (to, from)
            }

            expandMarkImageView.layer.transform = to
            let affineTransformAnimation = CABasicAnimation(keyPath: "transform")
            affineTransformAnimation.fromValue = NSValue(caTransform3D: from)
            affineTransformAnimation.toValue = NSValue(caTransform3D: to)
            affineTransformAnimation.duration = 0.3
            expandMarkImageView.layer.add(affineTransformAnimation, forKey: nil)
        }
    }

    var canExpanded: Bool = false {
        didSet {
            expandMarkImageView.isHidden = !canExpanded
        }
    }
    
    var prepareForReuseBag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        prepareForReuseBag = DisposeBag()
    }

}

extension Reactive where Base: ExpandedTableViewCell {
    var isExpanded: Binder<Bool> {
        return Binder(self.base as ExpandedTableViewCell, binding: { (cell, isExpanded) in
            if cell.isExpanded != isExpanded {
                cell.isExpanded = isExpanded
            }
        })
    }
}
