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
    var allLabels: [String] { availableLabels + customLabels }
    static func ==(lhs: Phone, rhs: Phone) -> Bool {
        lhs.label == rhs.label && lhs.value == rhs.value && lhs.availableLabels == rhs.availableLabels && lhs.customLabels == rhs.customLabels
    }
    
    init(id: UUID = UUID(), label: String? = "Mobile", value: String = "", availableLabels: [String] = ["Mobile", "Home", "Work"], customLabels: [String] = [String]()) {
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
