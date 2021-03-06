//
//  ManageContacts.swift
//  Address Book
//
//  Created by Fawzi Rifai on 10/05/2022.
//

import SwiftUI
import LocalAuthentication

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
                        ContactList(folder: .duplicates, isFolderLocked: false)
                    } label: {
                        HStack {
                            Text("Duplicates")
                            Spacer()
                            Text(contactStore.duplicates.count, format: .number)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink {
                        ContactList(folder: .hidden, isFolderLocked: true)
                    } label: {
                        HStack {
                            Text("Hidden")
                            Spacer()
                            Text(contactStore.hiddenContacts.count, format: .number)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink {
                        ContactList(folder: .deleted, isFolderLocked: true)
                    } label: {
                        HStack {
                            Text("Recently Deleted")
                            Spacer()
                            Text(contactStore.deletedContacts.count, format: .number)
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
                    let contacts = try JSONDecoder().decode([Contact].self, from: encodedContacts)
                    for contact in contacts {
                        contactStore.add(contact)
                    }
                    contactStore.isImporting = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } catch {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            })
            .confirmationDialog("Delete all Contacts?", isPresented: $isDeleteContactsAlertPresented) {
                Button("Delete All", role: .destructive) {
                    authenticate()
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
    func authenticate() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authentication is required to delete all contacts.") { success, _ in
                Task { @MainActor in
                    if success {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        contactStore.moveToDeletedList(contactStore.contacts)
                    }
                }
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            contactStore.moveToDeletedList(contactStore.contacts)
        }
    }
}

struct ManageContacts_Previews: PreviewProvider {
    static var previews: some View {
        ManageContacts()
    }
}
