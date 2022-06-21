//
//  LabelPicker.swift
//  Address Book
//
//  Created by Fawzi Rifai on 12/05/2022.
//

import SwiftUI

struct LabelPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var labeledValue: LabeledValue
    @State private var selectedLabel: String
    @State private var customLabel: String
    @FocusState private var isCustomLabelFocused: Bool
    var body: some View {
        NavigationView {
            List {
                ForEach(labeledValue.defaultLabels, id: \.self) { label in
                    Button {
                        selectedLabel = label
                        isCustomLabelFocused = false
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
                Section {
                    HStack {
                        TextField("Custom label", text: $customLabel)
                            .focused($isCustomLabelFocused)
                            .onTapGesture  {
                                isCustomLabelFocused = true
                                selectedLabel = customLabel
                            }
                            .onChange(of: customLabel) { newValue in
                                selectedLabel = newValue
                            }
                        Spacer()
                        if selectedLabel == customLabel && !labeledValue.defaultLabels.contains(customLabel) {
                            Image(systemName: "checkmark")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationBarTitle("Label", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        labeledValue.label = selectedLabel
                        if !labeledValue.defaultLabels.contains(customLabel) {
                            labeledValue.customLabel = customLabel
                        }
                        dismiss()
                    }
                    .disabled(selectedLabel == customLabel && customLabel.isTotallyEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    init(labeledValue: Binding<LabeledValue>) {
        self._labeledValue = labeledValue
        _selectedLabel = State(initialValue: labeledValue.label.wrappedValue)
        _customLabel = State(initialValue: labeledValue.customLabel.wrappedValue)
    }
}

struct LabelPicker_Previews: PreviewProvider {
    static var previews: some View {
        LabelPicker(labeledValue: .constant(LabeledValue(label: "Mobile", type: .phone)))
    }
}
