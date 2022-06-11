//
//  FileManager-extension.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import Foundation

extension FileManager {
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
