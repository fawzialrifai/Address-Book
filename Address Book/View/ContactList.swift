//
//  ContactList.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import SwiftUI

struct ContactList: View {
    @StateObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        ZStack {
            Color.contactsBackgroundColor
                .ignoresSafeArea()
            if viewModel.isFolderLocked {
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
                    Button("View \(viewModel.folder.rawValue)") {
                        viewModel.authenticate()
                    }
                }
            } else {
                ScrollViewReader { scrollViewProxy in
                    ZStack {
                        if viewModel.folder == .all {
                            NavigationView {
                                Contacts(scrollViewProxy: scrollViewProxy)
                            }
                        } else {
                            Contacts(scrollViewProxy: scrollViewProxy)
                                .navigationBarHidden(viewModel.isInitialsPresented)
                                .safeAreaInset(edge: .bottom) {
                                    if viewModel.folder == .deleted && !contactStore.deletedContacts.isEmpty {
                                        VStack(spacing: 16) {
                                            Button {
                                                viewModel.isDeleteAllContactsDialogPresented = true
                                            } label: {
                                                Label("Delete All Permanently", systemImage: "trash.fill")
                                                    .padding()
                                                    .frame(maxWidth: .infinity)
                                                    .foregroundColor(.white)
                                                    .background(.red)
                                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                            .padding([.horizontal, .top], 20)
                                            .confirmationDialog("Delete All Permanently?", isPresented: $viewModel.isDeleteAllContactsDialogPresented) {
                                                Button("Delete All Permanently") {
                                                    for contact in contactStore.deletedContacts {
                                                        contactStore.permanentlyDelete(contact)
                                                    }
                                                }
                                            } message: {
                                                Text("These contacts will be deleted permanently, This action cannot be undone.")
                                            }
                                            Button("Restore All") {
                                                for contact in contactStore.deletedContacts {
                                                    contactStore.restore(contact)
                                                }
                                            }
                                            .padding(.bottom, 20)
                                        }
                                        .background(Material.thinMaterial)
                                        .shadow(radius: 0.5)
                                    }
                                }
                        }
                        if viewModel.isInitialsPresented {
                            InitialsGrid(isInitialsPresented: $viewModel.isInitialsPresented, folder: viewModel.folder, scrollViewProxy: scrollViewProxy)
                                .zIndex(1)
                        }
                    }
                }
            }
        }
        .environmentObject(viewModel)
    }
    init(folder: Folder, isFolderLocked: Bool = true) {
        _viewModel = StateObject(wrappedValue: ContactListViewModel(folder: folder, isFolderLocked: isFolderLocked))
    }
}

struct Contacts: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var scrollViewProxy: ScrollViewProxy
    var body: some View {
            List {
                if viewModel.folder == .all {
                    MyCardSection()
                }
                EmergencySection()
                FavoritesSection()
                FirstLettersSections()
            }
            .confirmationDialog("Delete Contact?", isPresented: $viewModel.isDeleteContactDialogPresented) {
                Button("Delete", role: .destructive) {
                    withAnimation {
                        guard let contactToDelete = viewModel.contactToDelete else {
                            return
                        }
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        contactStore.moveToDeletedList(contactToDelete)
                    }
                    viewModel.contactToDelete = nil
                }
            } message: {
                if let contactToDelete = viewModel.contactToDelete {
                    Text("Are you sure you want to delete \(contactToDelete.fullName(displayOrder: contactStore.displayOrder)) from your contacts?")
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationBarTitle(viewModel.folder.rawValue, displayMode: viewModel.folder == .all ? .large : .inline)
            .searchable(text: viewModel.folder == .all ? $contactStore.filterText : viewModel.folder == .hidden ? $contactStore.hiddenFilterText : $contactStore.deletedFilterText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search for a contact")
            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewModel.folder == .all {
                            Button("Manage") { viewModel.isManageContactsViewPresented.toggle() }
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if viewModel.folder == .all {
                            Menu {
                                Button {
                                    viewModel.isNewContactViewPresented.toggle()
                                } label: {
                                    Label("Add Manually", systemImage: "plus")
                                }
                                Button {
                                    viewModel.isCodeScannerPresented = true
                                } label: {
                                    Label("Scan QR Code", systemImage: "qrcode")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .sheet(isPresented: $viewModel.isNewContactViewPresented) {
                NavigationView {
                    EditContact(contact: Contact()) { newContact in
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
            .sheet(isPresented: $viewModel.isManageContactsViewPresented) {
                ManageContacts()
            }
            .sheet(isPresented: $viewModel.isCodeScannerPresented) {
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
                                viewModel.isCodeScannerPresented = false
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
    func handleScan(result: Result<Data?, ScanError>) {
        switch result {
        case .success(let data):
            do {
                guard let data = data else { return }
                var newContact = try JSONDecoder().decode(Contact.self, from: data)
                newContact.id = UUID()
                viewModel.isCodeScannerPresented = false
                contactStore.add(newContact)
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
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
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
                        Button("Set up your card") { viewModel.isSettingUpMyCard.toggle() }
                        Text("Add your info.")
                            .font(Font.callout)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $viewModel.isSettingUpMyCard) {
            NavigationView {
                EditContact(contact: Contact(isMyCard: true))
                .navigationTitle("My Card")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

struct EmergencySection: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        if !contactStore.emergencyContacts(in: viewModel.folder).isEmpty {
            Section(header: SectionHeader(view: AnyView(Image(systemName: "staroflife.fill")))) {
                ForEach(contactStore.emergencyContacts(in: viewModel.folder)) { contact in
                    ContactRow(contact: contact)
                }
            }
            .id("staroflife")
        }
    }
}

struct FavoritesSection: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        if !contactStore.favorites(in: viewModel.folder).isEmpty {
            Section(header: SectionHeader(view: AnyView(Text("★")))) {
                ForEach(contactStore.favorites(in: viewModel.folder)) { contact in
                    ContactRow(contact: contact)
                }
            }
            .id("★")
        }
    }
}

struct FirstLettersSections: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        ForEach(contactStore.contactsDictionary(for: viewModel.folder).keys.sorted(by: <), id: \.self) { letter in
            Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                ForEach(contactStore.contactsDictionary(for: viewModel.folder)[letter] ?? []) { contact in
                    ContactRow(contact: contact)
                        .id(contact.id)
                }
            }
            .id(letter)
        }
    }
}

struct ContactRow: View {
    @EnvironmentObject var viewModel: ContactListViewModel
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
                viewModel.isDeleteContactDialogPresented.toggle()
                viewModel.contactToDelete = contact
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
            .tint(.red)
        }
    }
}

struct SectionHeader: View {
    @EnvironmentObject var contactStore: ContactStore
    @EnvironmentObject var viewModel: ContactListViewModel
    @Environment(\.dismissSearch) private var dismissSearch
    let view: AnyView
    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            dismissSearch()
            withAnimation {
                viewModel.isInitialsPresented.toggle()
            }
        } label: {
            view.frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(.secondary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContactList(folder: .all)
            .environmentObject(ContactStore())
    }
}
