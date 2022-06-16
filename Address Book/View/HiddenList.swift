//
//  HiddenList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/06/2022.
//

import SwiftUI
import LocalAuthentication

struct HiddenList: View {
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
                    Button("View Hidden Contacts") {
                        authenticate()
                    }
                }
            } else {
                if contactStore.hiddenContacts.isEmpty {
                    Text("No Hidden Contacts")
                        .foregroundColor(.secondary)
                        .font(.title2)
                } else {
                    List(contactStore.hiddenContactsDictionary.keys.sorted(by: <), id: \.self) { letter in
                        Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                            ForEach(contactStore.hiddenContactsDictionary[letter] ?? []) { contact in
                                ContactRow(contact: contact)
                            }
                        }
                        
                    }
                }
            }
        }
        .navigationTitle("Hidden Contacts")
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
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authentication is required to view hidden contacts.") { success, _ in
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

struct HiddenContactList_Previews: PreviewProvider {
    static var previews: some View {
        HiddenList()
            .environmentObject(ContactStore())
    }
}
