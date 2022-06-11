//
//  LabelPicker.swift
//  Address Book
//
//  Created by Fawzi Rifai on 12/05/2022.
//

import SwiftUI

struct LabelPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var labeledValue: ContactLabeledValue
    @State private var newLabel = ""
    @State private var selectedLabel: String?
    @State private var labels: [String]
    @State private var customLabels: [String]
    var body: some View {
        NavigationView {
            List {
                ForEach(labels, id: \.self) { label in
                    Button {
                        selectedLabel = label
                    } label: {
                        HStack {
                            Text(label)
                                .foregroundColor(.primary)
                            Spacer()
                            if label == selectedLabel {
                                Image(systemName: "checkmark")
                                    .font(.headline)
                            }
                        }
                    }
                }
                Section("Custom labels") {
                    ForEach(customLabels, id: \.self) { label in
                        Button {
                            selectedLabel = label
                        } label: {
                            HStack {
                                Text(label)
                                    .foregroundColor(.primary)
                                Spacer()
                                if label == selectedLabel {
                                    Image(systemName: "checkmark")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteLabels)
                    HStack {
                        TextField("Label", text: $newLabel)
                        Spacer()
                        Button {
                            withAnimation {
                                if customLabels.contains(newLabel) {
                                    newLabel.removeAll()
                                } else {
                                    customLabels.append(newLabel)
                                    newLabel.removeAll()
                                }
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        .disabled(newLabel.isTotallyEmpty)
                    }
                }
            }
            .navigationTitle("Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        labeledValue.customLabels = customLabels
                        labeledValue.label = selectedLabel
                        dismiss()
                    }
                    .disabled(selectedLabel == nil || labeledValue.label == selectedLabel)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        
    }
    init(labeledValue: Binding<ContactLabeledValue>) {
        self._labeledValue = labeledValue
        _selectedLabel = State(initialValue: labeledValue.label.wrappedValue)
        _labels = State(initialValue: labeledValue.availableLabels.wrappedValue)
        _customLabels = State(initialValue: labeledValue.customLabels.wrappedValue)
    }
    func deleteLabels(at offsets: IndexSet) {
        withAnimation {
            if selectedLabel == customLabels[offsets.first!] {
                selectedLabel = nil
            }
            customLabels.remove(atOffsets: offsets)
        }
    }
}

//struct LabelPicker_Previews: PreviewProvider {
//    static var previews: some View {
//        LabelPicker(phone: .constant(Phone()))
//    }
//}
