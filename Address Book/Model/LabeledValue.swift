//
//  LabeledValue.swift
//  Address Book
//
//  Created by Fawzi Rifai on 13/06/2022.
//

import Foundation

struct LabeledValue: Identifiable, Equatable, Codable {
    
    var id = UUID()
    var label: String?
    var value = ""
    var defaultLabels = ["Mobile", "Home", "Work"]
    var customLabels = [String]()
    var type: ValueType
    var allLabels: [String] { defaultLabels + customLabels }
    static func ==(lhs: LabeledValue, rhs: LabeledValue) -> Bool {
        lhs.label == rhs.label && lhs.value == rhs.value && lhs.defaultLabels == rhs.defaultLabels && lhs.customLabels == rhs.customLabels
    }
    
    init(label: String? = nil, value: String = "", type: LabeledValue.ValueType) {
        self.value = value
        self.type = type
        if type == .phone {
            self.defaultLabels = ["Mobile", "Home", "Work"]
        } else {
            self.defaultLabels = ["Personal", "Work"]
        }
        if let label = label {
            if !allLabels.contains(label) {
                self.customLabels.append(label)
            }
            self.label = label
        } else {
            self.label = self.defaultLabels[0]
        }
    }
    
    enum ValueType: Codable {
        case phone, email
    }
}
