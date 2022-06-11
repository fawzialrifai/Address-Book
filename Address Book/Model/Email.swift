//
//  Email.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import Foundation

struct Email: Identifiable, Equatable, ContactLabeledValue {
    var id = UUID()
    var label: String? = "Personal"
    var value = ""
    var availableLabels = ["Personal", "Work"]
    var customLabels = [String]()
    static func ==(lhs: Email, rhs: Email) -> Bool {
        lhs.label == rhs.label && lhs.value == rhs.value && lhs.availableLabels == rhs.availableLabels && lhs.customLabels == rhs.customLabels
    }
}
