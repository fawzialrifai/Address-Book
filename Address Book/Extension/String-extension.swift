//
//  String-extension.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

extension String {
    /// A Boolean value indicates whether a string has no characters after removing white spaces and newlines from both ends of it.
    var isTotallyEmpty: Bool {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    var optional: String? {
        self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
    var plainPhoneNumber: String {
        self.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
    }
    init?(_ c: Character?) {
        if let c = c {
            self = String(c)
        } else {
            return nil
        }
    }
}
