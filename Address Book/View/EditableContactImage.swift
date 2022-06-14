//
//  EditableContactImage.swift
//  Address Book
//
//  Created by Fawzi Rifai on 14/05/2022.
//

import SwiftUI

struct EditableContactImage: View {
    @State private var isImagePickerPresented = false
    @Binding var imageData: Data?
    var image: Image? {
        guard let imageData = imageData else {
            return Image(systemName: "person.crop.circle.fill")
        }
        if let uiImage = UIImage(data: imageData) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                image?
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.white, .gray)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(radius: 0.5)
                if imageData != nil {
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        imageData = nil
                    } label: {
                        ZStack {
                            Image(systemName: "x.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white, .gray)
                            Image(systemName: "x.circle")
                                .font(.title2)
                                .foregroundStyle(.white, .white)
                        }
                        .shadow(radius: 0.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            Button(imageData == nil ? "Add Image" : "Edit Image") {
                isImagePickerPresented.toggle()
            }
            .font(.body)
            .textCase(nil)
            .sheet(isPresented: $isImagePickerPresented) {
                ImagePicker(imageData: $imageData)
            }
        }
    }
}
