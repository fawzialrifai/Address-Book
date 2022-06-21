//
//  ContactStore.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import Contacts

@MainActor class ContactStore: ObservableObject {
    
    static var shared = ContactStore()
    
    @Published var contacts: [Contact] = []
    
    @Published var emergencyContactsIdentifiers: [String] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(emergencyContactsIdentifiers)
                try encodedData.write(to: emergencyContactsPath, options: .atomic)
            } catch {}
        }
    }
    
    @Published var favoritesIdentifiers: [String] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(favoritesIdentifiers)
                try encodedData.write(to: favoritesPath, options: .atomic)
            } catch {}
        }
    }
    
    @Published var hiddenContactsIdentifiers: [String] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(hiddenContactsIdentifiers)
                try encodedData.write(to: hiddenContactsPath, options: .atomic)
            } catch {}
        }
    }
    
    @Published var deletedContacts: [Contact] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(deletedContacts)
                try encodedData.write(to: deletedContactsPath, options: .atomic)
            } catch {}
        }
    }
    
    private var myCardPath = FileManager.documentDirectory.appendingPathComponent("My Card")
    private var emergencyContactsPath = FileManager.documentDirectory.appendingPathComponent("Emergency Contacts")
    private var favoritesPath = FileManager.documentDirectory.appendingPathComponent("Favorites")
    private var hiddenContactsPath = FileManager.documentDirectory.appendingPathComponent("Hidden Contacts")
    private var deletedContactsPath = FileManager.documentDirectory.appendingPathComponent("Deleted Contacts")
    @Published var isImporting = false
    @Published var isExporting = false
    @Published var isAuthorized = false
    @AppStorage("Sort Order") var sortOrder = Order.firstNameLastName
    @AppStorage("Order Display") var displayOrder = Order.firstNameLastName
    
    private init() {
        fetchMyCard()
        loadEmergencyContactsIdentifiers()
        loadFavoritesIdentifiers()
        loadHiddenContactsIdentifiers()
        requestContactsAccess {
            self.fetchContacts()
        }
        loadDeletedContacts()
    }
    
    
    
}

extension ContactStore {
    
    var hiddenContacts: [Contact] {
        contacts.filter({ $0.isHidden })
    }
    
    var unhiddenContacts: [Contact] {
        contacts.filter({ !$0.isHidden })
    }
    
    var duplicates: [[Contact]] {
        var arrayOfduplicates = [[Contact]]()
        var scannedContacts = [String]()
        let contacts = self.unhiddenContacts
        if self.contacts.isEmpty {
            return []
        }
        for firstIndex in (0 ..< contacts.count - 1) {
            if !scannedContacts.contains(contacts[firstIndex].fullName(displayOrder: displayOrder)) {
                scannedContacts.append(contacts[firstIndex].fullName(displayOrder: displayOrder))
                var duplicates = [contacts[firstIndex]]
                for secondIndex in (firstIndex + 1 ..< contacts.count) {
                    if contacts[firstIndex].fullName(displayOrder: displayOrder) == contacts[secondIndex].fullName(displayOrder: displayOrder) {
                        duplicates.append(contacts[secondIndex])
                    }
                }
                if duplicates.count > 1 {
                    arrayOfduplicates.append(duplicates)
                } else {
                    duplicates.removeAll()
                }
            }
        }
        return arrayOfduplicates
    }
    
    var status: String {
        if isImporting {
            return "Importing..."
        } else if isExporting {
            return "Exporting..."
        } else {
            return "\(contacts.filter({ !$0.isMyCard }).count) contacts"
        }
    }
    
}

extension ContactStore {
    
    func fetchMyCard() {
        do {
            let encodedMyCard = try Data(contentsOf: myCardPath)
            let myCard = try JSONDecoder().decode(Contact.self, from: encodedMyCard)
            contacts.append(myCard)
        } catch {}
    }
    
    func loadEmergencyContactsIdentifiers() {
        do {
            let encodedFavorites = try Data(contentsOf: favoritesPath)
            favoritesIdentifiers = try JSONDecoder().decode([String].self, from: encodedFavorites)
        } catch {}
    }
    
    func loadFavoritesIdentifiers() {
        do {
            let encodedEmergencyContacts = try Data(contentsOf: emergencyContactsPath)
            emergencyContactsIdentifiers = try JSONDecoder().decode([String].self, from: encodedEmergencyContacts)
        } catch {}
    }
    
    func loadHiddenContactsIdentifiers() {
        do {
            let encodedHiddenContactsIdentifiers = try Data(contentsOf: hiddenContactsPath)
            hiddenContactsIdentifiers = try JSONDecoder().decode([String].self, from: encodedHiddenContactsIdentifiers)
        } catch {}
    }
    
    func requestContactsAccess(onSuccess: @escaping () -> Void) {
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            isAuthorized = true
            onSuccess()
        } else {
            isAuthorized = false
        }
    }
    
    func fetchContacts() {
        let contactStore = CNContactStore()
        let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        try? contactStore.enumerateContacts(with: request) {
            (cnContact, _) in
            var contact = cnContact.modernized
            contact.isEmergencyContact = self.emergencyContactsIdentifiers.contains(cnContact.identifier)
            contact.isFavorite = self.favoritesIdentifiers.contains(cnContact.identifier)
            contact.isHidden = self.hiddenContactsIdentifiers.contains(cnContact.identifier)
            DispatchQueue.main.async {
                self.contacts.append(contact)
            }
        }
        DispatchQueue.main.async {
            self.sortContacts()
        }
    }
    
    func loadDeletedContacts() {
        do {
            let encodedContacts = try Data(contentsOf: deletedContactsPath)
            deletedContacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
        } catch {}
    }
    
}

extension ContactStore {
    
    func indexFor(_ newContact: Contact) -> Int {
        if sortOrder == .firstNameLastName {
            if let index = contacts.firstIndex(where: {$0.firstName > newContact.firstName}) {
                return index
            } else {
                return contacts.count
            }
        } else {
            if let index = contacts.firstIndex(where: {$0.lastName ?? $0.firstName > newContact.lastName ?? newContact.firstName}) {
                return index
            } else {
                return contacts.count
            }
        }
    }
    
    func sortContacts() {
        if sortOrder == .firstNameLastName {
            contacts.sort {
                $0.fullName(displayOrder: .firstNameLastName).lowercased() < $1.fullName(displayOrder: .firstNameLastName).lowercased()
            }
        } else {
            contacts.sort {
                $0.fullName(displayOrder: .lastNameFirstName).lowercased() < $1.fullName(displayOrder: .lastNameFirstName).lowercased()
            }
        }
    }
    
    func add(_ contact: Contact) {
        var contact = contact
        contact.phoneNumbers = contact.phoneNumbers.filter({ !$0.value.isTotallyEmpty })
        contact.emailAddresses = contact.emailAddresses.filter({ !$0.value.isTotallyEmpty })
        if contact.isMyCard {
            contacts.insert(contact, at: indexFor(contact))
            if let encodedMyCard = try? JSONEncoder().encode(contact) {
                try? encodedMyCard.write(to: myCardPath, options: .atomic)
            }
        } else {
            let cnContact = CNMutableContact()
            
            contact.identifier = cnContact.identifier
            contacts.insert(contact, at: indexFor(contact))
            if contact.isEmergencyContact {
                addToEmergencyContacts(contact)
            }
            if contact.isFavorite {
                addToFavorites(contact)
            }
            if contact.isHidden {
                hideContact(contact)
            }
            cnContact.givenName = contact.firstName
            cnContact.familyName = contact.lastName ?? ""
            cnContact.organizationName = contact.company ?? ""
            for phoneNumber in contact.phoneNumbers.filter({ !$0.value.isTotallyEmpty }) {
                cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
            }
            for emailAddress in contact.emailAddresses.filter({ !$0.value.isTotallyEmpty }) {
                cnContact.emailAddresses.append(CNLabeledValue(label: emailAddress.label, value: emailAddress.value as NSString))
            }
            if let birthday = contact.birthday {
                cnContact.birthday = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
            }
            cnContact.imageData = contact.imageData
            let store = CNContactStore()
            let saveRequest = CNSaveRequest()
            saveRequest.add(cnContact, toContainerWithIdentifier: nil)
            try? store.execute(saveRequest)
        }
    }
    
    func update(_ contact: Contact, with newData: Contact) {
        if contact.isDeleted {
            if let index = deletedContacts.firstIndex(of: contact) {
                deletedContacts[index].firstName = newData.firstName
                deletedContacts[index].lastName = newData.lastName
                deletedContacts[index].company = newData.company
                deletedContacts[index].phoneNumbers = newData.phoneNumbers.filter({ !$0.value.isTotallyEmpty })
                deletedContacts[index].emailAddresses = newData.emailAddresses.filter({ !$0.value.isTotallyEmpty })
                deletedContacts[index].latitude = newData.latitude
                deletedContacts[index].longitude = newData.longitude
                deletedContacts[index].birthday = newData.birthday
                deletedContacts[index].notes = newData.notes
                deletedContacts[index].imageData = newData.imageData
            }
        } else {
            if let index = contacts.firstIndex(of: contact) {
                contacts[index].firstName = newData.firstName
                contacts[index].lastName = newData.lastName
                contacts[index].company = newData.company
                contacts[index].phoneNumbers = newData.phoneNumbers.filter({ !$0.value.isTotallyEmpty })
                contacts[index].emailAddresses = newData.emailAddresses.filter({ !$0.value.isTotallyEmpty })
                contacts[index].latitude = newData.latitude
                contacts[index].longitude = newData.longitude
                contacts[index].birthday = newData.birthday
                contacts[index].notes = newData.notes
                contacts[index].imageData = newData.imageData
            }
            if contact.isMyCard {
                if let encodedMyCard = try? JSONEncoder().encode(newData) {
                    try? encodedMyCard.write(to: myCardPath, options: .atomic)
                }
            } else {
                let store = CNContactStore()
                let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
                if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact {
                    cnContact.givenName = newData.firstName
                    cnContact.familyName = newData.lastName ?? ""
                    cnContact.organizationName = newData.company ?? ""
                    cnContact.phoneNumbers.removeAll()
                    for phoneNumber in newData.phoneNumbers.filter({ !$0.value.isTotallyEmpty }) {
                        cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
                    }
                    cnContact.emailAddresses.removeAll()
                    for emailAddress in newData.emailAddresses.filter({ !$0.value.isTotallyEmpty }) {
                        cnContact.emailAddresses.append(CNLabeledValue(label: emailAddress.label, value: emailAddress.value as NSString))
                    }
                    if let birthday = newData.birthday {
                        cnContact.birthday = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
                    }
                    cnContact.imageData = newData.imageData
                    let saveRequest = CNSaveRequest()
                    saveRequest.update(cnContact)
                    try? store.execute(saveRequest)
                }
            }
        }
    }
    
    func addToEmergencyContacts(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isEmergencyContact = true
            emergencyContactsIdentifiers.append(contact.identifier)
        }
    }
    
    func removeFromEmergencyContacts(_ contact: Contact) {
        emergencyContactsIdentifiers.removeAll(where: { $0 == contact.identifier })
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isEmergencyContact = false
        }
    }
    
    func addToFavorites(_ contact: Contact) {
        if contact.isDeleted {
            if let index = deletedContacts.firstIndex(of: contact) {
                deletedContacts[index].isFavorite = true
                favoritesIdentifiers.append(contact.identifier)
            }
        } else {
            if let index = contacts.firstIndex(of: contact) {
                contacts[index].isFavorite = true
                favoritesIdentifiers.append(contact.identifier)
            }
        }
    }
    
    func removeFromFavorites(_ contact: Contact) {
        if contact.isDeleted {
            favoritesIdentifiers.removeAll(where: { $0 == contact.identifier })
            if let index = deletedContacts.firstIndex(of: contact) {
                deletedContacts[index].isFavorite = false
            }
        } else {
            favoritesIdentifiers.removeAll(where: { $0 == contact.identifier })
            if let index = contacts.firstIndex(of: contact) {
                contacts[index].isFavorite = false
            }
        }
    }
    
    func mergedContact(from cards: [Contact]) -> Contact {
        var contact = Contact()
        for card in cards {
            contact.firstName = card.firstName
            contact.lastName = card.lastName
            if let company = card.company, contact.company == nil {
                contact.company = company
            }
            for phoneNumber in card.phoneNumbers {
                if !contact.phoneNumbers.contains(phoneNumber) {
                    contact.phoneNumbers.append(phoneNumber)
                }
            }
            for emailAdress in card.emailAddresses {
                if !contact.emailAddresses.contains(emailAdress) {
                    contact.emailAddresses.append(emailAdress)
                }
            }
            if let birthday = card.birthday, contact.birthday == nil {
                contact.birthday = birthday
            }
            if let imageData = card.imageData, contact.imageData == nil {
                contact.imageData = imageData
            }
            if cards.contains(where: {
                $0.isFavorite
            }) {
                contact.isFavorite = true
            }
            if cards.contains(where: {
                $0.isEmergencyContact
            }) {
                contact.isEmergencyContact = true
            }
            if cards.contains(where: {
                $0.isMyCard
            }) {
                contact.isMyCard = true
            }
        }
        return contact
    }
    
    func mergeAllDuplicates() {
        for contactCards in duplicates {
            add(mergedContact(from: contactCards))
            moveToDeletedList(contactCards)
        }
    }
    
    func hideContact(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isHidden = true
            hiddenContactsIdentifiers.append(contact.identifier)
        }
    }
    
    func unhideContact(_ contact: Contact) {
        hiddenContactsIdentifiers.removeAll(where: { $0 == contact.identifier })
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isHidden = false
        }
    }
    
    func moveToDeletedList(_ contacts: [Contact]) {
        for contact in contacts {
            moveToDeletedList(contact)
        }
    }
    
    func permanentlyDelete(_ contacts: [Contact]) {
        for contact in contacts {
            permanentlyDelete(contact)
        }
    }
    
    func moveToDeletedList(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isDeleted = true
            contacts[index].isMyCard = false
            deletedContacts.append(contacts[index])
            contacts.remove(at: index)
            removeFromEmergencyContacts(contact)
            removeFromFavorites(contact)
            unhideContact(contact)
        }
        if contact.isMyCard {
            try? FileManager.default.removeItem(at: myCardPath)
        } else {
            let store = CNContactStore()
            if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: []).mutableCopy() as? CNMutableContact {
                let saveRequest = CNSaveRequest()
                saveRequest.delete(cnContact)
                try? store.execute(saveRequest)
            }
        }
    }
    
    func permanentlyDelete(_ contact: Contact) {
        if let index = deletedContacts.firstIndex(of: contact) {
            deletedContacts.remove(at: index)
            if contact.isEmergencyContact {
                removeFromEmergencyContacts(contact)
            }
        }
    }
    
    func emptyRecentlyDeletedFolder() {
        for contact in deletedContacts {
            permanentlyDelete(contact)
        }
    }
    
    func restore(_ contact: Contact) {
        if let index = deletedContacts.firstIndex(of: contact) {
            deletedContacts[index].isDeleted = false
            add(deletedContacts[index])
            deletedContacts.remove(at: index)
        }
    }
    
    func restoreAllDeletedContacts() {
        for contact in deletedContacts {
            restore(contact)
        }
    }
}
