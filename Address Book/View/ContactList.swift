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
            Color.contactsBackgroundColor.ignoresSafeArea()
            if viewModel.isFolderLocked {
                VStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Authentication Required")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Button("View \(viewModel.category.rawValue)", action: { viewModel.authenticate() })
                }
            } else {
                if viewModel.category == .unhidden || viewModel.categorizedContacts.isEmpty == false {
                    ScrollViewReader { scrollViewProxy in
                        ZStack {
                            if viewModel.category == .unhidden {
                                NavigationView {
                                    Contacts { contact in
                                        scrollViewProxy.scrollTo(contact.id, anchor: .center)
                                    }
                                }
                                if viewModel.isInitialsGridPresented {
                                    NavigationView {
                                        InitialsGrid(isInitialsPresented: $viewModel.isInitialsGridPresented, scrollViewProxy: scrollViewProxy)
                                            .zIndex(1)
                                    }
                                }
                            } else {
                                Contacts { contact in
                                    scrollViewProxy.scrollTo(contact.id, anchor: .center)
                                }
                                .safeAreaInset(edge: .bottom) {
                                    if (viewModel.category == .duplicates && !contactStore.duplicates.isEmpty) || (viewModel.category == .deleted && !contactStore.deletedContacts.isEmpty){
                                        BottomButton()
                                    }
                                }
                                if viewModel.isInitialsGridPresented {
                                    InitialsGrid(isInitialsPresented: $viewModel.isInitialsGridPresented, scrollViewProxy: scrollViewProxy)
                                        .zIndex(1)
                                }
                            }
                        }
                    }
                    .environmentObject(viewModel)
                } else if viewModel.category != .unhidden {
                    Text("No Contacts")
                        .foregroundColor(.secondary)
                        .font(.title2)
                }
            }
        }
        .navigationBarTitle(viewModel.category.rawValue)
    }
    init(folder: Category, isFolderLocked: Bool) {
        _viewModel = StateObject(wrappedValue: ContactListViewModel(folder: folder, isFolderLocked: isFolderLocked))
    }
}

struct Contacts: View {
    var onContactAdd: (Contact) -> Void
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        List {
            if viewModel.category == .unhidden {
                MyCardSection()
            }
            EmergencySection()
            FavoritesSection()
            FirstLettersSections()
        }
        .listStyle(InsetGroupedListStyle())
        .navigationBarTitle(viewModel.category.rawValue, displayMode: viewModel.category == .unhidden ? .large : .inline)
        .searchable(text: $viewModel.searchText, prompt: "Search for a contact")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.category == .unhidden {
                    Menu {
                        Button {
                            viewModel.isAddContactViewPresented.toggle()
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
                if viewModel.category == .unhidden {
                    Button("Manage") { viewModel.isManageContactsViewPresented.toggle() }
                }
            }
        }
        .sheet(isPresented: $viewModel.isManageContactsViewPresented) {
            ManageContacts()
        }
        .sheet(isPresented: $viewModel.isAddContactViewPresented) {
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
        .confirmationDialog("Merge Duplicates?", isPresented: $viewModel.isMergeAllDuplicatesDialogPresented) {
            Button("Merge All") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                contactStore.mergeAllDuplicates()
            }
        } message: {
            Text("Merging duplicate cards combines those with the same information into a single contact card.")
        }
        .confirmationDialog(viewModel.contactsToDelete.count > 1 ? "Delete Cards?" : "Delete Contact?", isPresented: $viewModel.isDeleteContactsDialogPresented) {
            Button("Delete", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation {
                    contactStore.moveToDeletedList(viewModel.contactsToDelete)
                }
                viewModel.contactsToDelete.removeAll()
            }
        } message: {
            if viewModel.isDeleteContactsDialogPresented {
                Text((viewModel.contactsToDelete.count > 1 ? "These cards" : viewModel.contactsToDelete[0].fullName(displayOrder: contactStore.displayOrder)) + " will be deleted and moved to the Recently Deleted folder.")
            }
        }
        .confirmationDialog("Delete All Permanently?", isPresented: $viewModel.isDeleteAllContactsDialogPresented) {
            Button("Delete All Permanently") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                contactStore.emptyRecentlyDeletedFolder()
            }
        } message: {
            Text("These contacts will be deleted permanently, This action cannot be undone.")
        }
        .confirmationDialog("Restore All?", isPresented: $viewModel.isRestoreAllContactsDialogPresented) {
            Button("Restore All") {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                contactStore.restoreAllDeletedContacts()
            }
        } message: {
            Text("These contacts will be restored and moved out of the Recently Deleted folder.")
        }
        .confirmationDialog("Permanently Delete Contact?", isPresented: $viewModel.isPermanentlyDeleteContactsDialogPresented) {
            Button("Delete Permanently", role: .destructive) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation {
                    contactStore.permanentlyDelete(viewModel.contactsToDelete)
                }
                viewModel.contactsToDelete.removeAll()
            }
        } message: {
            if viewModel.isPermanentlyDeleteContactsDialogPresented {
                Text("\(viewModel.contactsToDelete[0].fullName(displayOrder: contactStore.displayOrder)) will be deleted permanently, This action cannot be undone.")
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
                ContactRow(cards: [myCard])
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
        if !viewModel.emergencyContacts.isEmpty {
            Section(header: SectionHeader(view: AnyView(Image(systemName: "staroflife.fill")))) {
                ForEach(viewModel.emergencyContacts, id: \.[0].id) { cards in
                    ContactRow(cards: cards)
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
        if !viewModel.favorites.isEmpty {
            Section(header: SectionHeader(view: AnyView(Text("★")))) {
                ForEach(viewModel.favorites, id: \.[0].id) { cards in
                    ContactRow(cards: cards)
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
        ForEach(viewModel.initials, id: \.self) { letter in
            Section(header: SectionHeader(view: AnyView(Text(letter)))) {
                ForEach(viewModel.groupedContacts[letter] ?? [], id: \.[0].id) { cards in
                    ContactRow(cards: cards)
                }
            }
        }
    }
}

struct ContactRow: View {
    var cards: [Contact]
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        NavigationLink {
            if cards.count > 1 {
                MergeContact(duplicates: cards)
            } else {
                ContactDetails(contact: cards[0])
            }
        } label: {
            HStack {
                HStack {
                    ForEach(cards.prefix(3)) { card in
                        if let index = cards.firstIndex(of: card) {
                            ContactImage(contact: card)
                                .frame(width: 45, height: 45)
                                .padding(.leading, index == 0 ? 0 : -42)
                        }
                    }
                }
                .if(cards.count == 2) { view in
                    view.frame(width: 67)
                }
                VStack(alignment: .leading) {
                    Text(cards[0].fullName(displayOrder: contactStore.displayOrder))
                    Group {
                        if cards.count == 1 {
                            if cards[0].phoneNumbers.count > 0 {
                                Text(cards[0].phoneNumbers[0].value)
                            } else if cards[0].emailAddresses.count > 0 {
                                Text(cards[0].emailAddresses[0].value)
                            }
                        } else {
                            Text("\(cards.count) cards")
                        }
                    }
                    .font(Font.callout)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
        .contextMenu {
            if !cards.contains { $0.isMyCard } {
                if !cards.allSatisfy({ $0.phoneNumbers.count == 0 }) {
                    Menu {
                        ForEach(cards) { card in
                            ForEach(card.phoneNumbers) { phoneNumber in
                                Button("\(phoneNumber.label)\n\(phoneNumber.value)") {
                                    guard let phone = URL(string: "tel:\(phoneNumber.value.plainPhoneNumber)") else { return }
                                    UIApplication.shared.open(phone)
                                }
                            }
                        }
                    } label: {
                        Label("Call", systemImage: "phone")
                    }
                    Menu {
                        ForEach(cards) { card in
                            ForEach(card.phoneNumbers) { phoneNumber in
                                Button("\(phoneNumber.label)\n\(phoneNumber.value)") {
                                    guard let messages = URL(string: "tel:\(phoneNumber.value.plainPhoneNumber)") else { return }
                                    UIApplication.shared.open(messages)
                                }
                            }
                        }
                    } label: {
                        Label("Message", systemImage: "message")
                    }
                }
                if !cards.allSatisfy({ $0.emailAddresses.count == 0 }) {
                    Menu {
                        ForEach(cards) { card in
                            ForEach(card.emailAddresses) { emailAddress in
                                Button("\(emailAddress.label)\n\(emailAddress.value)") {
                                    guard let mail = URL(string: "tel:\(emailAddress.value)") else { return }
                                    UIApplication.shared.open(mail)
                                }
                            }
                        }
                    } label: {
                        Label("Mail", systemImage: "envelope")
                    }
                }
            }
        }
        .swipeActions(edge: .leading) {
            if !cards.allSatisfy({ $0.isMyCard }) {
                Button  {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation {
                        if cards.contains(where: { $0.isFavorite }) {
                            for card in cards {
                                contactStore.removeFromFavorites(card)
                            }
                        } else {
                            for card in cards {
                                if !card.isMyCard {
                                    contactStore.addToFavorites(card)
                                }
                            }
                        }
                    }
                } label: {
                    if cards.contains(where: { $0.isFavorite }) {
                        Label("Remove for Favorites", systemImage: "star.slash.fill")
                    } else {
                        Label("Add to Favorites", systemImage: "star.fill")
                    }
                }
                .tint(.yellow)
            }
        }
        .swipeActions(edge: .trailing) {
            if !cards.allSatisfy({ $0.isMyCard }) {
                Button  {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    viewModel.contactsToDelete = cards
                    if cards[0].isDeleted {
                        viewModel.isPermanentlyDeleteContactsDialogPresented.toggle()
                    } else {
                        viewModel.isDeleteContactsDialogPresented.toggle()
                    }
                } label: {
                    Label(cards[0].isDeleted ? "Delete Permanently" : "Delete", systemImage: "trash.fill")
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
            .shadow(radius: 1)
    }
}

struct BottomButton: View {
    @EnvironmentObject var viewModel: ContactListViewModel
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        if viewModel.category == .duplicates {
            HStack {
                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    viewModel.isMergeAllDuplicatesDialogPresented = true
                } label: {
                    Text("Merge All")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(20)
            }
            .background(Material.thinMaterial)
            .shadow(radius: 0.5)
        } else if viewModel.category == .deleted {
            VStack(spacing: 16) {
                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
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
                Button("Restore All") {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    viewModel.isRestoreAllContactsDialogPresented.toggle()
                }
                .padding(.bottom, 20)
            }
            .background(Material.thinMaterial)
            .shadow(radius: 0.5)
        }
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
                viewModel.isInitialsGridPresented.toggle()
            }
        } label: {
            view.frame(maxWidth: .infinity, alignment: .leading)
        }
        .tint(.secondary)
    }
}

struct ContactList_Previews: PreviewProvider {
    static var previews: some View {
        ContactList(folder: .unhidden, isFolderLocked: false)
            .environmentObject(ContactStore.shared)
    }
}
