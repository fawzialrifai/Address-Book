//
//  ContactStore.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import Contacts
import LocalAuthentication

@MainActor class ContactStore: ObservableObject {
    
    @Published var contacts: [Contact] = []
    
    @Published var deletedContacts: [Contact] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(deletedContacts)
                try encodedData.write(to: deletedContactsPath, options: .atomic)
            } catch {}
        }
    }
    
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
    
    private var deletedContactsPath = FileManager.documentDirectory.appendingPathComponent("Deleted Contacts")
    private var myCardPath = FileManager.documentDirectory.appendingPathComponent("My Card")
    private var favoritesPath = FileManager.documentDirectory.appendingPathComponent("Favorites")
    private var hiddenContactsPath = FileManager.documentDirectory.appendingPathComponent("Hidden Contacts")
    private var emergencyContactsPath = FileManager.documentDirectory.appendingPathComponent("Emergency Contacts")
    @Published var filterText = ""
    @Published var isFirstLettersGridPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isMerging = false
    @Published var isImporting = false
    @Published var isExporting = false
    @Published var isNotAuthorized = false
    @Published var isHiddenFolderLocked = true
    @AppStorage("Sort Order") var sortOrder = Order.firstNameLastName
    @AppStorage("Order Display") var displayOrder = Order.firstNameLastName
    
    init() {
        fetchMyCard()
        loadEmergencyContactsIdentifiers()
        loadFavoritesIdentifiers()
        loadHiddenContactsIdentifiers()
        fetchContacts()
        loadDeletedContacts()
    }
    
}

extension ContactStore {
    
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
    
    var filteredContacts: [Contact] {
        contacts.filter {
            !$0.isHidden && filterText.isEmpty || (
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
    
    var hiddenContacts: [Contact] {
        contacts.filter({ $0.isHidden })
    }
    
    var emergencyContacts: [Contact] {
        filteredContacts.filter({ $0.isEmergencyContact })
    }
    
    var favorites: [Contact] {
        filteredContacts.filter({ $0.isFavorite })
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
    
    var contactsDictionary: [String: [Contact]] {
        var keys = [String]()
        var contactsDictionary = [String: [Contact]]()
        for contact in filteredContacts {
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
    
    func loadDeletedContacts() {
        do {
            let encodedContacts = try Data(contentsOf: deletedContactsPath)
            deletedContacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
        } catch {}
    }
    
    func loadEmergencyContactsIdentifiers() {
        do {
            let encodedFavorites = try Data(contentsOf: favoritesPath)
            favoritesIdentifiers = try JSONDecoder().decode([String].self, from: encodedFavorites)
        } catch {}
    }
    
    func loadHiddenContactsIdentifiers() {
        do {
            let encodedHiddenContactsIdentifiers = try Data(contentsOf: hiddenContactsPath)
            hiddenContactsIdentifiers = try JSONDecoder().decode([String].self, from: encodedHiddenContactsIdentifiers)
        } catch {}
    }
    
    func loadFavoritesIdentifiers() {
        do {
            let encodedEmergencyContacts = try Data(contentsOf: emergencyContactsPath)
            emergencyContactsIdentifiers = try JSONDecoder().decode([String].self, from: encodedEmergencyContacts)
        } catch {}
    }
    
    func update(_ contact: Contact, with newData: Contact) {
        var contact = contact
        contact.phoneNumbers = contact.phoneNumbers.dropLast().filter({ !$0.value.isTotallyEmpty })
        contact.emailAddresses = contact.emailAddresses.dropLast().filter({ !$0.value.isTotallyEmpty })
        var newData = newData
        newData.phoneNumbers = newData.phoneNumbers.dropLast().filter({ !$0.value.isTotallyEmpty })
        newData.emailAddresses = newData.emailAddresses.dropLast().filter({ !$0.value.isTotallyEmpty })
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].firstName = newData.firstName
            contacts[index].lastName = newData.lastName
            contacts[index].company = newData.company
            contacts[index].phoneNumbers = newData.phoneNumbers
            contacts[index].emailAddresses = newData.emailAddresses
            contacts[index].latitude = newData.latitude
            contacts[index].longitude = newData.longitude
            contacts[index].birthday = newData.birthday
            contacts[index].notes = newData.notes
            contacts[index].imageData = newData.imageData
        }
        if contact.isMyCard {
            saveMyCard(newData)
        } else {
            let store = CNContactStore()
            let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
            if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact {
                cnContact.givenName = newData.firstName
                cnContact.familyName = newData.lastName ?? ""
                cnContact.organizationName = newData.company ?? ""
                cnContact.phoneNumbers.removeAll()
                for phoneNumber in newData.phoneNumbers {
                    cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
                }
                cnContact.emailAddresses.removeAll()
                for emailAddress in newData.emailAddresses {
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
    
    func add(_ contact: Contact) {
        var contact = contact
        contact.phoneNumbers = contact.phoneNumbers.dropLast().filter({ !$0.value.isTotallyEmpty })
        contact.emailAddresses = contact.emailAddresses.dropLast().filter({ !$0.value.isTotallyEmpty })
        if contact.isMyCard {
            contacts.insert(contact, at: indexFor(contact))
            saveMyCard(contact)
        } else {
            var newContact = contact
            let cnContact = CNMutableContact()
            newContact.identifier = cnContact.identifier
            contacts.insert(newContact, at: indexFor(newContact))
            cnContact.givenName = contact.firstName
            cnContact.familyName = contact.lastName ?? ""
            cnContact.organizationName = contact.company ?? ""
            for phoneNumber in contact.phoneNumbers {
                cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
            }
            for emailAddress in contact.emailAddresses {
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
    
    func reload() {
        contacts.removeAll()
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
    
    func fetchContacts() {
        let contactStore = CNContactStore()
        if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            reload()
            sortContacts()
        } else if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            contactStore.requestAccess(for: .contacts) { success, error in
                if success {
                    self.reload()
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
    
    func saveMyCard(_ contact: Contact) {
        if let encodedMyCard = try? JSONEncoder().encode(contact) {
            try? encodedMyCard.write(to: myCardPath, options: .atomic)
        }
    }
    
    func fetchMyCard() {
        do {
            let encodedMyCard = try Data(contentsOf: myCardPath)
            let myCard = try JSONDecoder().decode(Contact.self, from: encodedMyCard)
            contacts.append(myCard)
        } catch {}
    }
    
    func deleteMyCard() {
        try? FileManager.default.removeItem(at: myCardPath)
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
    
    func addToEmergencyContacts(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isEmergencyContact = true
            emergencyContactsIdentifiers.append(contact.identifier)
        }
    }
    
    func removeFromEmergencyContacts(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isEmergencyContact = false
            emergencyContactsIdentifiers.removeAll(where: { $0 == contact.identifier })
        }
    }
    
    func addToFavorites(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = true
            favoritesIdentifiers.append(contact.identifier)
        }
    }
    
    func removeFromFavorites(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = false
            favoritesIdentifiers.removeAll(where: { $0 == contact.identifier })
        }
    }
    
    func hideContact(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isHidden = true
            hiddenContactsIdentifiers.append(contact.identifier)
        }
    }
    
    func unhideContact(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isHidden = false
            hiddenContactsIdentifiers.removeAll(where: { $0 == contact.identifier })
        }
    }
    
    func moveToDeletedList(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isDeleted = true
            deletedContacts.append(contacts[index])
            contacts.remove(at: index)
        }
        let store = CNContactStore()
        if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: []).mutableCopy() as? CNMutableContact {
            let saveRequest = CNSaveRequest()
            saveRequest.delete(cnContact)
            try? store.execute(saveRequest)
        }
    }
    
    func permanentlyDelete(_ contact: Contact) {
        if let index = deletedContacts.firstIndex(of: contact) {
            deletedContacts.remove(at: index)
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
