//
//  Move.swift
//  Four In a Row _ 34
//
//  Created by KhoiLe on 09/08/2021.
//

import UIKit
import GameplayKit

class Move: NSObject, GKGameModelUpdate {
    var value: Int = 0
    var column: Int
    
    init(column: Int) {
        self.column = column
    }
}
