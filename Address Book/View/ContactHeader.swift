//
//  ContactHeader.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import SwiftUI

struct ContactHeader: View {
    @Binding var contact: Contact
    let isEditing: Bool
    @EnvironmentObject var contactStore: ContactStore
    @State private var isImagePickerPresented = false
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                ContactImage(contact: contact)
                    .frame(width: 100, height: 100)
                if isEditing {
                    if contact.imageData != nil {
                        Button {
                            UISelectionFeedbackGenerator().selectionChanged()
                            contact.imageData = nil
                        } label: {
                            ZStack {
                                Image(systemName: "x.circle.fill")
                                    .foregroundStyle(.white, .gray)
                                Image(systemName: "x.circle")
                                    .foregroundStyle(.white, .white)
                            }
                            .font(.title2)
                            .shadow(radius: 0.5)
                        }
                    }
                }
            }
            if isEditing {
                Button(contact.imageData == nil ? "Add Image" : "Edit Image") {
                    isImagePickerPresented.toggle()
                }
                .font(.body)
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(imageData: $contact.imageData)
                }
            } else {
                Text(contact.fullName(displayOrder: contactStore.displayOrder))
                    .font(.title)
                    .foregroundColor(.primary)
                if contact.company?.isTotallyEmpty == false {
                    Text(contact.company ?? "")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .textCase(nil)
    }
}

struct ContactHeader_Previews: PreviewProvider {
    static var previews: some View {
        ContactHeader(contact: .constant(.example), isEditing: true)
            .previewLayout(.sizeThatFits)
            .environmentObject(ContactStore.shared)
    }
}
