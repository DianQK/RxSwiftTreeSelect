//
//  ViewController.swift
//  PDF-Expert-Contents
//
//  Created by DianQK on 17/09/2016.
//  Copyright © 2016 DianQK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SwiftyJSON
import SafariServices

private typealias ContentsSectionModel = AnimatableSectionModel<String, ExpandableContentItemModel>

class ViewController: UIViewController, UITableViewDelegate {

    @IBOutlet private weak var contentsTableView: UITableView!
    
    let disposeBag = DisposeBag()

    private let dataSource = RxTableViewSectionedAnimatedDataSource<ContentsSectionModel>(configureCell: { dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.expandedCell, for: indexPath)!

        let headIndent = CGFloat(item.model.level * 15)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = headIndent
        paragraphStyle.headIndent = headIndent
        let font = item.canExpanded ? UIFont.boldSystemFont(ofSize: 17) : UIFont.systemFont(ofSize: 17)
        let attributeString = NSAttributedString(string: item.model.title, attributes: [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: font
            ])

        cell.attributedText = attributeString
        cell.canExpanded = item.canExpanded
        cell.level = item.model.level
        if item.canExpanded {
            item.isExpanded.asObservable()
                .bind(to: cell.rx.isExpanded)
                .disposed(by: cell.prepareForReuseBag)
        }
        item.model.isSelected.asObservable()
            .subscribe(onNext: { (isSelected, isSelectedAll) in
                cell.selectButton.isSelected = isSelected
                cell.selectButton.setImage(isSelectedAll ? R.image.icon_star_active() : R.image.icon_star_active_part(), for: .selected)
            })
            .disposed(by: cell.prepareForReuseBag)
        func updateAllSelectState(subItems: [ExpandableContentItemModel], isSelectedAll: Bool) {
            for subItem in subItems where subItem.model.isSelected.value.isSelectedAll != isSelectedAll {
                subItem.model.isSelected.value = (isSelected: isSelectedAll, isSelectedAll: isSelectedAll)
                updateAllSelectState(subItems: subItem.subItems, isSelectedAll: isSelectedAll)
            }
        }
        cell.selectButton.rx.tap.asObservable()
            .subscribe(onNext: {
                item.model.isSelected.value = (isSelected: !item.model.isSelected.value.isSelectedAll, isSelectedAll: !item.model.isSelected.value.isSelectedAll)
                updateAllSelectState(subItems: item.subItems, isSelectedAll: item.model.isSelected.value.isSelectedAll)
            })
            .disposed(by: cell.prepareForReuseBag)
        return cell
        })

    override func viewDidLoad() {
        super.viewDidLoad()

        let fetch = Observable
            .just(R.file.contentsJson, scheduler: SerialDispatchQueueScheduler(qos: .background))

        let expandableItems: Observable<[ExpandableContentItemModel]> = fetch
            .map { try Data(resource: $0) }
            .map { try JSON(data: $0) }
            .map { json -> [ExpandableContentItemModel] in
                json.arrayValue.map {
                    ContentItemModel.createExpandableContentItemModel(json: $0, withPreLevel: -1)
                }
            }

        expandableItems
            .map { (items: [ExpandableContentItemModel]) in
                items.map { item in
                    item.displayAllItems
                }
            }
            .flatMap { (items: [Observable<[ExpandableContentItemModel]>]) -> Observable<[ExpandableContentItemModel]> in
                guard let first = items.first else { return Observable.empty() }
                return items.dropFirst().reduce(first) { acc, x in
                    Observable.combineLatest(acc, x, resultSelector: +)
                }
            }
            .map { [ContentsSectionModel(model: "", items: $0)] }
            .observeOn(MainScheduler.instance)
            .bind(to: contentsTableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)

        do {
            contentsTableView.rx.setDelegate(self).disposed(by: disposeBag)
        }

        do {
            dataSource.animationConfiguration = RxDataSources.AnimationConfiguration(
                insertAnimation: .fade,
                reloadAnimation: .fade,
                deleteAnimation: .fade
            )
        }

        do {
            contentsTableView.rx.modelSelected(ExpandableContentItemModel.self)
                .subscribe(onNext: { [unowned self] item in
                    if item.canExpanded {
                        item.isExpanded.value = !item.isExpanded.value
                    } else if let url = item.model.url {
                        let sf = SFSafariViewController(url: url)
                        sf.preferredControlTintColor = UIColor.black
                        self.present(sf, animated: true, completion: nil)
                    }
                })
                .disposed(by: disposeBag)

            contentsTableView.rx.itemSelected.map { (at: $0, animated: true) }
                .subscribe(onNext: contentsTableView.deselectRow)
                .disposed(by: disposeBag)
        }

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource[indexPath]
        let headIndent = CGFloat(item.model.level * 15)
        let font = item.canExpanded ? UIFont.boldSystemFont(ofSize: 17) : UIFont.systemFont(ofSize: 17)
        let attributeString = NSAttributedString(string: item.model.title, attributes: [
            NSAttributedString.Key.font: font
            ])
        let textWidth = tableView.bounds.width - 80 - headIndent
        let textSize = attributeString.boundingRect(with: CGSize(width: textWidth, height: .greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        return textSize.height + 20
    }

}
