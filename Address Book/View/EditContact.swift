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
    @State private var isLocationAlertPresented = false
    @StateObject var locationManager: LocationManager
    var contact: Contact
    @State private var newData: Contact
    @State private var selectedLabel: LabeledValue? = nil
    @Binding var isEditingContact: Bool
    var body: some View {
        Form {
            Section(header: ContactHeader(contact: $newData, isEditing: true)) {}
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
                ForEach(Array(newData.phoneNumbers.enumerated()), id: \.element.id) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(item.element.label) {
                            selectedLabel = item.element
                        }
                        TextField("Phone number", text: $newData.phoneNumbers[item.offset].value)
                    }
                    .padding(.vertical, 8)
                }
                .onMove {
                    newData.movePhoneNumbers(at: $0, to: $1)
                }
                .onDelete {
                    UISelectionFeedbackGenerator().selectionChanged()
                    newData.removePhoneNumbers(at: $0)
                }
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation {
                        newData.addNewPhoneNumber()
                    }
                } label: {
                    HStack(spacing: 18) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                        Text("New Phone")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .disableAutocorrection(true)
            .keyboardType(UIKit.UIKeyboardType.phonePad)
            .textContentType(.telephoneNumber)
            Section {
                ForEach(Array(newData.emailAddresses.enumerated()), id: \.element.id) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        Button(item.element.label) {
                            selectedLabel = item.element
                        }
                        TextField("Email address", text: $newData.emailAddresses[item.offset].value)
                    }
                    .padding(.vertical, 8)
                }
                .onMove {
                    newData.moveEmailAddresses(at: $0, to: $1)
                }
                .onDelete {
                    UISelectionFeedbackGenerator().selectionChanged()
                    newData.removeEmailAddresses(at: $0)
                }
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    withAnimation {
                        newData.addNewEmailAddress()
                    }
                } label: {
                    HStack(spacing: 18) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.multicolor)
                        Text("New Email")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .disableAutocorrection(true)
            .autocapitalization(.none)
            Section {
                let isMapPresented: Binding<Bool> = Binding {
                    return newData.coordinateRegion != nil || locationManager.coordinateRegion != nil
                } set: {
                    if $0 == true {
                        if locationManager.isAuthorized {
                            locationManager.coordinateRegion = MKCoordinateRegion()
                            locationManager.requestLocation()
                        } else {
                            isLocationAlertPresented = true
                        }
                    }
                    else {
                        newData.latitude = nil
                        newData.longitude = nil
                        locationManager.coordinateRegion = nil
                    }
                }
                let strongCoordinateRegion: Binding<MKCoordinateRegion> = Binding {
                    if isEditingContact {
                        if newData.coordinateRegion == nil {
                            return locationManager.coordinateRegion ?? MKCoordinateRegion()
                        } else {
                            return newData.coordinateRegion!
                        }
                    } else {
                        return locationManager.coordinateRegion ?? MKCoordinateRegion()
                    }
                } set: {
                    if isEditingContact {
                        if newData.coordinateRegion == nil {
                            locationManager.coordinateRegion = $0
                            newData.latitude = $0.center.latitude
                            newData.longitude = $0.center.longitude
                        } else {
                            newData.latitude = $0.center.latitude
                            newData.longitude = $0.center.longitude
                        }
                    } else {
                        locationManager.coordinateRegion = $0
                        newData.latitude = $0.center.latitude
                        newData.longitude = $0.center.longitude
                    }
                }
                Toggle("Location", isOn: isMapPresented)
                if newData.coordinateRegion != nil || locationManager.coordinateRegion != nil {
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
                        newData.birthday = Calendar.current.startOfDay(for: contact.birthday ?? Date.now)
                    }
                    else {
                        newData.birthday = nil
                    }
                }
                let strongBirthday: Binding<Date> = Binding {
                    newData.birthday ?? Date.now
                } set: {
                    newData.birthday = Calendar.current.startOfDay(for: $0)
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
        .alert("Cannot Access Location", isPresented: $isLocationAlertPresented) {
            Button("OK") {}
        } message: {
            
        }
        .sheet(item: $selectedLabel) { strongLabel in
            if strongLabel.type == .phone {
                if let index = newData.phoneNumbers.firstIndex(of: strongLabel) {
                    let labelBinding: Binding<LabeledValue> = Binding {
                        newData.phoneNumbers[index]
                    } set: {
                        newData.phoneNumbers[index] = $0
                    }
                    LabelPicker(labeledValue: labelBinding)
                }
            } else if strongLabel.type == .email {
                if let index = newData.emailAddresses.firstIndex(of: strongLabel) {
                    let labelBinding: Binding<LabeledValue> = Binding {
                        newData.emailAddresses[index]
                    } set: {
                        newData.emailAddresses[index] = $0
                    }
                    LabelPicker(labeledValue: labelBinding)
                }
            }
        }
    }
    
    init(contact: Contact, isEditingContact: Binding<Bool> = .constant(false), completeionHandler: @escaping (Contact) -> Void = {_ in}) {
        self.contact = contact
        self._isEditingContact = isEditingContact
        self.completeionHandler = completeionHandler
        self._newData = State(initialValue: self.contact)
        self._locationManager = StateObject(wrappedValue: LocationManager(coordinateRegion: contact.coordinateRegion))
    }
    
}

struct EditContact_Previews: PreviewProvider {
    static var previews: some View {
        EditContact(contact: .example, isEditingContact: .constant(true), completeionHandler: {_ in})
    }
}
