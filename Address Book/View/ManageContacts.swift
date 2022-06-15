//
//  ManageContacts.swift
//  Address Book
//
//  Created by Fawzi Rifai on 10/05/2022.
//

import SwiftUI

struct ManageContacts: View {
    @EnvironmentObject var contactStore: ContactStore
    @Environment(\.dismiss) private var dismiss
    @State private var exportFile = JSONFile()
    @State private var isFileImporterPresented = false
    @State private var isFileExporterPresented = false
    @State private var isDeleteContactsAlertPresented = false
    @State private var isMergeCompleted = false
    @State private var duplicatesCount = 0
    var body: some View {
        NavigationView {
            Form {
                Section("Sort Order") {
                    ForEach(Order.allCases) { option in
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            contactStore.sortOrder = option
                        } label: {
                            HStack {
                                Text(option.localizedString)
                                    .foregroundColor(.primary)
                                Spacer()
                                if contactStore.sortOrder == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                Section("Display Order") {
                    ForEach(Order.allCases) { option in
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            contactStore.displayOrder = option
                        } label: {
                            HStack {
                                Text(option.localizedString)
                                    .foregroundColor(.primary)
                                Spacer()
                                if contactStore.displayOrder == option {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                Section {
                    NavigationLink {
                        DuplicatesList()
                    } label: {
                        HStack {
                            Text("Duplicates")
                            Spacer()
                            Text(contactStore.duplicates.count, format: .number)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink {
                        HiddenContactList()
                    } label: {
                        HStack {
                            Text("Hidden")
                            Spacer()
                            Text(contactStore.hiddenContacts.count, format: .number)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink {
                        Text("Recently Deleted")
                    } label: {
                        HStack {
                            Text("Recently Deleted")
                            Spacer()
                            Text("0")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Section(footer: Text(contactStore.status)) {
                    Button("Import Contacts") {
                        isFileImporterPresented = true
                    }
                    Button("Export Contacts") {
                        do {
                            let encodedData = try JSONEncoder().encode(contactStore.contacts)
                            exportFile.data = encodedData
                            isFileExporterPresented.toggle()
                        } catch {
                            fatalError()
                        }
                    }
                    Button("Delete All Contacts", role: .destructive) {
                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        isDeleteContactsAlertPresented = true
                    }
                }
            }
            .navigationTitle("Manage Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .fileExporter(isPresented: $isFileExporterPresented, document: exportFile, contentType: .json) {_ in
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.json], onCompletion: { result in
                do {
                    contactStore.isImporting = true
                    let encodedContacts = try Data(contentsOf: result.get())
                    contactStore.contacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
                    contactStore.sortContacts()
                    contactStore.isImporting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            })
            .alert("Merge Completed!", isPresented: $isMergeCompleted) {
                Button("OK") {}
            } message: {
                if duplicatesCount == 0 {
                    Text("No duplicates found.")
                } else {
                    Text("\(duplicatesCount) duplicates were found and merged successfully.")
                }
            }
            .confirmationDialog("Delete all Contacts?", isPresented: $isDeleteContactsAlertPresented) {
                Button("Delete", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    for contact in contactStore.contacts {
                        contactStore.delete(contact)
                    }
                }
            } message: {
                Text("Are you sure you want to delete all your contacts?")
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

struct ManageContacts_Previews: PreviewProvider {
    static var previews: some View {
        ManageContacts()
    }
}
