//
//  ContactListViewModel.swift
//  Address Book
//
//  Created by Fawzi Rifai on 19/06/2022.
//

import SwiftUI
import LocalAuthentication

@MainActor class ContactListViewModel: ObservableObject {
    var folder: Folder
    @Published var isFolderLocked: Bool
    @Published var searchText = ""
    var contactStore = ContactStore.shared
    @Published var isInitialsPresented = false
    @Published var isManageContactsViewPresented = false
    @Published var isNewContactViewPresented = false
    @Published var isCodeScannerPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var isPermanentlyDeleteContactDialogPresented = false
    @Published var isRestoreAllContactsDialogPresented = false
    @Published var isDeleteAllContactsDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isSettingUpMyCard = false
    
    init(folder: Folder, isFolderLocked: Bool) {
        self.folder = folder
        self.isFolderLocked = isFolderLocked
    }
    
    var categorizedContacts: [Contact] {
        if folder == .all {
            return contactStore.unhiddenContacts
        }
        else if folder == .hidden {
            return contactStore.hiddenContacts
        } else {
            return contactStore.deletedContacts
        }
    }
    
    var filteredContacts: [Contact] {
        return categorizedContacts.filter {
            searchText.isEmpty ||
            ($0.firstName + " " + ($0.lastName ?? "")).lowercased().contains(searchText.lowercased()) ||
            (($0.lastName ?? "") + " " + ($0.firstName)).lowercased().contains(searchText.lowercased()) ||
            $0.company?.lowercased().contains(searchText.lowercased()) == true ||
            $0.notes?.lowercased().contains(searchText.lowercased()) == true ||
            $0.phoneNumbers.contains(where: { $0.value.lowercased().contains(searchText.lowercased()) }) ||
            $0.phoneNumbers.contains(where: { $0.value.plainPhoneNumber.lowercased().contains(searchText.plainPhoneNumber.lowercased()) }) ||
            $0.emailAddresses.contains(where: { $0.value.lowercased().contains(searchText.lowercased()) })
            
        }
    }
    
    var groupedContacts: [String: [Contact]] {
        var keys = [String]()
        var groupedContacts = [String: [Contact]]()
        for contact in filteredContacts {
            if !contact.isMyCard {
                if let firstLetter = contact.firstLetter(sortOrder: contactStore.sortOrder) {
                    if keys.contains(firstLetter) {
                        groupedContacts[firstLetter]?.append(contact)
                    } else {
                        groupedContacts[firstLetter] = [contact]
                        keys.append(firstLetter)
                    }
                }
                
            }
        }
        return groupedContacts
    }
    
    var emergencyContacts: [Contact] {
        filteredContacts.filter({ $0.isEmergencyContact })
    }
    
    var favorites: [Contact] {
        filteredContacts.filter({ $0.isFavorite })
    }
    
    var initials: [String] {
        var keys = [String]()
        for contact in filteredContacts {
            if !contact.isMyCard {
                if let firstLetter = contact.firstLetter(sortOrder: contactStore.sortOrder) {
                    if !keys.contains(firstLetter) {
                        keys.append(firstLetter)
                    }
                }
            }
        }
        return keys.sorted()
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
