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
    @Published var isInitialsPresented = false
    @Published var isManageContactsViewPresented = false
    @Published var isNewContactViewPresented = false
    @Published var isCodeScannerPresented = false
    @Published var isDeleteContactDialogPresented = false
    @Published var isDeleteAllContactsDialogPresented = false
    @Published var contactToDelete: Contact?
    @Published var isSettingUpMyCard = false
    init(folder: Folder, isFolderLocked: Bool) {
        self.folder = folder
        self.isFolderLocked = isFolderLocked
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
}
