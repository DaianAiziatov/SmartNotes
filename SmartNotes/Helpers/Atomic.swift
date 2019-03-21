//
//  Atomic.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation

final class Atomic<A> {
    private let queue = DispatchQueue(label: "Atomic serial queue")
    private var _value: A
    init(_ value: A) {
        self._value = value
    }

    var value: A {
        get {
            return queue.sync { self._value }
        }
    }

    func mutate(_ transform: (inout A) -> ()) {
        queue.sync {
            transform(&self._value)
        }
    }
}
