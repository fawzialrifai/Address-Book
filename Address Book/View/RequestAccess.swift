//
//  RequestAccess.swift
//  Address Book
//
//  Created by Fawzi Rifai on 20/06/2022.
//

import SwiftUI
import Contacts

struct RequestAccess: View {
    @EnvironmentObject var contactStore: ContactStore
    var body: some View {
        GeometryReader { geometryProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.largeTitle.bold())
                    Text("Contacts")
                        .font(.largeTitle.bold())
                    Text("Please allow Address Book access to add, edit, and manage your contacts.")
                        .font(.title)
                    Spacer()
                    Text("Your contacts are not shared with anyone and are kept locally on your device.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                            CNContactStore().requestAccess(for: .contacts) { success, _ in
                                DispatchQueue.main.async {
                                    if success {
                                        contactStore.isAuthorized = true
                                        contactStore.fetchContacts()
                                    } else {
                                        contactStore.isAuthorized = false
                                    }
                                }
                            }
                        } else if CNContactStore.authorizationStatus(for: .contacts) == .denied {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    } label: {
                        Text("Allow")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .background(.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.top, 8)
                }
                .padding()
                .frame(minHeight: geometryProxy.size.height)
            }
            .clipped()
        }
        .background(.contactsBackgroundColor)
    }
}

struct RequestAccess_Previews: PreviewProvider {
    static var previews: some View {
        RequestAccess()
            .previewInterfaceOrientation(.portrait)
    }
}
