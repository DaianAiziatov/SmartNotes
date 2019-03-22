//
//  Result.swift
//  SmartNotes
//
//  Created by Daian Aiziatov on 21/03/2019.
//  Copyright © 2019 Daian Aiziatov. All rights reserved.
//

import Foundation

enum Result<T, U: Error> {
    case success(T)
    case failure(U)
}
