//
//  DuplicatesList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/06/2022.
//

import SwiftUI

struct DuplicatesList: View {
    @EnvironmentObject var contactStore: ContactStore
    @State private var isMergeAlertPresented = false
    var body: some View {
        Group {
            if contactStore.duplicates.isEmpty {
                ZStack {
                    Color.contactsBackgroundColor
                        .ignoresSafeArea()
                    Text("No Duplicates")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            } else {
                List(contactStore.duplicatesDictionary.keys.sorted(by: <), id: \.self) { letter in
                    Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                        ForEach(contactStore.duplicatesDictionary[letter] ?? [], id: \.[0].id) { duplicates in
                            NavigationLink {
                                MergeContact(duplicates: duplicates)
                            } label: {
                                HStack {
                                    HStack {
                                        ForEach(duplicates.prefix(3)) { contact in
                                            if let index = duplicates.firstIndex(of: contact) {
                                                contact.image?
                                                    .resizable()
                                                    .scaledToFill()
                                                    .foregroundStyle(.white, .gray)
                                                    .frame(width: 45, height: 45)
                                                    .clipShape(Circle())
                                                    .shadow(radius: 1)
                                                    .padding(.leading, index == 0 ? 0 : -42.5)
                                            }
                                        }
                                    }
                                    .frame(width: 70)
                                    VStack(alignment: .leading) {
                                        Text(duplicates.first!.fullName(displayOrder: contactStore.displayOrder))
                                        Text("\(duplicates.count) cards")
                                            .font(Font.callout)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Button {
                            isMergeAlertPresented = true
                        } label: {
                            Text("Merge All")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .background(.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(24)
                    }
                    .background(Material.thinMaterial)
                    .shadow(radius: 0.5)
                }
                .confirmationDialog("Merge Duplicates?", isPresented: $isMergeAlertPresented) {
                    Button("Merge All") {
                        for duplicates in contactStore.duplicates {
                            var newContact = Contact()
                            for contact in duplicates {
                                newContact.firstName = contact.firstName
                                newContact.lastName = contact.lastName
                                if let company = contact.company {
                                    newContact.company = company
                                }
                                for phoneNumber in contact.phoneNumbers {
                                    if !newContact.phoneNumbers.contains(phoneNumber) {
                                        newContact.phoneNumbers.append(phoneNumber)
                                    }
                                }
                                for emailAdress in contact.emailAddresses {
                                    if !newContact.emailAddresses.contains(emailAdress) {
                                        newContact.emailAddresses.append(emailAdress)
                                    }
                                }
                                if let birthday = contact.birthday {
                                    newContact.birthday = birthday
                                }
                                if let imageData = contact.imageData {
                                    newContact.imageData = imageData
                                }
                                contactStore.delete(contact)
                            }
                            contactStore.contacts.append(newContact)
                            contactStore.sortContacts()
                        }
                    }
                } message: {
                    Text("Merging duplicate cards combines those with the same information into a single contact card.")
                }
            }
        }
        .navigationTitle("Duplicate Contacts")
    }
    
}

struct DuplicatesList_Previews: PreviewProvider {
    static var previews: some View {
        DuplicatesList()
    }
}
