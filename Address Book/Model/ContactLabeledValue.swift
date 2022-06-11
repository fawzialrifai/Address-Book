//
//  ContactLabeledValue.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import Foundation

protocol ContactLabeledValue: Codable {
    var asParameter: ContactLabeledValue { get set }
    var id: UUID { get set }
    var label: String? { get set }
    var availableLabels: [String] { get set }
    var customLabels: [String] { get set }
    var value: String { get set }
}

extension ContactLabeledValue {
    var asParameter: ContactLabeledValue {
        get { self as ContactLabeledValue }
        set { self = newValue as! Self }
    }
}
