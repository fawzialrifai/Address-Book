//
//  ContactListViewModel.swift
//  Address Book
//
//  Created by Fawzi Rifai on 19/06/2022.
//

import SwiftUI
import LocalAuthentication

@MainActor class ContactListViewModel: ObservableObject {
    var contactStore = ContactStore.shared
    var folder: Folder
    @Published var isFolderLocked: Bool
    @Published var searchText = ""
    @Published var isInitialsGridPresented = false
    @Published var isManageContactsViewPresented = false
    @Published var isSettingUpMyCard = false
    @Published var isAddContactViewPresented = false
    @Published var isCodeScannerPresented = false
    @Published var isDeleteContactsDialogPresented = false
    @Published var isMergeAllDuplicatesDialogPresented = false
    @Published var isPermanentlyDeleteContactsDialogPresented = false
    @Published var isDeleteAllContactsDialogPresented = false
    @Published var isRestoreAllContactsDialogPresented = false
    @Published var contactsToDelete = [Contact]()
    
    init(folder: Folder, isFolderLocked: Bool) {
        self.folder = folder
        self.isFolderLocked = isFolderLocked
    }
    
    var categorizedContacts: [[Contact]] {
        switch folder {
        case .all:
            return contactStore.unhiddenContacts.map { [$0] }
        case .hidden:
            return contactStore.hiddenContacts.map { [$0] }
        case .deleted:
            return contactStore.deletedContacts.map { [$0] }
        case .duplicates:
            return contactStore.duplicates
        }
    }
    
    var filteredContacts: [[Contact]] {
        categorizedContacts.filter {
            searchText.isEmpty ||
            ($0[0].firstName + " " + ($0[0].lastName ?? "")).lowercased().contains(searchText.lowercased()) ||
            (($0[0].lastName ?? "") + " " + ($0[0].firstName)).lowercased().contains(searchText.lowercased()) ||
            $0.contains { $0.company?.lowercased().contains(searchText.lowercased()) == true } ||
            $0.contains { $0.notes?.lowercased().contains(searchText.lowercased()) == true } ||
            $0.contains { $0.phoneNumbers.contains(where: { $0.value.lowercased().contains(searchText.lowercased()) }) } ||
            $0.contains { $0.phoneNumbers.contains(where: { $0.value.plainPhoneNumber.lowercased().contains(searchText.plainPhoneNumber.lowercased()) }) } ||
            $0.contains { $0.emailAddresses.contains(where: { $0.value.lowercased().contains(searchText.lowercased()) }) }
        }
    }
    
    var emergencyContacts: [[Contact]] {
        filteredContacts.filter { $0.contains { $0.isEmergencyContact } }
    }
    
    var favorites: [[Contact]] {
        filteredContacts.filter { $0.contains { $0.isFavorite } }
    }
    
    var initials: [String] {
        var keys = [String]()
        for contacts in filteredContacts {
            if !contacts.allSatisfy({ $0.isMyCard }) {
                if let firstLetter = contacts[0].firstLetter(sortOrder: contactStore.sortOrder) {
                    if !keys.contains(firstLetter) {
                        keys.append(firstLetter)
                    }
                }
            }
        }
        return keys.sorted()
    }
    
    var groupedContacts: [String: [[Contact]]] {
        var keys = [String]()
        var groupedContacts = [String: [[Contact]]]()
        for contacts in filteredContacts {
            if !contacts.allSatisfy({ $0.isMyCard }) {
                if let firstLetter = contacts[0].firstLetter(sortOrder: contactStore.sortOrder) {
                    if keys.contains(firstLetter) {
                        groupedContacts[firstLetter]?.append(contacts)
                    } else {
                        groupedContacts[firstLetter] = [contacts]
                        keys.append(firstLetter)
                    }
                }
                
            }
        }
        return groupedContacts
    }
    
    func authenticate() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authentication is required to view \(folder.rawValue.lowercased()).") { success, _ in
                Task { @MainActor in
                    if success {
                        self.isFolderLocked = false
                    }
                }
            }
        } else {
            isFolderLocked = false
        }
    }
    
    func handleScan(result: Result<Data?, ScanError>, onSuccess: (Contact) -> Void) {
        switch result {
        case .success(let data):
            do {
                guard let data = data else { return }
                var contact = try JSONDecoder().decode(Contact.self, from: data)
                contact.id = UUID()
                isCodeScannerPresented = false
                onSuccess(contact)
            } catch {}
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
    
}
