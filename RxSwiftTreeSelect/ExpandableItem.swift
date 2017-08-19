//
//  ExpandableItem.swift
//  PDF-Expert-Contents
//
//  Created by DianQK on 17/09/2016.
//  Copyright © 2016 DianQK. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

struct ExpandableItem<Model: IdentifiableType & Equatable> {
    
    let model: Model
    let isExpanded: Variable<Bool>
    let canExpanded: Bool
    
    let displaySubItems: Observable<[ExpandableItem]>
    let subItems: [ExpandableItem]
    
    var displayAllItems: Observable<[ExpandableItem]> {
        return Observable.combineLatest(Observable.just([self]), displaySubItems) { $0 + $1 }
    }
    
    init(model: Model, isExpanded: Bool, subItems: [ExpandableItem]) {
        self.model = model
        self.canExpanded = !subItems.isEmpty
        self.subItems = subItems
        if self.canExpanded {
            self.isExpanded = Variable(isExpanded)
            self.displaySubItems = Observable.combineLatest(self.isExpanded.asObservable(), ExpandableItem.combinSubItems(subItems)) { isExpanded, subItems in isExpanded ? subItems : [] }
        } else {
            self.isExpanded = Variable(false)
            self.displaySubItems = Observable.just([])
        }
    }
    
    static private func combinSubItems(_ items: [ExpandableItem]) -> Observable<[ExpandableItem]> {
        return Observable.combineLatest(items.map { $0.displayAllItems }) { $0.flatMap { $0 } }
    }
    
}

extension ExpandableItem: IdentifiableType, Equatable {

    public static func ==(lhs: ExpandableItem, rhs: ExpandableItem) -> Bool {
        return lhs.model == rhs.model
    }

    var identity: Model.Identity {
        return model.identity
    }

}
