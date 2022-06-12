//
//  EditContact.swift
//  Address Book
//
//  Created by Fawzi Rifai on 09/05/2022.
//

import SwiftUI
import MapKit
import Contacts

struct EditContact: View {
    @Environment(\.dismiss) private var dismiss
    var completeionHandler: (Contact) -> Void
    @EnvironmentObject var contactStore: ContactStore
    @State private var firstName: String
    @State private var lastName: String
    @State private var company: String
    @State private var phoneNumbers: [Phone]
    @State private var emailAddresses: [Email]
    @Binding var coordinateRegion: MKCoordinateRegion?
    @StateObject var locationManager: LocationManager
    @State private var birthday: Date?
    @State private var notes: String
    @State private var imageData: Data?
    @State private var isLabelPickerPresented = false
    @State private var isEmailLabelPickerPresented = false
    @State private var selectedIndex: Int = 0
    var image: Image {
        guard let imageData = imageData else {
            return Image(systemName: "person.crop.circle.fill")
        }
        return Image(uiImage: UIImage(data: imageData)!)
    }
    @Binding var isEditingContact: Bool
    var isContactEdited: Bool {
        contact.firstName != firstName ||
        contact.lastName != lastName.optional ||
        contact.company != company.optional ||
        contact.phoneNumbers != phoneNumbers.dropLast().filter({ !$0.value.isTotallyEmpty }) ||
        contact.emailAddresses != emailAddresses.dropLast().filter({ !$0.value.isTotallyEmpty }) ||
        contact.latitude != locationManager.coordinateRegion?.center.latitude ||
        contact.longitude != locationManager.coordinateRegion?.center.longitude ||
        contact.birthday != birthday ||
        contact.notes != notes.optional ||
        contact.imageData != imageData
    }
    var contact: Contact
    var body: some View {
        Form {
            Section(header: EditableContactImage(imageData: $imageData)) {}
            Section {
                if contactStore.displayOrder == .firstNameLastName {
                    TextField("First name", text: $firstName)
                        .disableAutocorrection(true)
                    TextField("Last name", text: $lastName)
                        .disableAutocorrection(true)
                } else {
                    TextField("Last name", text: $lastName)
                        .disableAutocorrection(true)
                    TextField("First name", text: $firstName)
                        .disableAutocorrection(true)
                }
                TextField("Company", text: $company)
                    .disableAutocorrection(true)
            }
            Section {
                ForEach(0 ..< phoneNumbers.count - 1, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(phoneNumbers[index].label ?? "") {
                            selectedIndex = index
                            isLabelPickerPresented = true
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        TextField("Phone", text: $phoneNumbers[index].value)
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: removePhoneNumbers)
                .onMove(perform: movePhoneNumbers)
                HStack(spacing: 18) {
                    Button(action: addPhoneNumber) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    VStack(alignment: .leading, spacing: 0) {
                        Button(phoneNumbers[phoneNumbers.count - 1].label ?? "") {
                            selectedIndex = phoneNumbers.count - 1
                            isLabelPickerPresented = true
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        TextField("Phone", text: $phoneNumbers[phoneNumbers.count - 1].value)
                            .keyboardType(.phonePad)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                ForEach(0 ..< emailAddresses.count - 1, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(emailAddresses[index].label ?? "") {
                            selectedIndex = index
                            isEmailLabelPickerPresented = true
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        TextField("Email", text: $emailAddresses[index].value)
                    }
                    .padding(.vertical, 8)
                }
                .onDelete(perform: removeEmailAddresses)
                .onMove(perform: moveEmailAddresses)
                HStack(spacing: 18) {
                    Button(action: addEmailAddress) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    VStack(alignment: .leading, spacing: 0) {
                        Button(emailAddresses[emailAddresses.count - 1].label ?? "") {
                            selectedIndex = emailAddresses.count - 1
                            isEmailLabelPickerPresented = true
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        TextField("Email", text: $emailAddresses[emailAddresses.count - 1].value)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                    }
                }
                .padding(.vertical, 8)
            }
            Section {
                let isMapPresented: Binding<Bool> = Binding {
                    locationManager.coordinateRegion != nil
                } set: {
                    if $0 == true {
                        locationManager.coordinateRegion = contact.coordinateRegion ?? MKCoordinateRegion()
                        locationManager.requestLocation()
                    }
                    else {
                        locationManager.coordinateRegion = nil
                    }
                }
                let strongCoordinateRegion: Binding<MKCoordinateRegion> = Binding {
                    locationManager.coordinateRegion ?? MKCoordinateRegion()
                } set: {
                    locationManager.coordinateRegion = $0
                }
                Toggle("Location", isOn: isMapPresented)
                if locationManager.coordinateRegion != nil {
                    ZStack {
                        Map(coordinateRegion: strongCoordinateRegion)
                        image
                            .resizable()
                            .scaledToFill()
                            .foregroundStyle(.white, .gray)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(lineWidth: 2).foregroundColor(.white))
                            .shadow(radius: 1)
                    }
                    .listRowInsets(EdgeInsets())
                    .frame(height: 200)
                }
            }
            Section {
                let isDatePickerPresented: Binding<Bool> = Binding {
                    birthday != nil
                } set: {
                    if $0 == true {
                        birthday = contact.birthday ?? Date.now
                    }
                    else {
                        birthday = nil
                    }
                }
                let strongBirthday: Binding<Date> = Binding {
                    birthday ?? Date.now
                } set: {
                    birthday = $0
                }
                Toggle("Birthday", isOn: isDatePickerPresented )
                if birthday != nil {
                    DatePicker("Date", selection: strongBirthday, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                }
            }
            Section {
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Notes")
                            .opacity(0.25)
                            .padding(.top, 7)
                        
                    }
                    TextEditor(text: $notes)
                        .padding(.top, -1)
                        .padding(.leading, -5)
                        .frame(minHeight: 100)
                }
            }
        }
        .sheet(isPresented: $isLabelPickerPresented) {
            LabelPicker(labeledValue: $phoneNumbers[selectedIndex].asParameter)
        }
        .sheet(isPresented: $isEmailLabelPickerPresented) {
            LabelPicker(labeledValue: $emailAddresses[selectedIndex].asParameter)
        }
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if isEditingContact {
                    Button("Done") {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        isEditingContact.toggle()
                        if let index = contactStore.contacts.firstIndex(of: contact) {
                            contactStore.contacts[index].firstName = firstName
                            contactStore.contacts[index].lastName = lastName.isTotallyEmpty ? nil : lastName
                            contactStore.contacts[index].company = company.isTotallyEmpty ? nil : company
                            contactStore.contacts[index].phoneNumbers = phoneNumbers.dropLast().filter({
                                !$0.value.isTotallyEmpty
                            })
                            contactStore.contacts[index].emailAddresses = emailAddresses.dropLast().filter({
                                !$0.value.isTotallyEmpty
                            })
                            contactStore.contacts[index].latitude = locationManager.coordinateRegion?.center.latitude
                            contactStore.contacts[index].longitude = locationManager.coordinateRegion?.center.longitude
                            coordinateRegion = locationManager.coordinateRegion ?? MKCoordinateRegion()
                            contactStore.contacts[index].birthday = birthday
                            contactStore.contacts[index].notes = notes.isTotallyEmpty ? nil : notes
                            contactStore.contacts[index].imageData = imageData
                            let store = CNContactStore()
                            let keys = [CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactOrganizationNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactBirthdayKey, CNContactImageDataKey] as [CNKeyDescriptor]
                            if let cnContact = try? store.unifiedContact(withIdentifier: contact.identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact {
                                cnContact.givenName = firstName
                                cnContact.familyName = lastName
                                cnContact.organizationName = company
                                for phoneNumber in phoneNumbers.dropLast().filter({
                                    !$0.value.isTotallyEmpty
                                }) {
                                    cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
                                }
                                for emailAddress in emailAddresses.dropLast().filter({
                                    !$0.value.isTotallyEmpty
                                }) {
                                    cnContact.emailAddresses.append(CNLabeledValue(label: emailAddress.label, value: emailAddress.value as NSString))
                                }
                                if let birthday = birthday {
                                    cnContact.birthday = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
                                }
                                cnContact.imageData = imageData
                                let saveRequest = CNSaveRequest()
                                saveRequest.update(cnContact)
                                try? store.execute(saveRequest)
                            }
                        }
                    }
                    .disabled(firstName.isTotallyEmpty || !isContactEdited)
                } else {
                    Button("Done") {
                        dismiss()
                        completeionHandler(newContact())
                    }
                    .disabled(firstName.isTotallyEmpty)
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditingContact {
                    Button("Cancel") {
                        UISelectionFeedbackGenerator().selectionChanged()
                        isEditingContact.toggle()
                    }
                } else {
                    Button("Cancel", action: dismiss.callAsFunction)
                }
                
            }
        }
    }
    init(contact: Contact, coordinateRegion: Binding<MKCoordinateRegion?>, isEditingContact: Binding<Bool>, completeionHandler: @escaping (Contact) -> Void) {
        self.contact = contact
        _imageData = State(initialValue: contact.imageData)
        _firstName = State(initialValue: contact.firstName)
        _lastName = State(initialValue: contact.lastName ?? "")
        _company = State(initialValue: contact.company ?? "")
        _phoneNumbers = State(initialValue: contact.phoneNumbers + [Phone()])
        _emailAddresses = State(initialValue: contact.emailAddresses + [Email()])
        _notes = State(initialValue: contact.notes ?? "")
        _birthday = State(initialValue: contact.birthday)
        _locationManager = StateObject(wrappedValue: LocationManager(coordinateRegion: contact.coordinateRegion))
        _coordinateRegion = coordinateRegion
        _isEditingContact = isEditingContact
        self.completeionHandler = completeionHandler
    }
    func addPhoneNumber() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation {
            phoneNumbers.append(Phone())
        }
    }
    func addEmailAddress() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation {
            emailAddresses.append(Email())
        }
    }
    func removePhoneNumbers(at offsets: IndexSet) {
        phoneNumbers.remove(atOffsets: offsets)
    }
    func movePhoneNumbers(at offsets: IndexSet, to index: Int) {
        phoneNumbers.move(fromOffsets: offsets, toOffset: index)
    }
    func removeEmailAddresses(at offsets: IndexSet) {
        emailAddresses.remove(atOffsets: offsets)
    }
    func moveEmailAddresses(at offsets: IndexSet, to index: Int) {
        emailAddresses.move(fromOffsets: offsets, toOffset: index)
    }
    func removePhoneNumber(at index: Int) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        _ = withAnimation {
            phoneNumbers.remove(at: index)
        }
    }
    func removeEmailAddress(at index: Int) {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        _ = withAnimation {
            emailAddresses.remove(at: index)
        }
    }
    func newContact() -> Contact {
        var contact = Contact()
        contact.isMyCard = self.contact.isMyCard
        contact.firstName = firstName
        contact.lastName = lastName.isTotallyEmpty ? nil : lastName
        contact.company = company.isTotallyEmpty ? nil : company
        contact.phoneNumbers = phoneNumbers.dropLast().filter({
            !$0.value.isTotallyEmpty
        })
        contact.emailAddresses = emailAddresses.dropLast().filter({
            !$0.value.isTotallyEmpty
        })
        contact.latitude = locationManager.coordinateRegion?.center.latitude
        contact.longitude = locationManager.coordinateRegion?.center.longitude
        contact.birthday = birthday
        contact.notes = notes.isTotallyEmpty ? nil : notes
        contact.imageData = imageData
        if !contact.isMyCard {
            let cnContact = CNMutableContact()
            contact.identifier = cnContact.identifier
            cnContact.givenName = firstName
            cnContact.familyName = lastName
            cnContact.organizationName = company
            for phoneNumber in phoneNumbers.dropLast().filter({
                !$0.value.isTotallyEmpty
            }) {
                cnContact.phoneNumbers.append(CNLabeledValue(label: phoneNumber.label, value: CNPhoneNumber(stringValue: phoneNumber.value)))
            }
            for emailAddress in emailAddresses.dropLast().filter({
                !$0.value.isTotallyEmpty
            }) {
                cnContact.emailAddresses.append(CNLabeledValue(label: emailAddress.label, value: emailAddress.value as NSString))
            }
            if let birthday = birthday {
                cnContact.birthday = Calendar.current.dateComponents([.year, .month, .day], from: birthday)
            }
            cnContact.imageData = imageData
            let store = CNContactStore()
            let saveRequest = CNSaveRequest()
            saveRequest.add(cnContact, toContainerWithIdentifier: nil)
            try? store.execute(saveRequest)
        }
        return contact
    }
}

struct EditContact_Previews: PreviewProvider {
    static var previews: some View {
        EditContact(contact: .example, coordinateRegion: .constant(MKCoordinateRegion()), isEditingContact: .constant(true), completeionHandler: {_ in})
    }
}
