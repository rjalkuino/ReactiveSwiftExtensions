//
//  Utils.swift
//  TestProject
//
//  Created by robert john alkuino on 25/09/2019.
//  Copyright © 2019 robert john alkuino. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

class NotificationSignal<T> {
    
    let (signal, sink) = Signal<T, NoError>.pipe()
    
    func notify(value: T) {
        sink.send(value:value)
    }
    
    func dispose() {
        sink.sendInterrupted()
    }
}

