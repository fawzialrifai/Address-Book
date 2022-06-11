//
//  ShapeStyle-extension.swift
//  Address Book
//
//  Created by Fawzi Rifai on 11/05/2022.
//

import SwiftUI

extension ShapeStyle where Self == Color {

    static var contactsBackgroundColor: Color {
        Color(UIColor { $0.userInterfaceStyle == .light ? UIColor(red: 0.937, green: 0.937, blue: 0.937, alpha: 1) : UIColor.systemBackground })
    }

}
