//
//  DeletedList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 16/06/2022.
//

import SwiftUI
import LocalAuthentication

struct DeletedList: View {
    @Environment (\.scenePhase) private var scenePhase
    @EnvironmentObject var contactStore: ContactStore
    @State private var isFolderLocked = true
    var body: some View {
        ZStack {
            Color.contactsBackgroundColor
                .ignoresSafeArea()
            if isFolderLocked {
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
                    Button("View Deleted Contacts") {
                        authenticate()
                    }
                }
            } else {
                if contactStore.deletedContacts.isEmpty {
                    Text("No Deleted Contacts")
                        .foregroundColor(.secondary)
                        .font(.title2)
                } else {
                    List(contactStore.deletedContactsDictionary.keys.sorted(by: <), id: \.self) { letter in
                        Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                            ForEach(contactStore.deletedContactsDictionary[letter] ?? []) { contact in
                                ContactRow(contact: contact)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Deleted Contacts")
        .onAppear {
            if isFolderLocked {
                authenticate()
            }
        }
        .onChange(of: scenePhase) { newValue in
            if newValue != .active {
                isFolderLocked = true
            }
        }
    }
    func authenticate() {
        let context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authentication is required to view deleted contacts.") { success, _ in
                Task { @MainActor in
                    if success {
                        isFolderLocked = false
                    }
                }
            }
        } else {
            isFolderLocked = false
        }
    }
}

struct DeletedList_Previews: PreviewProvider {
    static var previews: some View {
        DeletedList()
    }
}
