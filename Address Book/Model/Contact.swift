//
//  Contact.swift
//  Address Book
//
//  Created by Fawzi Rifai on 05/05/2022.
//

import MapKit
import SwiftUI

struct Contact: Identifiable, Codable, Equatable {
    var id = UUID()
    var firstName = ""
    var lastName: String?
    var company: String?
    var phoneNumbers = [Phone]()
    var emailAddresses = [Email]()
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    var birthday: Date?
    var notes: String?
    var imageData: Data?
    var isMyCard = false
    var isEmergencyContact = false
    var isFavorite = false
    static let example = Contact(firstName: "Fawzi", lastName: "Rifai", company: "Apple")
}

extension Contact {
    
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var coordinateRegion: MKCoordinateRegion? {
        guard let coordinate = coordinate else {
            return nil
        }
        return MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
    }
    
    var mapURL: URL? {
        if let latitude = latitude, let longitude = longitude {
            if let lastName = lastName {
                return URL(string: "maps://?q=\(firstName)+\(lastName)&ll=\(latitude),\(longitude)")
            } else {
                return URL(string: "maps://?q=\(firstName)&ll=\(latitude),\(longitude)")
            }
        } else {
            return nil
        }
    }
    
    var image: Image {
        guard let imageData = imageData else {
            return Image(systemName: "person.crop.circle.fill")
        }
        return Image(uiImage: UIImage(data: imageData)!)
    }
    
    var qrShareableData: Data? {
        var qrShareableContact = self
        qrShareableContact.imageData = nil
        qrShareableContact.isMyCard = false
        qrShareableContact.isEmergencyContact = false
        qrShareableContact.isFavorite = false
        do {
            return try JSONEncoder().encode(qrShareableContact)
        } catch {
            return nil
        }
    }
    
}

extension Contact {
    
    func firstLetter(sortOrder: Order) -> String {
        if sortOrder == .firstNameLastName {
            return String(firstName.first!)
        } else {
            if let lastName = lastName {
                return String(lastName.first!)
            } else {
                return String(firstName.first!)
            }
        }
    }
    
    func fullName(displayOrder: Order) -> String {
        guard let lastName = lastName else {
            return firstName
        }
        if displayOrder == .firstNameLastName {
            return firstName + " " + lastName
        } else {
            return lastName + " " + firstName
        }
    }
    
}
