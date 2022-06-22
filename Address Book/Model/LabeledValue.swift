//
//  LabeledValue.swift
//  Address Book
//
//  Created by Fawzi Rifai on 13/06/2022.
//

import Foundation

struct LabeledValue: Identifiable, Equatable, Codable {
    
    var id = UUID()
    var label: String
    var value = ""
    var defaultLabels = ["Mobile", "Home", "Work"]
    var customLabel: String
    var type: ValueType
    
    init(label: String, value: String = "", type: LabeledValue.ValueType) {
        self.label = label
        self.value = value
        self.type = type
        if type == .phone {
            self.defaultLabels = ["Mobile", "Home", "Work"]
        } else {
            self.defaultLabels = ["Personal", "Work"]
        }
        if !defaultLabels.contains(label) {
            self.customLabel = label
        } else {
            self.customLabel = ""
        }
    }
    
    enum ValueType: Codable {
        case phone, email
    }
}
