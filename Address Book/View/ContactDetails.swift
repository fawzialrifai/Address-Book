//
//  ContactDetails.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import MapKit

struct ContactDetails: View {
    @EnvironmentObject var contactStore: ContactStore
    @Environment(\.dismiss) private var dismiss
    @State private var isDeleteContactAlertPresented = false
    @State private var isPermanentlyDeleteContactAlertPresented = false
    @State private var isHideContactAlertPresented = false
    @State private var isUnhideContactAlertPresented = false
    @State private var isRestoreContactAlertPresented = false
    @State private var expandedPhoneNumber: LabeledValue? = nil
    @State private var expandedEmailAddress: LabeledValue? = nil
    @State var region: MKCoordinateRegion?
    var contact: Contact
    @State var isEditingContact = false
    @State private var isCodeGeneratorPresented = false
    var body: some View {
        ZStack {
            Form {
                Section(header: ContactHeader(contact: .constant(contact), isEditing: false)) {}
                if contact.phoneNumbers.count > 0 {
                    Section() {
                        ForEach(contact.phoneNumbers) { phone in
                            if contact.isMyCard {
                                VStack(alignment: .leading) {
                                    Text(phone.label)
                                    Text(phone.value)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 8)
                            } else {
                                let isExpanded: Binding<Bool> = Binding {
                                    expandedPhoneNumber == phone
                                } set: { value in }
                                DisclosureGroup(isExpanded: isExpanded) {
                                    Button {
                                        guard let url = URL(string: "tel:\(phone.value.plainPhoneNumber)") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Label("Call", systemImage: "phone")
                                    }
                                    Button {
                                        guard let url = URL(string: "sms:\(phone.value.plainPhoneNumber)") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Label("Message", systemImage: "message")
                                    }
                                    Button {
                                    } label: {
                                        Label("FaceTime", systemImage: "video")
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(phone.label)
                                        Button(phone.value) {
                                            withAnimation {
                                                if expandedPhoneNumber == phone {
                                                    expandedPhoneNumber = nil
                                                } else {
                                                    expandedPhoneNumber = phone
                                                }
                                            }
                                        }
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                    }
                                    .padding(8)
                                }
                            }
                        }
                    }
                }
                if contact.emailAddresses.count > 0 {
                    Section() {
                        ForEach(contact.emailAddresses) { email in
                            if contact.isMyCard {
                                VStack(alignment: .leading) {
                                    Text(email.label)
                                    Text(email.value)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 8)
                            } else {
                                let isEmailExpanded: Binding<Bool> = Binding {
                                    expandedEmailAddress == email
                                } set: { value in }
                                DisclosureGroup(isExpanded: isEmailExpanded) {
                                    Button {
                                        guard let url = URL(string: "mailto:\(email.value)") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Label("Mail", systemImage: "envelope")
                                    }
                                    Button {
                                    } label: {
                                        Label("FaceTime", systemImage: "video")
                                    }
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(email.label)
                                        Button(email.value) {
                                            withAnimation {
                                                if expandedEmailAddress == email {
                                                    expandedEmailAddress = nil
                                                } else {
                                                    expandedEmailAddress = email
                                                }
                                            }
                                        }
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                    }
                                    .padding(8)
                                }
                            }
                        }
                    }
                }
                if contact.coordinateRegion != nil {
                    Section {
                        if let coordinate = contact.coordinate, let coordinateRegion = contact.coordinateRegion {
                            let strongCoordinateRegion: Binding<MKCoordinateRegion> = Binding {
                                coordinateRegion
                            } set: {
                                region = $0
                            }
                            Map(coordinateRegion: strongCoordinateRegion, annotationItems: [contact]) {_ in
                                MapAnnotation(coordinate: coordinate) {
                                    Button {
                                        guard let url = contact.mapURL else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        contact.image?
                                            .resizable()
                                            .scaledToFill()
                                            .foregroundStyle(.white, .gray)
                                            .frame(width: 30, height: 30)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(lineWidth: 2).foregroundColor(.white))
                                            .shadow(radius: 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .frame(height: 200)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                }
                if let birthday = contact.birthday {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Birthday")
                            Text(birthday.formatted(.dateTime.year().month().day()))
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                }
                if let notes = contact.notes {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Notes")
                            Text(notes)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .frame(minHeight: 100, alignment: .top)
                    }
                }
                Section {
                    Button("Generate QR Code") {
                        isCodeGeneratorPresented = true
                    }
                    .sheet(isPresented: $isCodeGeneratorPresented) {
                        CodeGenerator(contact: contact)
                    }
                    if contact.isDeleted {
                        Button("Restore Contact") {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isRestoreContactAlertPresented = true
                        }
                        .confirmationDialog("Restore Contact?", isPresented: $isRestoreContactAlertPresented) {
                            Button("Restore") {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.restore(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("\(contact.fullName(displayOrder: contactStore.displayOrder)) will be restored and moved out of the Recently Deleted folder.")
                        }
                        Button("Delete Contact", role: .destructive) {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isPermanentlyDeleteContactAlertPresented = true
                        }
                        .confirmationDialog("Permanently Delete Contact?", isPresented: $isPermanentlyDeleteContactAlertPresented) {
                            Button("Delete Permanently", role: .destructive) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.permanentlyDelete(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("\(contact.fullName(displayOrder: contactStore.displayOrder)) will be deleted permanently, This action cannot be undone.")
                        }
                    } else if !contact.isMyCard {
                        Button(contact.isEmergencyContact ? "Remove from Emergency Contacts" : "Add to Emergency Contacts") {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            if contact.isEmergencyContact {
                                contactStore.removeFromEmergencyContacts(contact)
                            } else {
                                contactStore.addToEmergencyContacts(contact)
                            }
                        }
                        Button(contact.isFavorite ? "Remove from Favorites" : "Add to Favorites") {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            if contact.isFavorite {
                                contactStore.removeFromFavorites(contact)
                            } else {
                                contactStore.addToFavorites(contact)
                            }
                        }
                        Button(contact.isHidden ? "Unhide Contact" : "Hide Contact") {
                            if contact.isHidden {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                isUnhideContactAlertPresented = true
                            } else {
                                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                                isHideContactAlertPresented.toggle()
                            }
                        }
                        Button("Delete Contact", role: .destructive) {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isDeleteContactAlertPresented.toggle()
                        }
                        .confirmationDialog("Hide Contact?", isPresented: $isHideContactAlertPresented) {
                            Button("Hide") {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.hideContact(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("This contact will be hidden but can be found in the Hidden folder.")
                        }
                        .confirmationDialog("Unhide Contact?", isPresented: $isUnhideContactAlertPresented) {
                            Button("Unhide") {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.unhideContact(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("This contact will be unhidden and moved out of the Hidden folder.")
                        }
                        .confirmationDialog("Delete Contact?", isPresented: $isDeleteContactAlertPresented) {
                            Button("Delete", role: .destructive) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.moveToDeletedList(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("Are you sure you want to delete \(contact.fullName(displayOrder: contactStore.displayOrder)) from your contacts?")
                        }
                    } else {
                        Button("Delete My Card", role: .destructive) {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isDeleteContactAlertPresented = true
                        }
                        .confirmationDialog("Delete Your Card?", isPresented: $isDeleteContactAlertPresented) {
                            Button("Delete", role: .destructive) {
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                contactStore.moveToDeletedList(contact)
                            }
                        } message: {
                            Text("Are you sure you want to delete your card?")
                        }
                    }
                }
            }
            .navigationTitle(isEditingContact ? "Edit Contact" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditingContact {
                    Button("Edit") {
                        UISelectionFeedbackGenerator().selectionChanged()
                        isEditingContact.toggle()
                    }
                }
            }
            if isEditingContact {
                EditContact(contact: contact, isEditingContact: $isEditingContact, completeionHandler: {_ in})
                    .zIndex(1)
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
    init(contact: Contact) {
        self.contact = contact
        _region = State(initialValue: contact.coordinateRegion)
    }
}

struct ContactDetails_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContactDetails(contact: .example)
        }
    }
}
