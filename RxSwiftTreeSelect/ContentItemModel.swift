//
//  ContentItemModel.swift
//  PDF-Expert-Contents
//
//  Created by DianQK on 24/09/2016.
//  Copyright © 2016 DianQK. All rights reserved.
//

import Foundation
import RxSwift
import RxDataSources
import SwiftyJSON

typealias ExpandableContentItemModel = ExpandableItem<ContentItemModel>

struct ContentItemModel: IdentifiableType, Equatable {

    let id: Int64
    let title: String
    let level: Int
    let url: URL?
    let isSelected = Variable((isSelected: false, isSelectedAll: false))
    
    private let disposeBag = DisposeBag()

    init(title: String, level: Int, id: Int64, url: URL?) {
        self.title = title
        self.level = level
        self.id = id
        self.url = url
    }

    var identity: Int64 {
        return id
    }

    static func createExpandableContentItemModel(json: JSON, withPreLevel preLevel: Int) -> ExpandableContentItemModel {
        let title = json["title"].stringValue
        let id = json["id"].int64Value
        let url = URL(string: json["url"].stringValue)

        let level = preLevel + 1

        let subItems: [ExpandableContentItemModel]

        if let subJSON = json["subdirectory"].array, !subJSON.isEmpty {
            subItems = subJSON.map { createExpandableContentItemModel(json: $0, withPreLevel: level) }
        } else {
            subItems = []
        }
        let contentItemModel = ContentItemModel(title: title, level: level, id: id, url: url)
        Observable.combineLatest(subItems.map { $0.model.isSelected.asObservable() })
            .map { (isSelected: $0.first(where: { $0.isSelected }) != nil, isSelectedAll: $0.first(where: { !$0.isSelectedAll }) == nil) }
            .bind(to: contentItemModel.isSelected)
            .disposed(by: contentItemModel.disposeBag)

        let expandableItem = ExpandableItem(model: contentItemModel, isExpanded: false, subItems: subItems)
        return expandableItem
    }
    
    static func ==(lfs: ContentItemModel, rfs: ContentItemModel) -> Bool {
        return lfs.id == rfs.id && lfs.title == rfs.title && lfs.level == rfs.level && lfs.url == rfs.url
    }
}


