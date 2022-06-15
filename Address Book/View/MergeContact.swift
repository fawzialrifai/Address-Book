//
//  MergeContact.swift
//  Address Book
//
//  Created by Fawzi Rifai on 15/06/2022.
//

import SwiftUI
import Contacts

struct MergeContact: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isMergeAlertPresented = false
    var companies = [String]()
    var phoneNumbers = [LabeledValue]()
    var emailAddresses = [LabeledValue]()
    var birthdays = [Date]()
    var images = [Data]()
    @EnvironmentObject var contactStore: ContactStore
    let duplicates: [Contact]
    @State private var mergedContact: Contact
    
    var body: some View {
        Form {
            if !images.isEmpty {
                Section("Image") {
                    GeometryReader { geometryProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 24) {
                                ForEach(images, id: \.self) { imageData in
                                        Button {
                                            if mergedContact.imageData == imageData {
                                                mergedContact.imageData = nil
                                            } else {
                                                mergedContact.imageData = imageData
                                            }
                                        } label: {
                                            Image(uiImage: UIImage(data: imageData)!)
                                                .resizable()
                                                .scaledToFill()
                                                .foregroundStyle(.white, .gray)
                                                .frame(width: 75, height: 75)
                                                .clipShape(Circle())
                                                .shadow(radius: 0.5)
                                                .padding(3)
                                                .overlay(Circle().stroke(lineWidth: mergedContact.imageData == imageData ? 3 : 0)).foregroundColor(.blue)
                                                .shadow(radius: 0.5)
                                        }
                                }
                            }
                            .padding(24)
                            .frame(minWidth: geometryProxy.size.width)
                        }
                    }
                    .listRowInsets(EdgeInsets())
                    .frame(minHeight: 129)
                }
            }
            if !companies.isEmpty {
                Section("Company") {
                    ForEach(companies, id: \.self) { company in
                            HStack {
                                Text(company)
                                Spacer()
                                Button {
                                    if mergedContact.company == company {
                                        mergedContact.company = nil
                                    } else {
                                        mergedContact.company = company
                                    }
                                } label: {
                                    if mergedContact.company == company {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                    }
                }
            }
            if !phoneNumbers.isEmpty {
                Section("Phone Numbers") {
                    ForEach(phoneNumbers) { phoneNumber in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(phoneNumber.label ?? "")
                                    Text(phoneNumber.value)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                Spacer()
                                Button {
                                    if mergedContact.phoneNumbers.contains(phoneNumber) {
                                        if let index = mergedContact.phoneNumbers.firstIndex(of: phoneNumber) {
                                            mergedContact.phoneNumbers.remove(at: index)
                                        }
                                    } else {
                                        mergedContact.phoneNumbers.append(phoneNumber)
                                    }
                                } label: {
                                    if mergedContact.phoneNumbers.contains(phoneNumber) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                    }
                }
            }
            if !emailAddresses.isEmpty {
                Section("Email Addresses") {
                        ForEach(emailAddresses) { emailAddress in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(emailAddress.label ?? "")
                                    Text(emailAddress.value)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                Spacer()
                                Button {
                                    if mergedContact.emailAddresses.contains(emailAddress) {
                                        if let index = mergedContact.emailAddresses.firstIndex(of: emailAddress) {
                                            mergedContact.emailAddresses.remove(at: index)
                                        }
                                    } else {
                                        mergedContact.emailAddresses.append(emailAddress)
                                    }
                                } label: {
                                    if mergedContact.emailAddresses.contains(emailAddress) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                }
            }
            if !birthdays.isEmpty {
                Section("Birthday") {
                    ForEach(birthdays, id: \.self) { birthday in
                            HStack {
                                Text(birthday.formatted(.dateTime.year().month().day()))
                                Spacer()
                                Button {
                                    if mergedContact.birthday == birthday {
                                        mergedContact.birthday = nil
                                    } else {
                                        mergedContact.birthday = birthday
                                    }
                                } label: {
                                    if mergedContact.birthday == birthday {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white, .blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(mergedContact.fullName(displayOrder: contactStore.displayOrder))
        .confirmationDialog("Merge Duplicates?", isPresented: $isMergeAlertPresented) {
            Button("Merge") {
                for contact in duplicates {
                    contactStore.delete(contact)
                }
                let cnContact = CNMutableContact()
                mergedContact.identifier = cnContact.identifier
                cnContact.givenName = mergedContact.firstName
                cnContact.familyName = mergedContact.lastName ?? ""
                cnContact.organizationName = mergedContact.company ?? ""
                for phoneNumber in mergedContact.phoneNumbers.dropLast().filter({
                    !$0.value.isTotallyEmpty
                }) {
                    cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
                }
                for emailAddress in mergedContact.emailAddresses.dropLast().filter({
                    !$0.value.isTotallyEmpty
                }) {
                    cnContact.emailAddresses.append(CNLabeledValue(label: emailAddress.label, value: emailAddress.value as NSString))
                }
                if let birthday = mergedContact.birthday {
                    cnContact.birthday = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
                }
                cnContact.imageData = mergedContact.imageData
                let store = CNContactStore()
                let saveRequest = CNSaveRequest()
                saveRequest.add(cnContact, toContainerWithIdentifier: nil)
                try? store.execute(saveRequest)
                contactStore.contacts.append(mergedContact)
                contactStore.sortContacts()
                dismiss()
            }
        } message: {
            Text("Merging duplicate cards combines those with the same information into a single contact card.")
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Merge") {
                    isMergeAlertPresented = true
                }
            }
        }
    }
    init(duplicates: [Contact]) {
        self.duplicates = duplicates
        var newContact = Contact()
        for contact in duplicates {
            newContact.firstName = contact.firstName
            newContact.lastName = contact.lastName
            if let company = contact.company {
                if !companies.contains(company) {
                    companies.append(company)
                }
            }
            for phoneNumber in contact.phoneNumbers {
                if !phoneNumbers.contains(phoneNumber) {
                    phoneNumbers.append(phoneNumber)
                }
            }
            for emailAdress in contact.emailAddresses {
                if !emailAddresses.contains(emailAdress) {
                    emailAddresses.append(emailAdress)
                }
            }
            if let birthday = contact.birthday {
                if !birthdays.contains(birthday) {
                    birthdays.append(birthday)
                }
            }
            if let imageData = contact.imageData {
                if !images.contains(imageData) {
                    images.append(imageData)
                }
            }
        }
        newContact.company = companies.first
        newContact.phoneNumbers = phoneNumbers
        newContact.emailAddresses = emailAddresses
        newContact.birthday = birthdays.first
        newContact.imageData = images.first
        _mergedContact = State(initialValue: newContact)
    }
}

struct MergeFactory_Previews: PreviewProvider {
    static var previews: some View {
        MergeContact(duplicates: [])
    }
}
