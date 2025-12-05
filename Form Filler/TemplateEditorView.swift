//
//  TemplateEditorView.swift
//  Speedoc Clinical Notes
//
//  Redesigned template editor:
//  Level 1: Text-based form editor (no background shown)
//  Level 2: Placement editor (background + draggable fields)
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

#if os(iOS)
import UIKit // for NSTextAlignment, UIImage, pickers
#elseif os(macOS)
import AppKit
#endif

// MARK: - Entry: Text-based Template Editor (Level 1)

struct TemplateEditorView: View {
    @EnvironmentObject var appState: AppState

    // Selection
    @State private var selectedTemplateID: UUID? = nil

    // Export
    @State private var showingPreview = false
    @State private var exportPDFData: Data?

    // Errors
    @State private var errorMessage: String?
    @State private var showingDeleteAlert = false

    // iOS document picker
    #if os(iOS)
    @State private var showingDocumentPicker = false
    @State private var isChangingBackground = false
    #endif

    // macOS open panel state not needed

    // Helpers
    private var selectedTemplateIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return appState.templates.firstIndex(where: { $0.id == id })
    }
    private var selectedTemplate: Template? {
        guard let idx = selectedTemplateIndex, appState.templates.indices.contains(idx) else { return nil }
        return appState.templates[idx]
    }

    var body: some View {
        Form {
            Section(header: Text("Template")) {
                // Template picker
                Picker("Select Template", selection: Binding(
                    get: { selectedTemplateID ?? appState.templates.first?.id },
                    set: { selectedTemplateID = $0 }
                )) {
                    ForEach(appState.templates) { t in
                        Text(t.name).tag(Optional(t.id))
                    }
                }
                .pickerStyle(.menu)

                // Rename
                if let idx = selectedTemplateIndex {
                    TextField("Template Name", text: Binding(
                        get: { appState.templates[idx].name },
                        set: { appState.templates[idx].name = $0; appState.saveTemplates() }
                    ))
                    .textInputAutocapitalization(.words)
                }

                // Page index
                if let idx = selectedTemplateIndex {
                    Stepper(value: Binding(
                        get: { appState.templates[idx].pageIndex },
                        set: { appState.templates[idx].pageIndex = $0; appState.saveTemplates() }
                    ), in: 1...99) {
                        Text("Page Index: \(appState.templates[idx].pageIndex)")
                    }
                }

                // Background controls (import/replace; normalized to A4)
                HStack {
                    if let t = selectedTemplate {
                        Text("Background: \(t.backgroundImageName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    } else {
                        Text("No background selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button {
                        #if os(iOS)
                        isChangingBackground = true
                        showingDocumentPicker = true
                        #else
                        presentOpenPanel(forChange: true)
                        #endif
                    } label: {
                        Label("Change Background", systemImage: "photo.on.rectangle")
                    }
                    .disabled(selectedTemplate == nil)
                }

                // Add new template (import background; normalized to A4)
                Button {
                    #if os(iOS)
                    isChangingBackground = false
                    showingDocumentPicker = true
                    #else
                    presentOpenPanel(forChange: false)
                    #endif
                } label: {
                    Label("Add Template (Import Background)", systemImage: "plus")
                }

                // Delete current template
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete Template", systemImage: "trash")
                }
                .disabled(selectedTemplate == nil)

                // Placement editor link
                if selectedTemplate != nil {
                    NavigationLink {
                        TemplatePlacementView(selectedTemplateID: selectedTemplateID)
                            .environmentObject(appState)
                    } label: {
                        Label("Open Text Placement", systemImage: "square.and.pencil")
                    }
                }

                // Export PDF (single page for selected template)
                Button {
                    exportSelectedTemplateAsPDF()
                } label: {
                    Label("Export PDF (This Template)", systemImage: "arrow.down.doc.fill")
                }
                .disabled(selectedTemplate == nil)
            }

            // Fields list
            if let idx = selectedTemplateIndex {
                Section(header:
                    HStack {
                        Text("Fields (\(appState.templates[idx].fields.count))")
                        Spacer()
                        Button {
                            addField(to: idx)
                        } label: {
                            Label("Add Field", systemImage: "plus.circle.fill")
                        }
                    }
                ) {
                    if appState.templates[idx].fields.isEmpty {
                        Text("No fields yet. Tap Add Field to create one.")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(appState.templates[idx].fields.indices, id: \.self) { fIndex in
                            FieldRowEditor(field: Binding(
                                get: { appState.templates[idx].fields[fIndex] },
                                set: { appState.templates[idx].fields[fIndex] = $0; appState.saveTemplates() }
                            )) {
                                appState.templates[idx].fields.remove(at: fIndex)
                                appState.saveTemplates()
                            }
                        }
                        .onMove { indices, newOffset in
                            appState.templates[idx].fields.move(fromOffsets: indices, toOffset: newOffset)
                            appState.saveTemplates()
                        }
                        .environment(\.editMode, .constant(.active)) // enable reordering UI
                    }
                }
            }
        }
        .navigationTitle("Template Editor")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred.")
        }
        .alert("Delete Template?", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) { deleteSelectedTemplate() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(selectedTemplate?.name ?? "No template selected")
        }
        .sheet(isPresented: $showingPreview) {
            if let data = exportPDFData {
                let filename = selectedTemplate?.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? "\(selectedTemplate!.name).pdf" : "Template.pdf"
                PDFPreviewView(pdfData: data, filename: filename, showingExport: .constant(false))
            }
        }
        // Keep selection in sync with template list
        .onChange(of: appState.templates.map { $0.id }) { _ in
            if selectedTemplateID == nil || !appState.templates.contains(where: { $0.id == selectedTemplateID }) {
                selectedTemplateID = appState.templates.first?.id
            }
        }
        .onAppear {
            if selectedTemplateID == nil {
                selectedTemplateID = appState.templates.first?.id
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showingDocumentPicker) {
            DocumentPickerView(onPick: { url in
                if isChangingBackground {
                    changeBackground(at: url)
                } else {
                    addTemplateWithBackground(at: url)
                }
            })
        }
        #endif
    }

    // MARK: - Field management

    private func addField(to templateIndex: Int) {
        let newField = TemplateField(
            key: "field.\(UUID().uuidString.prefix(6))",
            label: "New Field",
            kind: .text,
            frame: CGRectCodable(x: 100, y: 100, width: 200, height: 30),
            fontSize: 12,
            alignment: .left,
            placeholder: ""
        )
        appState.templates[templateIndex].fields.append(newField)
        appState.saveTemplates()
    }

    private func deleteSelectedTemplate() {
        guard let sIndex = selectedTemplateIndex else { return }
        appState.templates.remove(at: sIndex)
        appState.saveTemplates()
        selectedTemplateID = appState.templates.first?.id
    }

    // MARK: - Export (single page for selected template)

    private func exportSelectedTemplateAsPDF() {
        guard let template = selectedTemplate else { return }
        guard let bg = PlatformImage.load(named: template.backgroundImageName) else {
            errorMessage = "Could not load background image."
            return
        }
        let instructions = template.fields.map { f in
            DrawInstruction(
                text: "", // Export empty text by default; placement preview only
                frame: f.frame.cgRect,
                fontSize: f.fontSize,
                alignment: f.alignment,
                isMultiline: f.kind == .multiline
            )
        }
        let page = RenderedPage(backgroundImage: bg, instructions: instructions)
        let renderer = PDFRenderer()
        do {
            let data = try renderer.render(pages: [page])
            exportPDFData = data
            showingPreview = true
        } catch {
            errorMessage = "Failed to generate PDF: \(error.localizedDescription)"
        }
    }

    // MARK: - Background import + normalization (A4)

    #if os(iOS)
    private func addTemplateWithBackground(at url: URL) {
        loadImageFromFile_iOS(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    promptForNewTemplateName_iOS { name, page in
                        let normalized = normalizeToA4_iOS(image: image)
                        let imageName = saveImageToDocuments_iOS(image: normalized)
                        let newTemplate = Template(
                            name: name.isEmpty ? "Untitled" : name,
                            backgroundImageName: imageName,
                            pageIndex: page,
                            fields: []
                        )
                        appState.templates.append(newTemplate)
                        appState.saveTemplates()
                        selectedTemplateID = newTemplate.id
                    }
                case .failure(let err):
                    errorMessage = "Failed to load background: \(err.localizedDescription)"
                }
            }
        }
    }

    private func changeBackground(at url: URL) {
        loadImageFromFile_iOS(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let image):
                    if let sIndex = selectedTemplateIndex {
                        let normalized = normalizeToA4_iOS(image: image)
                        let imageName = saveImageToDocuments_iOS(image: normalized)
                        appState.templates[sIndex].backgroundImageName = imageName
                        appState.saveTemplates()
                    }
                case .failure(let err):
                    errorMessage = "Failed to load background: \(err.localizedDescription)"
                }
            }
        }
    }

    private func loadImageFromFile_iOS(url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if url.pathExtension.lowercased() == "pdf" {
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "PDF could not be loaded."])))
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let a4 = CGSize(width: 595, height: 842)
                UIGraphicsBeginImageContextWithOptions(a4, true, 1.0)
                defer { UIGraphicsEndImageContext() }
                guard let ctx = UIGraphicsGetCurrentContext() else {
                    completion(.failure(NSError(domain: "TemplateEditor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context."])))
                    return
                }
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fill(CGRect(origin: .zero, size: a4))
                let pageRect = page.bounds(for: .mediaBox)
                let scale = min(a4.width / pageRect.width, a4.height / pageRect.height)
                let scaledSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                let drawRect = CGRect(x: (a4.width - scaledSize.width) / 2,
                                      y: (a4.height - scaledSize.height) / 2,
                                      width: scaledSize.width,
                                      height: scaledSize.height)
                ctx.saveGState()
                ctx.translateBy(x: drawRect.minX, y: drawRect.maxY)
                ctx.scaleBy(x: scale, y: -scale)
                ctx.translateBy(x: -pageRect.minX, y: -pageRect.minY)
                page.draw(with: .mediaBox, to: ctx)
                ctx.restoreGState()
                if let img = UIGraphicsGetImageFromCurrentImageContext() {
                    completion(.success(img))
                } else {
                    completion(.failure(NSError(domain: "TemplateEditor", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to render PDF page."])))
                }
            }
        } else {
            if let image = UIImage(contentsOfFile: url.path) {
                completion(.success(image))
            } else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unsupported file type or not an image."])))
            }
        }
    }

    private func normalizeToA4_iOS(image: UIImage) -> UIImage {
        let a4 = CGSize(width: 595, height: 842)
        let renderer = UIGraphicsImageRenderer(size: a4)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: a4))
            let imgSize = image.size
            let scale = min(a4.width / imgSize.width, a4.height / imgSize.height)
            let scaled = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
            let rect = CGRect(x: (a4.width - scaled.width) / 2,
                              y: (a4.height - scaled.height) / 2,
                              width: scaled.width, height: scaled.height)
            image.draw(in: rect)
        }
    }

    private func saveImageToDocuments_iOS(image: UIImage) -> String {
        let filename = "template_bg_\(UUID().uuidString).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(filename)
        if let data = image.pngData() {
            try? data.write(to: url)
            return filename
        }
        return filename
    }

    private func promptForNewTemplateName_iOS(completion: @escaping (String, Int) -> Void) {
        let alert = UIAlertController(title: "New Template", message: "Enter a name and page index", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Template Name" }
        alert.addTextField { tf in tf.placeholder = "Page Index"; tf.keyboardType = .numberPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            let name = alert.textFields?[0].text ?? "Untitled"
            let page = Int(alert.textFields?[1].text ?? "") ?? 1
            completion(name, page)
        }))
        UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
    }

    struct DocumentPickerView: UIViewControllerRepresentable {
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
                if let url = urls.first { parent.onPick(url) }
            }
        }
    }
    #endif

    #if os(macOS)
    private func presentOpenPanel(forChange: Bool) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf, .image]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if forChange {
                changeBackground_macOS(at: url)
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
                    let normalized = normalizeToA4_macOS(image: image)
                    let filename = saveImageToDocuments_macOS(image: normalized)
                    let newTemplate = Template(name: name.isEmpty ? "Untitled" : name,
                                               backgroundImageName: filename,
                                               pageIndex: page,
                                               fields: [])
                    appState.templates.append(newTemplate)
                    appState.saveTemplates()
                    selectedTemplateID = newTemplate.id
                }
            case .failure(let err):
                errorMessage = "Failed to load background: \(err.localizedDescription)"
            }
        }
    }

    private func changeBackground_macOS(at url: URL) {
        loadImageFromFile_macOS(url: url) { result in
            switch result {
            case .success(let image):
                if let sIndex = selectedTemplateIndex {
                    let normalized = normalizeToA4_macOS(image: image)
                    let filename = saveImageToDocuments_macOS(image: normalized)
                    appState.templates[sIndex].backgroundImageName = filename
                    appState.saveTemplates()
                }
            case .failure(let err):
                errorMessage = "Failed to load background: \(err.localizedDescription)"
            }
        }
    }

    private func loadImageFromFile_macOS(url: URL, completion: @escaping (Result<NSImage, Error>) -> Void) {
        if url.pathExtension.lowercased() == "pdf" {
            guard let pdf = PDFDocument(url: url), let page = pdf.page(at: 0) else {
                completion(.failure(NSError(domain: "TemplateEditor", code: 1, userInfo: [NSLocalizedDescriptionKey: "PDF could not be loaded."])))
                return
            }
            DispatchQueue.global(qos: .userInitiated).async {
                let a4 = CGSize(width: 595, height: 842)
                let image = NSImage(size: a4)
                image.lockFocusFlipped(false)
                guard let ctx = NSGraphicsContext.current?.cgContext else {
                    image.unlockFocus()
                    completion(.failure(NSError(domain: "TemplateEditor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to create graphics context."])))
                    return
                }
                ctx.setFillColor(NSColor.white.cgColor)
                ctx.fill(CGRect(origin: .zero, size: a4))
                let pageRect = page.bounds(for: .mediaBox)
                let scale = min(a4.width / pageRect.width, a4.height / pageRect.height)
                let scaled = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)
                let drawRect = CGRect(x: (a4.width - scaled.width) / 2,
                                      y: (a4.height - scaled.height) / 2,
                                      width: scaled.width, height: scaled.height)
                ctx.saveGState()
                ctx.translateBy(x: drawRect.minX, y: drawRect.maxY)
                ctx.scaleBy(x: scale, y: -scale)
                ctx.translateBy(x: -pageRect.minX, y: -pageRect.minY)
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

    private func normalizeToA4_macOS(image: NSImage) -> NSImage {
        let a4 = CGSize(width: 595, height: 842)
        let out = NSImage(size: a4)
        out.lockFocusFlipped(false)
        NSColor.white.setFill()
        NSBezierPath(rect: CGRect(origin: .zero, size: a4)).fill()
        let imgSize = image.size
        let scale = min(a4.width / imgSize.width, a4.height / imgSize.height)
        let scaled = CGSize(width: imgSize.width * scale, height: imgSize.height * scale)
        let rect = CGRect(x: (a4.width - scaled.width) / 2,
                          y: (a4.height - scaled.height) / 2,
                          width: scaled.width, height: scaled.height)
        image.draw(in: rect)
        out.unlockFocus()
        return out
    }

    private func saveImageToDocuments_macOS(image: NSImage) -> String {
        let filename = "template_bg_\(UUID().uuidString).png"
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = documents.appendingPathComponent(filename)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else {
            return filename
        }
        try? data.write(to: url)
        return filename
    }

    private func promptForNewTemplateName_macOS(completion: @escaping (String, Int) -> Void) {
        let alert = NSAlert()
        alert.messageText = "New Template"
        alert.informativeText = "Enter a name and page index"
        let nameField = NSTextField(string: "")
        nameField.placeholderString = "Template Name"
        let pageField = NSTextField(string: "1")
        pageField.placeholderString = "Page Index"
        let stack = NSStackView(views: [nameField, pageField])
        stack.orientation = .vertical
        stack.spacing = 8
        alert.accessoryView = stack
        alert.addButton(withTitle: "Create")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let name = nameField.stringValue
            let page = Int(pageField.stringValue) ?? 1
            completion(name, page)
        }
    }
    #endif
}

// MARK: - Field Row Editor (text-based)

private struct FieldRowEditor: View {
    @Binding var field: TemplateField
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Label", text: $field.label)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            TextField("Key (e.g., notes.hpi)", text: $field.key)

            HStack {
                Picker("Type", selection: $field.kind) {
                    Text("Single line").tag(FieldKind.text)
                    Text("Multiline").tag(FieldKind.multiline)
                    Text("Date/Time").tag(FieldKind.datetime)
                    Text("Picker").tag(FieldKind.picker)
                }
                .pickerStyle(.menu)

                Spacer()

                Stepper(value: Binding(
                    get: { Int(field.fontSize) },
                    set: { field.fontSize = CGFloat($0) }
                ), in: 8...36) {
                    Text("Font: \(Int(field.fontSize))")
                }
            }

            HStack {
                Picker("Alignment", selection: $field.alignment) {
                    Text("Left").tag(NSTextAlignment.left)
                    Text("Center").tag(NSTextAlignment.center)
                    Text("Right").tag(NSTextAlignment.right)
                }
                .pickerStyle(.segmented)
            }

            TextField("Placeholder", text: Binding(
                get: { field.placeholder ?? "" },
                set: { field.placeholder = $0 }
            ))
            .textFieldStyle(.roundedBorder)
        }
        .font(.subheadline)
        .padding(.vertical, 6)
    }
}

// MARK: - Placement Editor (Level 2) – A4 canvas with auto-fit + manual zoom + scroll

struct TemplatePlacementView: View {
    @EnvironmentObject var appState: AppState
    let selectedTemplateID: UUID?

    @State private var selectedFieldID: UUID?
    @State private var snapToGrid = false
    @State private var scale: CGFloat = 1.0
    @State private var showingFieldEditor = false

    // A4 logical points at 72 DPI
    private let a4Width: CGFloat = 595
    private let a4Height: CGFloat = 842

    private var templateIndex: Int? {
        guard let id = selectedTemplateID else { return nil }
        return appState.templates.firstIndex(where: { $0.id == id })
    }
    private var templateValue: Template? {
        guard let idx = templateIndex, appState.templates.indices.contains(idx) else { return nil }
        return appState.templates[idx]
    }

    var body: some View {
        VStack(spacing: 0) {
            if let idx = templateIndex {
                let fieldsBinding = $appState.templates[idx].fields
                let template = appState.templates[idx]

                GeometryReader { proxy in
                    // Compute auto-fit scale to fit A4 page within available area
                    let availableW = max(1, proxy.size.width)
                    let availableH = max(1, proxy.size.height)
                    let fitScale = min(availableW / a4Width, availableH / a4Height)

                    ScrollView([.horizontal, .vertical]) {
                        ZStack {
                            // Centering container so the scaled canvas stays centered initially
                            Color.clear
                                .frame(
                                    width: max(availableW, a4Width * fitScale * scale),
                                    height: max(availableH, a4Height * fitScale * scale)
                                )

                            // The A4 canvas (background + overlays)
                            ZStack {
                                backgroundView(for: template)
                                    .frame(width: a4Width, height: a4Height)

                                FieldsOverlayView(
                                    fields: fieldsBinding,
                                    selectedFieldID: $selectedFieldID,
                                    snapToGrid: snapToGrid,
                                    onPositionChange: { appState.saveTemplates() }
                                )
                                .frame(width: a4Width, height: a4Height)
                            }
                            .frame(width: a4Width, height: a4Height)
                            .scaleEffect(fitScale * scale)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                }

                // Controls
                VStack(spacing: 12) {
                    HStack {
                        Toggle("Snap to Grid", isOn: $snapToGrid)
                        Spacer()
                        HStack {
                            Button { scale = max(0.5, scale - 0.1) } label: {
                                Image(systemName: "minus.magnifyingglass")
                            }
                            Text("\(Int(scale * 100))%").frame(width: 60)
                            Button { scale = min(3.0, scale + 0.1) } label: {
                                Image(systemName: "plus.magnifyingglass")
                            }
                        }
                    }
                    HStack {
                        Button("Save") { appState.saveTemplates() }
                            .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                }
                .padding()
            } else {
                Text("No template selected.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Text Placement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingFieldEditor) {
            if let idx = templateIndex,
               let fieldIndex = appState.templates[idx].fields.firstIndex(where: { $0.id == selectedFieldID }) {
                FieldEditorSheet(
                    field: $appState.templates[idx].fields[fieldIndex],
                    isPresented: $showingFieldEditor,
                    onDelete: {
                        appState.templates[idx].fields.remove(at: fieldIndex)
                        appState.saveTemplates()
                        showingFieldEditor = false
                        selectedFieldID = nil
                    }
                )
            }
        }
    }

    // Background display helper
    @ViewBuilder
    private func backgroundView(for template: Template) -> some View {
        // Enforce A4 frame; draw image scaled to fill that A4 canvas.
        if let image = loadBackgroundSwiftUIImage(namedOrFilename: template.backgroundImageName) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: a4Width, height: a4Height)
                .clipped()
        } else {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: a4Width, height: a4Height)
                .overlay(
                    Text("Image not found:\n\(template.backgroundImageName)")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                )
        }
    }

    private func loadBackgroundSwiftUIImage(namedOrFilename: String) -> Image? {
        if let asset = PlatformImage.swiftUIImage(named: namedOrFilename) {
            return asset
        }
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
}

// MARK: - Shared overlay views (unchanged)

private struct FieldsOverlayView: View {
    @Binding var fields: [TemplateField]
    @Binding var selectedFieldID: UUID?
    let snapToGrid: Bool
    let onPositionChange: () -> Void

    var body: some View {
        ForEach($fields) { $field in
            FieldOverlay(
                field: $field,
                isSelected: field.id == selectedFieldID,
                snapToGrid: snapToGrid,
                onTap: { selectedFieldID = field.id },
                onPositionChange: onPositionChange
            )
        }
    }
}

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
            .onTapGesture { onTap() }
    }
}

// Field editor sheet (unchanged UI)

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
                        Text("X"); Spacer()
                        TextField("X", value: Binding(
                            get: { Double(field.frame.x) },
                            set: { field.frame.x = CGFloat($0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    HStack {
                        Text("Y"); Spacer()
                        TextField("Y", value: Binding(
                            get: { Double(field.frame.y) },
                            set: { field.frame.y = CGFloat($0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    HStack {
                        Text("Width"); Spacer()
                        TextField("Width", value: Binding(
                            get: { Double(field.frame.width) },
                            set: { field.frame.width = CGFloat($0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    HStack {
                        Text("Height"); Spacer()
                        TextField("Height", value: Binding(
                            get: { Double(field.frame.height) },
                            set: { field.frame.height = CGFloat($0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                }
                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Font Size"); Spacer()
                        TextField("Size", value: Binding(
                            get: { Double(field.fontSize) },
                            set: { field.fontSize = CGFloat($0) }
                        ), format: .number.precision(.fractionLength(0...2)))
                        .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    Picker("Alignment", selection: $field.alignment) {
                        Text("Left").tag(NSTextAlignment.left)
                        Text("Center").tag(NSTextAlignment.center)
                        Text("Right").tag(NSTextAlignment.right)
                    }
                }
                Section {
                    Button(role: .destructive, action: onDelete) {
                        HStack { Spacer(); Text("Delete Field"); Spacer() }
                    }
                }
            }
            .navigationTitle("Edit Field")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

#Preview("Template Editor (Text)") {
    NavigationView {
        TemplateEditorView()
            .environmentObject(AppState())
    }
}

#Preview("Placement View") {
    NavigationView {
        TemplatePlacementView(selectedTemplateID: nil)
            .environmentObject(AppState())
    }
}
