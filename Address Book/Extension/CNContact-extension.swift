//
//  CNContact-extension.swift
//  Address Book
//
//  Created by Fawzi Rifai on 16/06/2022.
//

import Contacts

extension CNContact {
    var modernized: Contact {
        var contact = Contact()
        contact.identifier = identifier
        contact.firstName = givenName
        contact.lastName = familyName.isTotallyEmpty ? nil : familyName
        contact.company = organizationName.isTotallyEmpty ? nil : organizationName
        for phoneNumber in phoneNumbers {
            contact.phoneNumbers.append(LabeledValue(label: CNLabeledValue<CNPhoneNumber>.localizedString(forLabel: phoneNumber.label ?? ""), value: phoneNumber.value.stringValue, type: .phone))
        }
        for emailAddress in emailAddresses {
            contact.emailAddresses.append(LabeledValue(label: CNLabeledValue<NSString>.localizedString(forLabel: emailAddress.label ?? ""), value: emailAddress.value as String, type: .email))
        }
        contact.birthday = birthday?.date
        contact.imageData = imageData
        return contact
    }
}
