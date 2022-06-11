//
//  JSONFile.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import SwiftUI
import UniformTypeIdentifiers

struct JSONFile: FileDocument {
    static var readableContentTypes = [UTType.json]
    var data = Data()
    
    init(initialData: Data = Data()) {
        data = initialData
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = data
        return FileWrapper(regularFileWithContents: data)
    }
}
