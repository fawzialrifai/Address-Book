//
//  ContactStore.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import Contacts

@MainActor class ContactStore: ObservableObject {
    
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
    @Published var filterText = ""
    @Published var hiddenFilterText = ""
    @Published var deletedFilterText = ""
    @Published var isInitialsGridPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isImporting = false
    @Published var isExporting = false
    @Published var isNotAuthorized = false
    @AppStorage("Sort Order") var sortOrder = Order.firstNameLastName
    @AppStorage("Order Display") var displayOrder = Order.firstNameLastName
    
    init() {
        fetchMyCard()
        loadEmergencyContactsIdentifiers()
        loadFavoritesIdentifiers()
        loadHiddenContactsIdentifiers()
        requestContactsAccess {
            self.fetchContacts()
            self.sortContacts()
        }
        loadDeletedContacts()
    }
    
}

extension ContactStore {
    
    func filteredContacts(for list: Folder) -> [Contact] {
        if list == .all {
            return contacts.filter {
                !$0.isHidden && (filterText.isEmpty ||
                    ($0.firstName + " " + ($0.lastName ?? "")).lowercased().contains(filterText.lowercased()) ||
                    (($0.lastName ?? "") + " " + ($0.firstName)).lowercased().contains(filterText.lowercased()) ||
                    $0.company?.lowercased().contains(filterText.lowercased()) == true ||
                    $0.notes?.lowercased().contains(filterText.lowercased()) == true ||
                    $0.phoneNumbers.contains(where: { $0.value.lowercased().contains(filterText.lowercased()) }) ||
                    $0.phoneNumbers.contains(where: { $0.value.plainPhoneNumber.lowercased().contains(filterText.plainPhoneNumber.lowercased()) }) ||
                    $0.emailAddresses.contains(where: { $0.value.lowercased().contains(filterText.lowercased()) })
                )
            }
        }
        else if list == .hidden {
            return hiddenContacts.filter {
                hiddenFilterText.isEmpty || (
                    ($0.firstName + " " + ($0.lastName ?? "")).lowercased().contains(hiddenFilterText.lowercased()) ||
                    (($0.lastName ?? "") + " " + ($0.firstName)).lowercased().contains(hiddenFilterText.lowercased()) ||
                    $0.company?.lowercased().contains(hiddenFilterText.lowercased()) == true ||
                    $0.notes?.lowercased().contains(hiddenFilterText.lowercased()) == true ||
                    $0.phoneNumbers.contains(where: { $0.value.lowercased().contains(hiddenFilterText.lowercased()) }) ||
                    $0.phoneNumbers.contains(where: { $0.value.plainPhoneNumber.lowercased().contains(hiddenFilterText.plainPhoneNumber.lowercased()) }) ||
                    $0.emailAddresses.contains(where: { $0.value.lowercased().contains(hiddenFilterText.lowercased()) })
                )
            }
        } else {
            return deletedContacts.filter {
                deletedFilterText.isEmpty || (
                    ($0.firstName + " " + ($0.lastName ?? "")).lowercased().contains(deletedFilterText.lowercased()) ||
                    (($0.lastName ?? "") + " " + ($0.firstName)).lowercased().contains(deletedFilterText.lowercased()) ||
                    $0.company?.lowercased().contains(deletedFilterText.lowercased()) == true ||
                    $0.notes?.lowercased().contains(deletedFilterText.lowercased()) == true ||
                    $0.phoneNumbers.contains(where: { $0.value.lowercased().contains(deletedFilterText.lowercased()) }) ||
                    $0.phoneNumbers.contains(where: { $0.value.plainPhoneNumber.lowercased().contains(deletedFilterText.plainPhoneNumber.lowercased()) }) ||
                    $0.emailAddresses.contains(where: { $0.value.lowercased().contains(deletedFilterText.lowercased()) })
                )
            }
        }
    }
    
    func emergencyContacts(in list: Folder) -> [Contact] {
        filteredContacts(for: list).filter({ $0.isEmergencyContact })
    }
    
    func favorites(in list: Folder) -> [Contact] {
        filteredContacts(for: list).filter({ $0.isFavorite })
    }
    
    var hiddenContacts: [Contact] {
        contacts.filter({ $0.isHidden })
    }
    
    var duplicates: [[Contact]] {
        var arrayOfduplicates = [[Contact]]()
        var scannedContacts = [String]()
        let contacts = self.contacts
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
    
    func contactsDictionary(for list: Folder) -> [String: [Contact]] {
        var keys = [String]()
        var contactsDictionary = [String: [Contact]]()
        for contact in filteredContacts(for: list) {
            if !contact.isMyCard {
                if let firstLetter = contact.firstLetter(sortOrder: sortOrder) {
                    if keys.contains(firstLetter) {
                        contactsDictionary[firstLetter]?.append(contact)
                    } else {
                        contactsDictionary[firstLetter] = [contact]
                        keys.append(firstLetter)
                    }
                }
                
            }
        }
        return contactsDictionary
    }
    
    var duplicatesDictionary: [String: [[Contact]]] {
        var keys = [String]()
        var contactsDictionary = [String: [[Contact]]]()
        for duplicate in duplicates {
            if let firstDuplicate = duplicate.first {
                if !firstDuplicate.isMyCard {
                    if let firstLetter = firstDuplicate.firstLetter(sortOrder: sortOrder) {
                        if keys.contains(firstLetter) {
                            contactsDictionary[firstLetter]?.append(duplicate)
                        } else {
                            contactsDictionary[firstLetter] = [duplicate]
                            keys.append(firstLetter)
                        }
                    }
                }
            }
            
        }
        return contactsDictionary
    }
    
    var hiddenContactsDictionary: [String: [Contact]] {
        var keys = [String]()
        var contactsDictionary = [String: [Contact]]()
        for contact in hiddenContacts {
            if !contact.isMyCard {
                if let firstLetter = contact.firstLetter(sortOrder: sortOrder) {
                    if keys.contains(firstLetter) {
                        contactsDictionary[firstLetter]?.append(contact)
                    } else {
                        contactsDictionary[firstLetter] = [contact]
                        keys.append(firstLetter)
                    }
                }
                
            }
        }
        return contactsDictionary
    }
    
    var deletedContactsDictionary: [String: [Contact]] {
        var keys = [String]()
        var contactsDictionary = [String: [Contact]]()
        for contact in deletedContacts {
            if let firstLetter = contact.firstLetter(sortOrder: sortOrder) {
                if keys.contains(firstLetter) {
                    contactsDictionary[firstLetter]?.append(contact)
                } else {
                    contactsDictionary[firstLetter] = [contact]
                    keys.append(firstLetter)
                }
            }
            
        }
        return contactsDictionary
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
        let contactStore = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            onSuccess()
        } else if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            contactStore.requestAccess(for: .contacts) { success, _ in
                if success {
                    onSuccess()
                } else {
                    DispatchQueue.main.async {
                        self.isNotAuthorized = true
                    }
                }
            }
        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
            self.isNotAuthorized = true
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
        sortContacts()
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
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = true
            favoritesIdentifiers.append(contact.identifier)
        }
    }
    
    func removeFromFavorites(_ contact: Contact) {
        favoritesIdentifiers.removeAll(where: { $0 == contact.identifier })
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = false
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
    
    func moveToDeletedList(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isDeleted = true
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
    
    func restore(_ contact: Contact) {
        if let index = deletedContacts.firstIndex(of: contact) {
            deletedContacts[index].isDeleted = false
            add(deletedContacts[index])
            deletedContacts.remove(at: index)
        }
    }
}
