//
//  InitialsGrid.swift
//  Address Book
//
//  Created by Fawzi Rifai on 08/05/2022.
//

import SwiftUI

struct InitialsGrid: View {
    var folder: Folder
    @EnvironmentObject var contactStore: ContactStore
    let scrollViewProxy: ScrollViewProxy?
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 75, maximum: 75))], spacing: 8) {
                        if !contactStore.emergencyContacts(in: folder).isEmpty {
                            LetterItem(scrollViewProxy: scrollViewProxy, id: "staroflife", view: AnyView(Image(systemName: "staroflife.fill")))
                        }
                        if !contactStore.favorites(in: folder).isEmpty {
                            LetterItem(scrollViewProxy: scrollViewProxy, id: "★", view: AnyView(Text("★")))
                        }
                        ForEach(contactStore.contactsDictionary(for: folder).keys.sorted(by: <), id: \.self) { letter in
                            LetterItem(scrollViewProxy: scrollViewProxy, id: letter, view: AnyView(Text(letter)))
                        }
                    }
                    .padding()
                    .frame(minHeight: proxy.size.height)
                }
                .background(.contactsBackgroundColor)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation {
                            contactStore.isInitialsGridPresented.toggle()
                        }
                    }
                }
            }
        }
    }
}

struct LetterItem: View {
    @EnvironmentObject var contactStore: ContactStore
    let scrollViewProxy: ScrollViewProxy?
    let id: String
    let view: AnyView
    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation {
                contactStore.isInitialsGridPresented.toggle()
                scrollViewProxy?.scrollTo(id, anchor: UnitPoint.center)
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                    .frame(height: 75)
                view.font(.title)
            }
        }
        .foregroundStyle(.secondary)
        .shadow(radius: 0.5)
    }
}

struct FirstLettersGrid_Previews: PreviewProvider {
    static var previews: some View {
        InitialsGrid(folder: .all, scrollViewProxy: nil)
    }
}
