//
//  Phone.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import Foundation

struct Phone: Identifiable, Equatable, ContactLabeledValue {
    var id = UUID()
    var label: String? = "Mobile"
    var value = ""
    var availableLabels = ["Mobile", "Home", "Work"]
    var customLabels = [String]()
    static func ==(lhs: Phone, rhs: Phone) -> Bool {
        lhs.label == rhs.label && lhs.value == rhs.value && lhs.availableLabels == rhs.availableLabels && lhs.customLabels == rhs.customLabels
    }
}
