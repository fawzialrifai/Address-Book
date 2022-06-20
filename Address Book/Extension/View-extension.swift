//
//  View-extension.swift
//  Address Book
//
//  Created by Fawzi Rifai on 20/06/2022.
//

import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
