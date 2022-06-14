//
//  ContactList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI
import MapKit

struct ContactList: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ZStack {
                Contacts(scrollViewProxy: scrollViewProxy)
                if contactStore.isFirstLettersGridPresented {
                    FirstLettersGrid(scrollViewProxy: scrollViewProxy)
                    .zIndex(1)
                }
            }
        }
    }
}

struct Contacts: View {
    @Environment (\.scenePhase) private var scenePhase
    @EnvironmentObject var contactStore: ContactStore
    @State private var isManageContactsViewPresented = false
    @State private var isNewContactViewPresented = false
    @State private var isCodeScannerPresented = false
    var scrollViewProxy: ScrollViewProxy
    var body: some View {
        NavigationView {
            List {
                MyCardSection()
                EmergencySection()
                FavoritesSection()
                FirstLettersSections()
            }
            .confirmationDialog("Delete Contact?", isPresented: $contactStore.isDeleteContactDialogPresented) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        guard let contactToDelete = contactStore.contactToDelete else {
                            return
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        contactStore.delete(contactToDelete)
                    }
                    contactStore.contactToDelete = nil
                }
            } message: {
                if let contactToDelete = contactStore.contactToDelete {
                    Text("Are you sure you want to delete \(contactToDelete.fullName(displayOrder: contactStore.displayOrder)) from your contacts?")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Contacts")
            .searchable(text: $contactStore.filterText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search for a contact")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Manage") { isManageContactsViewPresented.toggle() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isNewContactViewPresented.toggle()
                        } label: {
                            Label("Add Manually", systemImage: "plus")
                        }
                        Button {
                            isCodeScannerPresented = true
                        } label: {
                            Label("Scan QR Code", systemImage: "qrcode")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isNewContactViewPresented) {
                NavigationView {
                    EditContact(contact: Contact(), coordinateRegion: .constant(MKCoordinateRegion()), isEditingContact: .constant(false)) { newContact in
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        contactStore.contacts.insert(newContact, at: contactStore.indexFor(newContact))
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                scrollViewProxy.scrollTo(newContact.id, anchor: .center)
                            }
                        }
                    }
                    .navigationTitle("Add Contact")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $isManageContactsViewPresented) {
                ManageContacts()
                    .environment(\.scenePhase, scenePhase)
            }
            .sheet(isPresented: $isCodeScannerPresented) {
                NavigationView {
                    CodeScannerView() { result in
                        handleScan(result: result)
                    }
                    .background(.contactsBackgroundColor)
                    .navigationTitle("Scan QR Code")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
                            Button("Cancel") {
                                isCodeScannerPresented = false
                            }
                        }
                    }
                }
                
            }
            .alert("Cannot Access Contacts", isPresented: $contactStore.isNotAuthorized) {
                Button("Exit") {
                    fatalError()
                }
            } message: {
                Text("Please allow Address Book access contacts from Settings.")

            }
        }
    }
    func handleScan(result: Result<Data?, ScanError>) {
        switch result {
        case .success(let data):
            do {
                guard let data = data else { return }
                var newContact = try JSONDecoder().decode(Contact.self, from: data)
                newContact.id = UUID()
                isCodeScannerPresented = false
                contactStore.contacts.insert(newContact, at: contactStore.indexFor(newContact))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        scrollViewProxy.scrollTo(newContact.id, anchor: .center)
                    }
                }
            } catch {}
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}

struct MyCardSection: View {
    @EnvironmentObject var contactStore: ContactStore
    @State private var isSettingUpMyCard = false
    var body: some View {
        Section(header: Text("My Card").textCase(nil)) {
            if let myCard = contactStore.contacts.first(where: { $0.isMyCard }) {
                NavigationLink(destination: ContactDetails(contact: myCard)) {
                    HStack {
                        myCard.image?
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.white, .gray)
                            .frame(width: 45, height: 45)
                            .clipShape(Circle())
                            .shadow(radius: 0.5)
                        VStack(alignment: .leading) {
                            Text(myCard.fullName(displayOrder: contactStore.displayOrder))
                            if myCard.phoneNumbers.count > 0 {
                                Text(myCard.phoneNumbers[0].value)
                                    .font(Font.callout)
                                    .foregroundColor(.secondary)
                            } else if myCard.emailAddresses.count > 0 {
                                Text(myCard.emailAddresses[0].value)
                                    .font(Font.callout)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            } else {
                HStack {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 45, height: 45)
                        .clipShape(Circle())
                        .shadow(radius: 0.5)
                        .foregroundStyle(.white, .gray)
                    VStack(alignment: .leading) {
                        Button("Set up your card") { isSettingUpMyCard.toggle() }
                        Text("Add your info.")
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $isSettingUpMyCard) {
            NavigationView {
                EditContact(contact: Contact(isMyCard: true), coordinateRegion: .constant(MKCoordinateRegion()), isEditingContact: .constant(false)) { newContact in
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    contactStore.contacts.append(newContact)
                }
                .navigationTitle("My Card")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct EmergencySection: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        if !contactStore.emergencyContacts.isEmpty {
            Section(header: SectionHeader(view: AnyView(Image(systemName: "staroflife.fill")))) {
                ForEach(contactStore.emergencyContacts) { contact in
                    ContactRow(contact: contact)
                }
            }
            .id("staroflife")
        }
    }
}

struct FavoritesSection: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        if !contactStore.favorites.isEmpty {
            Section(header: SectionHeader(view: AnyView(Text("★")))) {
                ForEach(contactStore.favorites) { contact in
                    ContactRow(contact: contact)
                }
            }
            .id("★")
        }
    }
}

struct FirstLettersSections: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        ForEach(contactStore.contactsDictionary.keys.sorted(by: <), id: \.self) { letter in
            Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                ForEach(contactStore.contactsDictionary[letter] ?? []) { contact in
                    ContactRow(contact: contact)
                        .id(contact.id)
                }
            }
            .id(letter)
        }
    }
}

struct ContactRow: View {
    @EnvironmentObject var contactStore: ContactStore
    var contact: Contact
    var body: some View {
        NavigationLink(destination: ContactDetails(contact: contact)) {
            HStack {
                contact.image?
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.white, .gray)
                    .frame(width: 45, height: 45)
                    .clipShape(Circle())
                    .shadow(radius: 0.5)
                VStack(alignment: .leading) {
                    Text(contact.fullName(displayOrder: contactStore.displayOrder))
                    if contact.phoneNumbers.count > 0 {
                        Text(contact.phoneNumbers[0].value)
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                    } else if contact.emailAddresses.count > 0 {
                        Text(contact.emailAddresses[0].value)
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .contextMenu {
                if contact.phoneNumbers.count > 0 {
                    Menu {
                        ForEach(contact.phoneNumbers) { phone in
                            Button("\(phone.label ?? "")\n\(phone.value)") {
                                guard let url = URL(string: "tel:\(phone.value.plainPhoneNumber)") else { return }
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        Label("Call", systemImage: "phone")
                    }
                    Menu {
                        ForEach(contact.phoneNumbers) { phone in
                            Button("\(phone.label ?? "")\n\(phone.value)") {
                                guard let url = URL(string: "sms:\(phone.value.plainPhoneNumber)") else { return }
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        Label("Message", systemImage: "message")
                    }
                }
                if contact.emailAddresses.count > 0 {
                    Menu {
                        ForEach(contact.emailAddresses) { email in
                            Button("\(email.label ?? "")\n\(email.value)") {
                                guard let url = URL(string: "mailto:\(email.value)") else { return }
                                UIApplication.shared.open(url)
                            }
                        }
                    } label: {
                        Label("Mail", systemImage: "envelope")
                    }
                }
            }
        }
        .swipeActions(edge: .leading) {
            Button  {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation {
                    contact.isFavorite ? contactStore.removeFromFavorites(contact) : contactStore.addToFavorites(contact)
                }
            } label: {
                Label(contact.isFavorite ? "Remove for Favorites" : "Add to Favorites", systemImage: contact.isFavorite ? "star.slash.fill" : "star.fill")
            }
            .tint(.yellow)
        }
        .swipeActions(edge: .trailing) {
            Button  {
                UINotificationFeedbackGenerator().notificationOccurred(.warning)
                contactStore.isDeleteContactDialogPresented.toggle()
                contactStore.contactToDelete = contact
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            .tint(.red)
        }
    }
}

struct SectionHeader: View {
    @EnvironmentObject var contactStore: ContactStore
    @Environment(\.dismissSearch) private var dismissSearch
    let view: AnyView
    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            dismissSearch()
            withAnimation {
                contactStore.isFirstLettersGridPresented.toggle()
            }
        } label: {
            view.frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(.secondary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContactList()
            .environmentObject(ContactStore())
    }
}
