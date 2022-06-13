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
    var allLabels: [String] { availableLabels + customLabels }
    static func ==(lhs: Email, rhs: Email) -> Bool {
        lhs.label == rhs.label && lhs.value == rhs.value && lhs.availableLabels == rhs.availableLabels && lhs.customLabels == rhs.customLabels
    }
    
    init(id: UUID = UUID(), label: String? = "Personal", value: String = "", availableLabels: [String] = ["Personal", "Work"], customLabels: [String] = [String]()) {
        self.id = id
        self.label = label
        self.value = value
        self.availableLabels = availableLabels
        self.customLabels = customLabels
        if let label = label {
            if !allLabels.contains(label) {
                self.customLabels.append(label)
            }
        }
    }
}
