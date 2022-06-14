//
//  HiddenContactList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/06/2022.
//

import SwiftUI

struct HiddenContactList: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        ZStack {
            Color.contactsBackgroundColor
                .ignoresSafeArea()
            if contactStore.isHiddenFolderLocked {
                VStack(alignment: .center, spacing: 8) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.secondary)
                            .font(.largeTitle)
                        Text("Authentication Required")
                            .foregroundColor(.secondary)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                    }
                    Button("View Hidden Contacts") {
                        contactStore.authenticate(reason: "Authentication is required to view hidden contacts.")
                    }
                }
            } else {
                if contactStore.hiddenContacts.isEmpty {
                    Text("No Hidden Contacts")
                        .foregroundColor(.secondary)
                        .font(.title2)
                } else {
                    List {
                        ForEach(contactStore.hiddenContactsDictionary.keys.sorted(by: <), id: \.self) { letter in
                            Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                                ForEach(contactStore.hiddenContactsDictionary[letter] ?? []) { contact in
                                    ContactRow(contact: contact)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Hidden Contacts")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            contactStore.authenticate(reason: "Authentication is required to view hidden contacts.")
        }
    }
}

struct HiddenContactList_Previews: PreviewProvider {
    static var previews: some View {
        HiddenContactList()
            .environmentObject(ContactStore())
    }
}
