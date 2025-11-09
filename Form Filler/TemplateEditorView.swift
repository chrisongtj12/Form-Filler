//
//  TemplateEditorView.swift
//  Speedoc Clinical Notes
//
//  WYSIWYG editor for template field positioning
//

import SwiftUI

#if os(iOS)
import UIKit // for NSTextAlignment in Picker tags
#elseif os(macOS)
import AppKit
#endif

struct TemplateEditorView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTemplateIndex = 0
    @State private var selectedFieldID: UUID?
    @State private var showingFieldEditor = false
    @State private var snapToGrid = false
    @State private var scale: CGFloat = 1.0
    
    var selectedTemplate: Template? {
        guard selectedTemplateIndex < appState.templates.count else { return nil }
        return appState.templates[selectedTemplateIndex]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Template picker
            Picker("Template", selection: $selectedTemplateIndex) {
                ForEach(appState.templates.indices, id: \.self) { index in
                    Text(appState.templates[index].name).tag(index)
                }
            }
            .pickerStyle(.menu)
            .padding()
            
            if let template = selectedTemplate {
                // Canvas with background and draggable fields
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        if let image = PlatformImage.swiftUIImage(named: template.backgroundImageName) {
                            image
                                .resizable()
                                .scaledToFit()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 794, height: 1123) // A4 size in points
                                .overlay(
                                    Text("Image not found:\n\(template.backgroundImageName)")
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.red)
                                )
                        }
                        
                        ForEach(template.fields.indices, id: \.self) { fieldIndex in
                            FieldOverlay(
                                field: $appState.templates[selectedTemplateIndex].fields[fieldIndex],
                                isSelected: appState.templates[selectedTemplateIndex].fields[fieldIndex].id == selectedFieldID,
                                snapToGrid: snapToGrid,
                                onTap: {
                                    selectedFieldID = appState.templates[selectedTemplateIndex].fields[fieldIndex].id
                                    showingFieldEditor = true
                                },
                                onPositionChange: {
                                    appState.saveTemplates()
                                }
                            )
                        }
                    }
                    .scaleEffect(scale)
                }
                .background(
                    Group {
                        #if os(iOS)
                        Color(UIColor.systemBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                )
                
                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Toggle("Snap to Grid", isOn: $snapToGrid)
                        
                        Spacer()
                        
                        HStack {
                            Button(action: { scale = max(0.5, scale - 0.1) }) {
                                Image(systemName: "minus.magnifyingglass")
                            }
                            Text("\(Int(scale * 100))%")
                                .frame(width: 60)
                            Button(action: { scale = min(2.0, scale + 0.1) }) {
                                Image(systemName: "plus.magnifyingglass")
                            }
                        }
                    }
                    
                    HStack {
                        Button("Add Field") {
                            addField()
                        }
                        
                        Spacer()
                        
                        Button("Save") {
                            appState.saveTemplates()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(
                    Group {
                        #if os(iOS)
                        Color(UIColor.systemBackground)
                        #elseif os(macOS)
                        Color(nsColor: .windowBackgroundColor)
                        #endif
                    }
                )
            }
        }
        .navigationTitle("Template Editor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFieldEditor) {
            if let fieldIndex = appState.templates[selectedTemplateIndex].fields.firstIndex(where: { $0.id == selectedFieldID }) {
                FieldEditorSheet(
                    field: $appState.templates[selectedTemplateIndex].fields[fieldIndex],
                    isPresented: $showingFieldEditor,
                    onDelete: {
                        appState.templates[selectedTemplateIndex].fields.remove(at: fieldIndex)
                        appState.saveTemplates()
                        showingFieldEditor = false
                        selectedFieldID = nil
                    }
                )
            }
        }
    }
    
    private func addField() {
        let newField = TemplateField(
            key: "new.field",
            label: "New Field",
            kind: .text,
            frame: CGRectCodable(x: 100, y: 100, width: 200, height: 30),
            fontSize: 12,
            alignment: .left,
            placeholder: nil
        )
        appState.templates[selectedTemplateIndex].fields.append(newField)
        appState.saveTemplates()
    }
}

// MARK: - Field Overlay

struct FieldOverlay: View {
    @Binding var field: TemplateField
    let isSelected: Bool
    let snapToGrid: Bool
    let onTap: () -> Void
    let onPositionChange: () -> Void
    
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        Rectangle()
            .stroke(isSelected ? Color.blue : Color.green, lineWidth: 2)
            .background(Color.blue.opacity(isSelected ? 0.2 : 0.1))
            .frame(width: field.frame.width, height: field.frame.height)
            .overlay(
                VStack {
                    Text(field.label)
                        .font(.system(size: 10))
                        .foregroundColor(.black)
                        .lineLimit(1)
                    
                    if isSelected {
                        Text("x:\(Int(field.frame.x)) y:\(Int(field.frame.y))")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                        Text("w:\(Int(field.frame.width)) h:\(Int(field.frame.height))")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                    }
                }
            )
            .position(x: field.frame.x + field.frame.width / 2,
                      y: field.frame.y + field.frame.height / 2)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        var newX = field.frame.x + value.translation.width - dragOffset.width
                        var newY = field.frame.y + value.translation.height - dragOffset.height
                        
                        if snapToGrid {
                            newX = round(newX / 10) * 10
                            newY = round(newY / 10) * 10
                        }
                        
                        field.frame.x = max(0, newX)
                        field.frame.y = max(0, newY)
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        dragOffset = .zero
                        onPositionChange()
                    }
            )
            .onTapGesture {
                onTap()
            }
    }
}

// MARK: - Field Editor Sheet

struct FieldEditorSheet: View {
    @Binding var field: TemplateField
    @Binding var isPresented: Bool
    let onDelete: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Field Properties")) {
                    TextField("Label", text: $field.label)
                    TextField("Key", text: $field.key)
                    TextField("Placeholder", text: Binding(
                        get: { field.placeholder ?? "" },
                        set: { field.placeholder = $0.isEmpty ? nil : $0 }
                    ))
                    
                    Picker("Type", selection: $field.kind) {
                        Text("Text").tag(FieldKind.text)
                        Text("Multiline").tag(FieldKind.multiline)
                        Text("Date/Time").tag(FieldKind.datetime)
                        Text("Picker").tag(FieldKind.picker)
                    }
                }
                
                Section(header: Text("Position & Size")) {
                    HStack {
                        Text("X")
                        Spacer()
                        TextField(
                            "X",
                            value: Binding(
                                get: { Double(field.frame.x) },
                                set: { field.frame.x = CGFloat($0) }
                            ),
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Y")
                        Spacer()
                        TextField(
                            "Y",
                            value: Binding(
                                get: { Double(field.frame.y) },
                                set: { field.frame.y = CGFloat($0) }
                            ),
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Width")
                        Spacer()
                        TextField(
                            "Width",
                            value: Binding(
                                get: { Double(field.frame.width) },
                                set: { field.frame.width = CGFloat($0) }
                            ),
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Height")
                        Spacer()
                        TextField(
                            "Height",
                            value: Binding(
                                get: { Double(field.frame.height) },
                                set: { field.frame.height = CGFloat($0) }
                            ),
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                }
                
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        TextField(
                            "Size",
                            value: Binding(
                                get: { Double(field.fontSize) },
                                set: { field.fontSize = CGFloat($0) }
                            ),
                            format: .number.precision(.fractionLength(0...2))
                        )
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                    }
                    
                    Picker("Alignment", selection: $field.alignment) {
                        Text("Left").tag(NSTextAlignment.left)
                        Text("Center").tag(NSTextAlignment.center)
                        Text("Right").tag(NSTextAlignment.right)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: onDelete) {
                        HStack {
                            Spacer()
                            Text("Delete Field")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview("Template Editor") {
    NavigationView {
        TemplateEditorView()
            .environmentObject(AppState())
    }
}

#Preview("Field Editor Sheet") {
    FieldEditorSheet(
        field: .constant(TemplateField(
            key: "patient.name",
            label: "Patient Name",
            kind: .text,
            frame: CGRectCodable(x: 100, y: 100, width: 200, height: 30),
            fontSize: 12,
            alignment: .left,
            placeholder: "Enter name"
        )),
        isPresented: .constant(true),
        onDelete: {}
    )
}

