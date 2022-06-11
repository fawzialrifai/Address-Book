//
//  ContactStore.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import Contacts

@MainActor class ContactStore: ObservableObject {
    
    @Published var contacts: [Contact] {
        didSet {
            do {
                let encodedData = try JSONEncoder().encode(contacts)
                try encodedData.write(to: contactsPath, options: .atomic)
            } catch {}
        }
    }
    
    init() {
        do {
            //print(contactsPath)
            let encodedContacts = try Data(contentsOf: contactsPath)
            contacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
            sortContacts()
        } catch {
            do {
                let encodedContacts = try Data(contentsOf: Bundle.main.url(forResource: "Contacts", withExtension: "json")!)
                contacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
            } catch {
                contacts = []
            }
        }
    }
    
    private var contactsPath = FileManager.documentDirectory.appendingPathComponent("Contacts")
    @Published var filterText = ""
    @Published var isFirstLettersGridPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isMerging = false
    @Published var isImporting = false
    @Published var isExporting = false
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
                $0.firstName < $1.firstName
            }
        } else {
            contacts.sort {
                $0.lastName ?? $0.firstName < $1.lastName ?? $1.firstName
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
        }
    }
    
    func removeFromEmergencyContacts(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isEmergencyContact = false
        }
    }
    
    func addToFavorites(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = true
        }
    }
    
    func removeFromFavorites(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts[index].isFavorite = false
        }
    }
    
    func delete(_ contact: Contact) {
        if let index = contacts.firstIndex(of: contact) {
            contacts.remove(at: index)
        }
    }
    
}
