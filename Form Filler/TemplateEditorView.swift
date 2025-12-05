//
//  TemplateEditorView.swift
//  Speedoc Clinical Notes
//
//  WYSIWYG editor for template field positioning
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

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

    // New: States for template add/delete/background actions
    @State private var showingAddTemplate = false
    @State private var showingDeleteAlert = false
    @State private var showingChangeBackground = false
    @State private var newTemplateName = ""
    @State private var newPageIndex = 1
    @State private var pickedBackgroundURL: URL?
    @State private var pickedChangeBgURL: URL?
    @State private var isPickingBackground = false
    @State private var isPickingChangeBackground = false
    @State private var addTemplateError: String?
    @State private var changeBgError: String?

#if os(iOS)
    @State private var showingDocumentPicker = false
    @State private var documentPickerForChange = false // false = add, true = change
#endif

    var selectedTemplate: Template? {
        guard selectedTemplateIndex < appState.templates.count else { return nil }
        return appState.templates[selectedTemplateIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top controls: Template picker + add/delete/change
            HStack {
                Picker("Template", selection: $selectedTemplateIndex) {
                    ForEach(appState.templates.indices, id: \.self) { index in
                        Text(appState.templates[index].name).tag(index)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                Button(action: {
#if os(iOS)
                    documentPickerForChange = false
                    showingDocumentPicker = true
#else
                    presentOpenPanel(forChange: false)
#endif
                }) {
                    Label("Add Template", systemImage: "plus")
                }

                if selectedTemplate != nil {
                    Button(action: {
#if os(iOS)
                        documentPickerForChange = true
                        showingDocumentPicker = true
#else
                        presentOpenPanel(forChange: true)
#endif
                    }) {
                        Label("Change Background", systemImage: "photo.on.rectangle")
                    }

                    Button(role: .destructive, action: {
                        showingDeleteAlert = true
                    }) {
                        Label("Delete Template", systemImage: "trash")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if let template = selectedTemplate {
                // Canvas with background and draggable fields
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        if let image = loadBackgroundSwiftUIImage(namedOrFilename: template.backgroundImageName) {
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
        // Field editing sheet
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
        // Add template prompts (iOS: file picker, then details prompt; macOS: open panel + prompt)
#if os(iOS)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(
                forChange: documentPickerForChange,
                onPick: { url in
                    if documentPickerForChange {
                        changeBackgroundImage(at: url)
                    } else {
                        addTemplateWithBackground(at: url)
                    }
                }
            )
        }
#endif
        .alert("Delete Template?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteTemplate()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let template = selectedTemplate {
                Text("Are you sure you want to delete \"\(template.name)\"?")
            } else {
                Text("No template selected.")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { addTemplateError != nil || changeBgError != nil },
            set: { _ in addTemplateError = nil; changeBgError = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(addTemplateError ?? changeBgError ?? "An error occurred.")
        }
    }

    // MARK: - Add/Remove/Change Template Actions

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

    private func deleteTemplate() {
        guard !appState.templates.isEmpty, selectedTemplateIndex < appState.templates.count else { return }
        appState.templates.remove(at: selectedTemplateIndex)
        if selectedTemplateIndex >= appState.templates.count {
            selectedTemplateIndex = max(0, appState.templates.count - 1)
        }
        appState.saveTemplates()
    }

    // MARK: - Background loading (cross-platform)

    private func loadBackgroundSwiftUIImage(namedOrFilename: String) -> Image? {
        // First try bundled/asset image
        if let asset = PlatformImage.swiftUIImage(named: namedOrFilename) {
            return asset
        }
        // Then try Documents directory file saved by editor
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documents.appendingPathComponent(namedOrFilename)
        #if os(iOS)
        if let uiImage = UIImage(contentsOfFile: fileURL.path) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(contentsOf: fileURL) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }

#if os(iOS)
    // Called after picking a file for new template background
    private func addTemplateWithBackground(at url: URL) {
        // Try to load image from PDF or as UIImage
        loadImageFromFile(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    // Prompt for new template name and page index
                    promptForNewTemplateName { name, page in
                        // Save image to documents, generate a unique name
                        let imageName = saveImageToDocuments(image: image)
                        let newTemplate = Template(
                            name: name,
                            backgroundImageName: imageName,
                            pageIndex: page,
                            fields: []
                        )
                        appState.templates.append(newTemplate)
                        appState.saveTemplates()
                        selectedTemplateIndex = appState.templates.count - 1
                    }
                case .failure(let error):
                    addTemplateError = "Failed to load background: \(error.localizedDescription)"
                }
            }
        }
    }

    // Called after picking a file for changing background
    private func changeBackgroundImage(at url: URL) {
        loadImageFromFile(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    guard selectedTemplateIndex < appState.templates.count else { return }
                    let imageName = saveImageToDocuments(image: image)
                    appState.templates[selectedTemplateIndex].backgroundImageName = imageName
                    appState.saveTemplates()
                case .failure(let error):
                    changeBgError = "Failed to load background: \(error.localizedDescription)"
                }
            }
        }
    }

    // Helper to show an alert with textfields (SwiftUI workaround), fallback to basic prompt
    private func promptForNewTemplateName(completion: @escaping (String, Int) -> Void) {
        let alert = UIAlertController(
            title: "New Template",
            message: "Enter a name and page index for the template",
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "Template Name" }
        alert.addTextField { tf in
            tf.placeholder = "Page Index"
            tf.keyboardType = .numberPad
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            let theName = alert.textFields?[0].text ?? "Untitled"
            let pageIndex = Int(alert.textFields?[1].text ?? "") ?? 1
            completion(theName, pageIndex)
        }))
        guard let root = UIApplication.shared.windows.first?.rootViewController else { return }
        root.present(alert, animated: true)
    }

    // Load background image from PDF or image file
    private func loadImageFromFile(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if url.pathExtension.lowercased() == "pdf" {
            // Render first page as image
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "PDF could not be loaded."])))
                return
            }
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            DispatchQueue.global(qos: .userInitiated).async {
                UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
                defer { UIGraphicsEndImageContext() }
                guard let ctx = UIGraphicsGetCurrentContext() else {
                    completion(.failure(NSError(domain: "TemplateEditor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context."])))
                    return
                }
                ctx.saveGState()
                // White background
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fill(CGRect(origin: .zero, size: size))
                // Draw PDF
                ctx.translateBy(x: 0, y: size.height)
                ctx.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx)
                ctx.restoreGState()
                if let img = UIGraphicsGetImageFromCurrentImageContext() {
                    completion(.success(img))
                } else {
                    completion(.failure(NSError(domain: "TemplateEditor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to render PDF page."])))
                }
            }
        } else {
            // Try as image
            if let image = UIImage(contentsOfFile: url.path) {
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type or not an image."])))
            }
        }
    }

    // Save UIImage to documents directory, returns unique filename
    private func saveImageToDocuments(image: UIImage) -> String {
        let filename = "template_bg_\(UUID().uuidString).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(filename)
        if let data = image.pngData() {
            try? data.write(to: url)
            return filename
        }
        return ""
    }

    // Document picker wrapper
    struct DocumentPickerView: UIViewControllerRepresentable {
        var forChange: Bool
        var onPick: (URL) -> Void

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let types: [UTType] = [.pdf, .image]
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
            picker.delegate = context.coordinator
            return picker
        }
        func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
        func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
        class Coordinator: NSObject, UIDocumentPickerDelegate {
            let parent: DocumentPickerView
            init(parent: DocumentPickerView) { self.parent = parent }
            func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
                if let url = urls.first {
                    parent.onPick(url)
                }
            }
        }
    }
#endif

#if os(macOS)
    // macOS: present NSOpenPanel for PDF or image, then add/change template background
    private func presentOpenPanel(forChange: Bool) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if forChange {
                changeBackgroundImage_macOS(at: url)
            } else {
                addTemplateWithBackground_macOS(at: url)
            }
        }
    }

    private func addTemplateWithBackground_macOS(at url: URL) {
        loadImageFromFile_macOS(url: url) { result in
            switch result {
            case .success(let image):
                promptForNewTemplateName_macOS { name, page in
                    let imageName = saveImageToDocuments_macOS(image: image)
                    let newTemplate = Template(
                        name: name,
                        backgroundImageName: imageName,
                        pageIndex: page,
                        fields: []
                    )
                    appState.templates.append(newTemplate)
                    appState.saveTemplates()
                    selectedTemplateIndex = appState.templates.count - 1
                }
            case .failure(let error):
                changeBgError = "Failed to load background: \(error.localizedDescription)"
            }
        }
    }

    private func changeBackgroundImage_macOS(at url: URL) {
        loadImageFromFile_macOS(url: url) { result in
            switch result {
            case .success(let image):
                guard selectedTemplateIndex < appState.templates.count else { return }
                let imageName = saveImageToDocuments_macOS(image: image)
                appState.templates[selectedTemplateIndex].backgroundImageName = imageName
                appState.saveTemplates()
            case .failure(let error):
                changeBgError = "Failed to load background: \(error.localizedDescription)"
            }
        }
    }

    private func loadImageFromFile_macOS(url: URL, completion: @escaping (Result<NSImage, Error>) -> Void) {
        if url.pathExtension.lowercased() == "pdf" {
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "PDF could not be loaded."])))
                return
            }
            let pageRect = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
            DispatchQueue.global(qos: .userInitiated).async {
                let image = NSImage(size: size)
                image.lockFocusFlipped(false)
                guard let ctx = NSGraphicsContext.current?.cgContext else {
                    image.unlockFocus()
                    completion(.failure(NSError(domain: "TemplateEditor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context."])))
                    return
                }
                // White background
                ctx.setFillColor(NSColor.white.cgColor)
                ctx.fill(CGRect(origin: .zero, size: size))
                // Draw PDF
                ctx.saveGState()
                ctx.translateBy(x: 0, y: size.height)
                ctx.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx)
                ctx.restoreGState()
                image.unlockFocus()
                completion(.success(image))
            }
        } else {
            if let image = NSImage(contentsOf: url) {
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type or not an image."])))
            }
        }
    }

    private func saveImageToDocuments_macOS(image: NSImage) -> String {
        let filename = "template_bg_\(UUID().uuidString).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(filename)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            return ""
        }
        try? data.write(to: url)
        return filename
    }

    private func promptForNewTemplateName_macOS(completion: @escaping (String, Int) -> Void) {
        // Simple synchronous prompt using NSAlert + accessory views
        let alert = NSAlert()
        alert.messageText = "New Template"
        alert.informativeText = "Enter a name and page index for the template"
        alert.alertStyle = .informational

        let nameField = NSTextField(string: "")
        nameField.placeholderString = "Template Name"

        let pageField = NSTextField(string: "1")
        pageField.placeholderString = "Page Index"

        let stack = NSStackView(views: [nameField, pageField])
        stack.orientation = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.setFrameSize(NSSize(width: 240, height: 48))

        alert.accessoryView = stack
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue.isEmpty ? "Untitled" : nameField.stringValue
            let page = Int(pageField.stringValue) ?? 1
            completion(name, page)
        }
    }
#endif
}

// MARK: - Field Overlay (unchanged)

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

// MARK: - Field Editor Sheet (unchanged)

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

