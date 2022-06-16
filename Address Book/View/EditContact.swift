//
//  EditContact.swift
//  Address Book
//
//  Created by Fawzi Rifai on 09/05/2022.
//

import SwiftUI
import MapKit

struct EditContact: View {
    @Environment(\.dismiss) private var dismiss
    var completeionHandler: (Contact) -> Void
    @EnvironmentObject var contactStore: ContactStore
    @StateObject var locationManager: LocationManager
    var contact: Contact
    @State private var newData: Contact
    @State private var isPhoneLabelPickerPresented = false
    @State private var isEmailLabelPickerPresented = false
    @State private var selectedLabel: Int = 0
    @Binding var isEditingContact: Bool
    var body: some View {
        Form {
            Section(header: EditableContactImage(imageData: $newData.imageData)) {}
            Section {
                let lastName: Binding<String> = Binding {
                    newData.lastName ?? ""
                } set: {
                    newData.lastName = $0
                }
                let company: Binding<String> = Binding {
                    newData.company ?? ""
                } set: {
                    newData.company = $0
                }
                if contactStore.displayOrder == .firstNameLastName {
                    TextField("First name", text: $newData.firstName)
                        .textContentType(.givenName)
                    TextField("Last name", text: lastName)
                        .textContentType(.familyName)
                } else {
                    TextField("Last name", text: lastName)
                        .textContentType(.familyName)
                    TextField("First name", text: $newData.firstName)
                        .textContentType(.givenName)
                }
                TextField("Company", text: company)
            }
            .disableAutocorrection(true)
            Section {
                ForEach(Array(newData.phoneNumbers.dropLast().enumerated()), id: \.element.id) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(item.element.label ?? "") {
                            selectedLabel = item.offset
                            isPhoneLabelPickerPresented = true
                        }
                        TextField("Phone number", text: $newData.phoneNumbers[item.offset].value)
                    }
                    .padding(.vertical, 8)
                }
                .onMove {
                    newData.movePhoneNumbers(at: $0, to: $1)
                }
                .onDelete {
                    newData.removePhoneNumbers(at: $0)
                }
                HStack(spacing: 18) {
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation {
                            newData.addNewPhoneNumber()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Button(newData.phoneNumbers[newData.phoneNumbers.count - 1].label ?? "") {
                            selectedLabel = newData.phoneNumbers.count - 1
                            isPhoneLabelPickerPresented = true
                        }
                        TextField("Phone number", text: $newData.phoneNumbers[newData.phoneNumbers.count - 1].value)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .disableAutocorrection(true)
            .keyboardType(UIKit.UIKeyboardType.phonePad)
            .textContentType(.telephoneNumber)
            Section {
                ForEach(Array(newData.emailAddresses.dropLast().enumerated()), id: \.element.id) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(item.element.label ?? "") {
                            selectedLabel = item.offset
                            isEmailLabelPickerPresented = true
                        }
                        TextField("Email address", text: $newData.emailAddresses[item.offset].value)
                    }
                    .padding(.vertical, 8)
                }
                .onMove {
                    newData.moveEmailAddresses(at: $0, to: $1)
                }
                .onDelete {
                    newData.removeEmailAddresses(at: $0)
                }
                HStack(spacing: 18) {
                    Button {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation {
                            newData.addNewEmailAddress()
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Button(newData.emailAddresses[newData.emailAddresses.count - 1].label ?? "") {
                            selectedLabel = newData.emailAddresses.count - 1
                            isEmailLabelPickerPresented = true
                        }
                        TextField("Email address", text: $newData.emailAddresses[newData.emailAddresses.count - 1].value)
                    }
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            Section {
                let isMapPresented: Binding<Bool> = Binding {
                    locationManager.coordinateRegion != nil
                } set: {
                    if $0 == true {
                        locationManager.coordinateRegion = newData.coordinateRegion ?? MKCoordinateRegion()
                        locationManager.requestLocation()
                    }
                    else {
                        newData.latitude = nil
                        newData.longitude = nil
                        locationManager.coordinateRegion = nil
                    }
                }
                let strongCoordinateRegion: Binding<MKCoordinateRegion> = Binding {
                    locationManager.coordinateRegion ?? MKCoordinateRegion()
                } set: {
                    locationManager.coordinateRegion = $0
                    newData.latitude = $0.center.latitude
                    newData.longitude = $0.center.longitude
                }
                Toggle("Location", isOn: isMapPresented)
                if locationManager.coordinateRegion != nil {
                    ZStack {
                        Map(coordinateRegion: strongCoordinateRegion)
                        newData.image?
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
                    newData.birthday != nil
                } set: {
                    if $0 == true {
                        newData.birthday = contact.birthday ?? Date.now
                    }
                    else {
                        newData.birthday = nil
                    }
                }
                let strongBirthday: Binding<Date> = Binding {
                    newData.birthday ?? Date.now
                } set: {
                    newData.birthday = $0
                }
                Toggle("Birthday", isOn: isDatePickerPresented)
                if newData.birthday != nil {
                    DatePicker("Date", selection: strongBirthday, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                }
            }
            Section {
                let notes: Binding<String> = Binding {
                    newData.notes ?? ""
                } set: {
                    if $0.isTotallyEmpty {
                        newData.notes = nil
                    } else {
                        newData.notes = $0
                    }
                }
                ZStack(alignment: .topLeading) {
                    if newData.notes == nil {
                        Text("Notes")
                            .opacity(0.25)
                            .padding(.top, 7)
                        
                    }
                    TextEditor(text: notes)
                        .padding(.top, -1)
                        .padding(.leading, -5)
                        .frame(minHeight: 100)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    if isEditingContact {
                        isEditingContact.toggle()
                        contactStore.update(contact, with: newData)
                    } else {
                        dismiss()
                        contactStore.add(newData)
                        completeionHandler(newData)
                    }
                }
                .disabled(newData.firstName.isTotallyEmpty || contact == newData)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if isEditingContact {
                        UISelectionFeedbackGenerator().selectionChanged()
                        isEditingContact.toggle()
                    } else {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $isPhoneLabelPickerPresented) {
            LabelPicker(labeledValue: $newData.phoneNumbers[selectedLabel])
        }
        .sheet(isPresented: $isEmailLabelPickerPresented) {
            LabelPicker(labeledValue: $newData.emailAddresses[selectedLabel])
        }
    }
    
    init(contact: Contact, isEditingContact: Binding<Bool> = .constant(false), completeionHandler: @escaping (Contact) -> Void = {_ in}) {
        self.contact = contact
        self._isEditingContact = isEditingContact
        self.completeionHandler = completeionHandler
        self.contact.phoneNumbers.append(LabeledValue(type: .phone))
        self.contact.emailAddresses.append(LabeledValue(type: .email))
        self._newData = State(initialValue: self.contact)
        self._locationManager = StateObject(wrappedValue: LocationManager(coordinateRegion: contact.coordinateRegion))
    }
    
}

struct EditContact_Previews: PreviewProvider {
    static var previews: some View {
        EditContact(contact: .example, isEditingContact: .constant(true), completeionHandler: {_ in})
    }
}
