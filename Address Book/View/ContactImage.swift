//
//  ContactImage.swift
//  Address Book
//
//  Created by Fawzi Rifai on 10/05/2022.
//

import SwiftUI

struct ContactImagee: View {
    @EnvironmentObject var contactStore: ContactStore
    var contact: Contact
    var body: some View {
        VStack {
            contact.image?
                .resizable()
                .scaledToFill()
                .foregroundStyle(.white, .gray)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(radius: 0.5)
            Text(contact.fullName(displayOrder: contactStore.displayOrder))
                .font(.title)
                .foregroundColor(.primary)
            if contact.company?.isTotallyEmpty == false {
                Text(contact.company ?? "")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .textCase(nil)
    }
}

struct ContactImagee_Previews: PreviewProvider {
    static var previews: some View {
        ContactImagee(contact: .example)
            .previewLayout(.sizeThatFits)
            .environmentObject(ContactStore.shared)
    }
}
