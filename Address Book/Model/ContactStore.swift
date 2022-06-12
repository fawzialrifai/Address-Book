//
//  ContactStore.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import Contacts

@MainActor class ContactStore: ObservableObject {
    
    @Published var contacts: [Contact] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(contacts)
                try encodedData.write(to: contactsPath, options: .atomic)
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
    
    @Published var emergencyContactsIdentifiers: [String] = [] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(emergencyContactsIdentifiers)
                try encodedData.write(to: emergencyContactsPath, options: .atomic)
            } catch {}
        }
    }
    
    init() {
        do {
            let encodedFavorites = try Data(contentsOf: favoritesPath)
            favoritesIdentifiers = try JSONDecoder().decode([String].self, from: encodedFavorites)
        } catch {}
        do {
            let encodedEmergencyContacts = try Data(contentsOf: emergencyContactsPath)
            emergencyContactsIdentifiers = try JSONDecoder().decode([String].self, from: encodedEmergencyContacts)
        } catch {}
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts) { success, error in
            if success {
                let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
                let request = CNContactFetchRequest(keysToFetch: keys)
                try? contactStore.enumerateContacts(with: request) {
                    (cnContact, _) in
                    var contact = Contact()
                    if self.favoritesIdentifiers.contains(cnContact.identifier) {
                        if self.emergencyContactsIdentifiers.contains(cnContact.identifier) {
                            contact.update(from: cnContact, isEmergencyContact: true, isFavorite: true)
                        } else {
                            contact.update(from: cnContact, isEmergencyContact: false, isFavorite: true)
                        }
                    } else {
                        if self.emergencyContactsIdentifiers.contains(cnContact.identifier) {
                            contact.update(from: cnContact, isEmergencyContact: true, isFavorite: false)
                        } else {
                            contact.update(from: cnContact, isEmergencyContact: false, isFavorite: false)
                        }
                    }
                    DispatchQueue.main.async {
                        self.contacts.append(contact)
                    }
                }
                DispatchQueue.main.async {
                    self.sortContacts()
                }
            } else {
                DispatchQueue.main.async {
                    self.isNotAuthorized = true
                }
            }
        }
    }
    
    private var contactsPath = FileManager.documentDirectory.appendingPathComponent("Contacts")
    private var favoritesPath = FileManager.documentDirectory.appendingPathComponent("Favorites")
    private var emergencyContactsPath = FileManager.documentDirectory.appendingPathComponent("emergencyContacts")
    @Published var filterText = ""
    @Published var isFirstLettersGridPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isMerging = false
    @Published var isImporting = false
    @Published var isExporting = false
    @Published var isNotAuthorized = false
    @AppStorage("Sort Order") var sortOrder = Order.firstNameLastName
    @AppStorage("Order Display") var displayOrder = Order.firstNameLastName
    
}

extension ContactStore {
    
    var filteredContacts: [Contact] {
        contacts.filter {
            filterText.isEmpty || (
                ($0.firstName + " " + ($0.lastName ?? "")).lowercased().contains(filterText.lowercased()) ||
                (($0.lastName ?? "") + " " + ($0.firstName)).lowercased().contains(filterText.lowercased()) ||
                $0.company?.lowercased().contains(filterText.lowercased()) == true ||
                $0.notes?.lowercased().contains(filterText.lowercased()) == true
            )
        }
    }
    
    var emergencyContacts: [Contact] {
        filteredContacts.filter({ $0.isEmergencyContact })
    }
    
    var favorites: [Contact] {
        filteredContacts.filter({ $0.isFavorite })
    }
    
    var contactsDictionary: [String: [Contact]] {
        var keys = [String]()
        var contactsDictionary = [String: [Contact]]()
        for contact in filteredContacts {
            if !contact.isMyCard {
                if keys.contains(contact.firstLetter(sortOrder: sortOrder)) {
                    contactsDictionary[contact.firstLetter(sortOrder: sortOrder)]?.append(contact)
                } else {
                    contactsDictionary[contact.firstLetter(sortOrder: sortOrder)] = [contact]
                    keys.append(contact.firstLetter(sortOrder: sortOrder))
                }
            }
        }
        return contactsDictionary
    }
    
    var status: String {
        if isMerging {
            return "Merging duplicates..."
        } else if isImporting {
            return "Importing..."
        } else if isExporting {
            return "Exporting..."
        } else {
            return "\(contacts.filter({ !$0.isMyCard }).count) contacts"
        }
    }
    
}

extension ContactStore {
    
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
    
    func delete(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts.remove(at: index)
        }
        let store = CNContactStore()
        if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: []) {
            let saveRequest = CNSaveRequest()
            saveRequest.delete(cnContact.mutableCopy() as! CNMutableContact)
            try? store.execute(saveRequest)
        }
    }
    
}
