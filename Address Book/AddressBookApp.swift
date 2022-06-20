//
//  AddressBookApp.swift
//  Address Book
//
//  Created by Fawzi Rifai on 11/06/2022.
//

import SwiftUI

@main
struct AddressBookApp: App {
    @StateObject var contactStore = ContactStore.shared
    var body: some Scene {
        WindowGroup {
            if contactStore.isAuthorized {
                ContactList(folder: .all, isFolderLocked: false)
                    .environmentObject(contactStore)
                
            } else {
                RequestAccess()
                    .environmentObject(contactStore)
            }
        }
    }
    init() {
        UITableView.appearance().backgroundColor = UIColor { $0.userInterfaceStyle == .light ? UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1) : UIColor.systemBackground }
    }
}
