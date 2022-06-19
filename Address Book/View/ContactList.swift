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
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Authentication Required")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Button("View \(viewModel.folder.rawValue)", action: { viewModel.authenticate() })
                }
            } else {
                ScrollViewReader { scrollViewProxy in
                    ZStack {
                        if viewModel.folder == .all {
                            NavigationView {
                                Contacts { contact in
                                    scrollViewProxy.scrollTo(contact.id, anchor: .center)
                                }
                            }
                        } else {
                            Contacts { contact in
                                scrollViewProxy.scrollTo(contact.id, anchor: .center)
                            }
                            .navigationBarHidden(viewModel.isInitialsPresented)
                            .safeAreaInset(edge: .bottom) {
                                if viewModel.folder == .deleted && !contactStore.deletedContacts.isEmpty {
                                    BottomButton()
                                }
                            }
                        }
                        if viewModel.isInitialsPresented {
                            InitialsGrid(isInitialsPresented: $viewModel.isInitialsPresented, folder: viewModel.folder, scrollViewProxy: scrollViewProxy)
                                .zIndex(1)
                        }
                    }
                    .environmentObject(viewModel)
                }
            }
        }
    }
    init(folder: Folder, isFolderLocked: Bool = true) {
        _viewModel = StateObject(wrappedValue: ContactListViewModel(folder: folder, isFolderLocked: isFolderLocked))
    }
}

struct Contacts: View {
    var onContactAdd: (Contact) -> Void
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        List {
            if viewModel.folder == .all {
                MyCardSection()
            }
            EmergencySection()
            FavoritesSection()
            FirstLettersSections()
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(viewModel.folder.rawValue, displayMode: viewModel.folder == .all ? .large : .inline)
        .searchable(text: viewModel.folder == .all ? $contactStore.filterText : viewModel.folder == .hidden ? $contactStore.hiddenFilterText : $contactStore.deletedFilterText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "Search for a contact")
        .toolbar {
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
            ToolbarItem(placement: .navigationBarLeading) {
                if viewModel.folder == .all {
                    Button("Manage") { viewModel.isManageContactsViewPresented.toggle() }
                }
            }
        }
        .sheet(isPresented: $viewModel.isManageContactsViewPresented) {
            ManageContacts()
        }
        .sheet(isPresented: $viewModel.isNewContactViewPresented) {
            NavigationView {
                EditContact(contact: Contact()) { contact in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            onContactAdd(contact)
                        }
                    }
                }
                .navigationBarTitle("Add Contact", displayMode: .inline)
            }
        }
        .sheet(isPresented: $viewModel.isCodeScannerPresented) {
            NavigationView {
                CodeScannerView() { result in
                    viewModel.handleScan(result: result) { contact in
                        contactStore.add(contact)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                onContactAdd(contact)
                            }
                        }
                    }
                }
                .background(.contactsBackgroundColor)
                .navigationBarTitle("Scan QR Code", displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
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
        .confirmationDialog("Delete Contact?", isPresented: $viewModel.isDeleteContactDialogPresented) {
            Button("Delete", role: .destructive) {
                guard let contactToDelete = viewModel.contactToDelete else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation {
                    contactStore.moveToDeletedList(contactToDelete)
                }
                viewModel.contactToDelete = nil
            }
        } message: {
            if let contactToDelete = viewModel.contactToDelete {
                Text("\(contactToDelete.fullName(displayOrder: contactStore.displayOrder)) will be deleted and moved to the Recently Deleted folder.")
            }
        }
        .confirmationDialog("Permanently Delete Contact?", isPresented: $viewModel.isPermanentlyDeleteContactDialogPresented) {
            Button("Delete Permanently", role: .destructive) {
                guard let contactToDelete = viewModel.contactToDelete else { return }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation {
                    contactStore.permanentlyDelete(contactToDelete)
                }
                viewModel.contactToDelete = nil
            }
        } message: {
            if let contactToDelete = viewModel.contactToDelete {
                Text("\(contactToDelete.fullName(displayOrder: contactStore.displayOrder)) will be deleted permanently, This action cannot be undone.")
            }
        }
    }
}

struct MyCardSection: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        Section(header: Text("My Card").textCase(nil)) {
            if let myCard = contactStore.contacts.first { $0.isMyCard } {
                ContactRow(contact: myCard)
            } else {
                HStack {
                    ContactImage(contact: Contact())
                        .frame(width: 45, height: 45)
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
                    .navigationBarTitle("My Card", displayMode: .inline)
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
    var contact: Contact
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        NavigationLink(destination: ContactDetails(contact: contact)) {
            HStack {
                ContactImage(contact: contact)
                    .frame(width: 45, height: 45)
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
            }
            .padding(.vertical, 8)
        }
        .contextMenu {
            if !contact.isMyCard {
                if contact.phoneNumbers.count > 0 {
                    Menu {
                        ForEach(contact.phoneNumbers) { phoneNumber in
                            Button("\(phoneNumber.label ?? "")\n\(phoneNumber.value)") {
                                guard let phone = URL(string: "tel:\(phoneNumber.value.plainPhoneNumber)") else { return }
                                UIApplication.shared.open(phone)
                            }
                        }
                    } label: {
                        Label("Call", systemImage: "phone")
                    }
                    Menu {
                        ForEach(contact.phoneNumbers) { phoneNumber in
                            Button("\(phoneNumber.label ?? "")\n\(phoneNumber.value)") {
                                guard let messages = URL(string: "sms:\(phoneNumber.value.plainPhoneNumber)") else { return }
                                UIApplication.shared.open(messages)
                            }
                        }
                    } label: {
                        Label("Message", systemImage: "message")
                    }
                }
                if contact.emailAddresses.count > 0 {
                    Menu {
                        ForEach(contact.emailAddresses) { emailAddress in
                            Button("\(emailAddress.label ?? "")\n\(emailAddress.value)") {
                                guard let mail = URL(string: "mailto:\(emailAddress.value)") else { return }
                                UIApplication.shared.open(mail)
                            }
                        }
                    } label: {
                        Label("Mail", systemImage: "envelope")
                    }
                }
            }
        }
        .swipeActions(edge: .leading) {
            if !contact.isMyCard {
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
        }
        .swipeActions(edge: .trailing) {
            if !contact.isMyCard {
                Button  {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    viewModel.contactToDelete = contact
                    if contact.isDeleted {
                        viewModel.isPermanentlyDeleteContactDialogPresented.toggle()
                    } else {
                        viewModel.isDeleteContactDialogPresented.toggle()
                    }
                } label: {
                    Label(contact.isDeleted ? "Delete Permanently" : "Delete", systemImage: "trash.fill")
                }
                .tint(.red)
            }
        }
    }
}

struct ContactImage: View {
    let contact: Contact
    var body: some View {
        contact.image?
            .resizable()
            .scaledToFill()
            .foregroundStyle(.white, .gray)
            .clipShape(Circle())
            .shadow(radius: 0.5)
    }
}

struct BottomButton: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
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
                    contactStore.emptyRecentlyDeletedFolder()
                }
            } message: {
                Text("These contacts will be deleted permanently, This action cannot be undone.")
            }
            Button("Restore All") {
                viewModel.isRestoreAllContactsDialogPresented.toggle()
            }
            .padding(.bottom, 20)
            .confirmationDialog("Restore All?", isPresented: $viewModel.isRestoreAllContactsDialogPresented) {
                Button("Restore All") {
                    contactStore.restoreAllDeletedContacts()
                }
            } message: {
                Text("These contacts will be restored and moved out of the Recently Deleted folder.")
            }
        }
        .background(Material.thinMaterial)
        .shadow(radius: 0.5)
    }
}

struct SectionHeader: View {
    let view: AnyView
    @EnvironmentObject var viewModel: ContactListViewModel
    @Environment(\.dismissSearch) private var dismissSearch
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

struct ContactList_Previews: PreviewProvider {
    static var previews: some View {
        ContactList(folder: .all)
            .environmentObject(ContactStore())
    }
}
