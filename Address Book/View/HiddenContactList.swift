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
        List {
            ForEach(contactStore.hiddenContactsDictionary.keys.sorted(by: <), id: \.self) { letter in
                Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                    ForEach(contactStore.hiddenContactsDictionary[letter] ?? []) { contact in
                        ContactRow(contact: contact)
                    }
                }
            }
        }
        .navigationTitle("Hidden Contacts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HiddenContactList_Previews: PreviewProvider {
    static var previews: some View {
        HiddenContactList()
    }
}
