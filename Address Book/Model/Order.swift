//
//  Order.swift
//  Address Book
//
//  Created by Fawzi Rifai on 19/05/2022.
//

import SwiftUI

enum Order: String, Identifiable, CaseIterable {
    case firstNameLastName = "First name, Last name"
    case lastNameFirstName = "Last name, First name"
    var id: Self { self }
    var localizedString: LocalizedStringKey { LocalizedStringKey(self.rawValue) }
}
