//
//  CodeGenerator.swift
//  Address Book
//
//  Created by Fawzi Rifai on 15/05/2022.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct CodeGenerator: View {
    @Environment(\.dismiss) private var dismiss
    var contact: Contact
    @State var qrContact: Contact
    @State private var isCompanyIncluded = true
    @State private var isPhonesIncluded = true
    @State private var isEmailsIncluded = true
    @State private var isLocationIncluded = true
    @State private var isBirthdayIncluded = true
    @State private var isNotesIncluded = true
    var body: some View {
        NavigationView {
            Form {
                Section(header: QRCodeImage(qrContact: $qrContact)) {}
                Section("Include") {
                    Toggle("Image", isOn: .constant(false))
                        .disabled(true)
                    Toggle("Full Name", isOn: .constant(true))
                        .disabled(true)
                    Toggle("Company", isOn: $isCompanyIncluded)
                    Toggle("Phone Numbers", isOn: $isPhonesIncluded)
                    Toggle("Email Addresses", isOn: $isEmailsIncluded)
                    Toggle("Location", isOn: $isLocationIncluded)
                    Toggle("Birthday", isOn: $isBirthdayIncluded)
                    Toggle("Notes", isOn: $isNotesIncluded)
                }
                .onChange(of: isCompanyIncluded) {_ in
                    if isCompanyIncluded {
                        qrContact.company = contact.company
                    } else {
                        qrContact.company = nil
                    }
                }
                .onChange(of: isPhonesIncluded) {_ in
                    if isPhonesIncluded {
                        qrContact.phoneNumbers = contact.phoneNumbers
                    } else {
                        qrContact.phoneNumbers = []
                    }
                }
                .onChange(of: isEmailsIncluded) {_ in
                    if isEmailsIncluded {
                        qrContact.emailAddresses = contact.emailAddresses
                    } else {
                        qrContact.emailAddresses = []
                    }
                }
                .onChange(of: isLocationIncluded) {_ in
                    if isLocationIncluded {
                        qrContact.latitude = contact.latitude
                        qrContact.longitude = contact.longitude
                    } else {
                        qrContact.latitude = nil
                        qrContact.longitude = nil
                    }
                }
                .onChange(of: isBirthdayIncluded) {_ in
                    if isBirthdayIncluded {
                        qrContact.birthday = contact.birthday
                    } else {
                        qrContact.birthday = nil
                    }
                }
                .onChange(of: isNotesIncluded) {_ in
                    if isNotesIncluded {
                        qrContact.notes = contact.notes
                    } else {
                        qrContact.notes = nil
                    }
                }
            }
            .navigationTitle("QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
    init(contact: Contact) {
        self.contact = contact
        _qrContact = State(initialValue: contact)
    }
}

struct QRCodeImage: View {
    @Binding var qrContact: Contact
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    var body: some View {
        if let qrCode = generateQRCode(for: qrContact) {
            Image(uiImage: qrCode)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .padding(12)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 0.5)
                .frame(width: 150, height: 150)
                .frame(maxWidth: .infinity)
        }
    }
    func generateQRCode(for contact: Contact) -> UIImage? {
        guard let data = contact.qrShareableData else { return nil }
        filter.message = data
        if let outputImage = filter.outputImage {
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }
}

struct QRCodeGenerator_Previews: PreviewProvider {
    static var previews: some View {
        CodeGenerator(contact: .example)
    }
}
