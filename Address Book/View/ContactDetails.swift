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
    @State var region: MKCoordinateRegion?
    var contact: Contact
    @State var isEditingContact = false
    @State private var isCodeGeneratorPresented = false
    var body: some View {
        ZStack {
            Form {
                Section(header:ContactImage(contact: contact)) {}
                if contact.phoneNumbers.count > 0 {
                    Section() {
                        ForEach(contact.phoneNumbers) { phone in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(phone.label ?? "")
                                    Text(phone.value)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                if !contact.isMyCard {
                                    Spacer()
                                    Button {
                                        guard let url = URL(string: "tel:\(phone.value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: ""))") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Image(systemName: "phone.fill")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                            .frame(width: 30, height: 30)
                                            .background(.regularMaterial)
                                            .clipShape(Circle())
                                            .shadow(radius: 1)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                    Button {
                                        guard let url = URL(string: "sms:\(phone.value.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "").replacingOccurrences(of: "-", with: ""))") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Image(systemName: "message.fill")
                                            .font(.footnote)
                                            .foregroundColor(.blue)
                                            .frame(width: 30, height: 30)
                                            .background(.regularMaterial)
                                            .clipShape(Circle())
                                            .shadow(radius: 1)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                if contact.emailAddresses.count > 0 {
                    Section() {
                        ForEach(contact.emailAddresses) { email in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(email.label ?? "")
                                    Text(email.value)
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                }
                                if !contact.isMyCard {
                                    Spacer()
                                    Button {
                                        guard let url = URL(string: "mailto:\(email.value)") else { return }
                                        UIApplication.shared.open(url)
                                    } label: {
                                        Image(systemName: "envelope.fill")
                                            .foregroundColor(.blue)
                                            .font(.footnote)
                                            .frame(width: 30, height: 30)
                                            .background(.regularMaterial)
                                            .clipShape(Circle())
                                            .shadow(radius: 1)
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            }
                            .padding(.vertical, 8)
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
                                        contact.image
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
                        QRCodeGenerator(contact: contact)
                    }
                    if !contact.isMyCard {
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
                        Button("Hide Contact") {
                        }
                        Button("Delete Contact", role: .destructive) {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isDeleteContactAlertPresented.toggle()
                        }
                        .confirmationDialog("Delete Contact?", isPresented: $isDeleteContactAlertPresented) {
                            Button("Delete", role: .destructive) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                                    withAnimation {
                                        contactStore.delete(contact)
                                    }
                                }
                            }
                        } message: {
                            Text("Are you sure you want to delete this contact?")
                        }
                    } else {
                        Button("Delete My Card", role: .destructive) {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            isDeleteContactAlertPresented = true
                        }
                        .confirmationDialog("Delete Your Card?", isPresented: $isDeleteContactAlertPresented) {
                            Button("Delete", role: .destructive) {
                                dismiss()
                                contactStore.delete(contact)
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
                EditContact(contact: contact, coordinateRegion: $region, isEditingContact: $isEditingContact, completeionHandler: {_ in})
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
