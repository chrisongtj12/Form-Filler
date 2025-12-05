//
//  Settings+CoordinateTransfer.swift
//  Coordinate export/import for templates
//
//  Drop-in file for iOS 16+
//
//  Assumptions:
//  - You have models Template, TemplateField, FieldKind, CGRectCodable, and a store (TemplatePersisting)
//

import SwiftUI
import Combine

// MARK: - Store Adapter
protocol TemplatePersisting: ObservableObject {
    var templates: [Template] { get set }
    func save()
}

// MARK: - Export/Import JSON Schema (Templates-only, legacy)

struct ExportPackage: Codable {
    var version: Int
    var templates: [ExportTemplate]
}

struct ExportTemplate: Codable {
    var name: String
    var fields: [ExportField]
}

struct ExportField: Codable {
    var key: String
    var frame: RectDTO
    var fontSize: CGFloat?
    var alignment: AlignmentDTO?
}

// Minimal Rect DTO used for export/import (x,y,w,h)
struct RectDTO: Codable, Equatable {
    var x: CGFloat
    var y: CGFloat
    var w: CGFloat
    var h: CGFloat
}

// Alignment wrapper as string enum
enum AlignmentDTO: String, Codable {
    case left
    case center
    case right
}

// MARK: - New Combined Package (Templates + BV Notes Settings)

struct CombinedExportPackage: Codable {
    var version: Int
    var templates: [ExportTemplate]
    var bvNotesSettings: GlobalVaccineSettings?
}

// MARK: - Pure Functions (legacy templates-only)

func makeExportJSON(from templates: [Template]) -> String {
    let payload = ExportPackage(
        version: 1,
        templates: templates.map { t in
            ExportTemplate(
                name: t.name,
                fields: t.fields.map { f in
                    ExportField(
                        key: f.key,
                        frame: RectDTO(x: f.frame.x, y: f.frame.y, w: f.frame.width, h: f.frame.height),
                        fontSize: f.fontSize,
                        alignment: AlignmentDTO(from: f.alignment)
                    )
                }
            )
        }
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    do {
        let data = try encoder.encode(payload)
        return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
        return "{}"
    }
}

public struct ImportResult {
    public var updatedCount: Int
    public var skippedCount: Int
    public var warnings: [String]
}

func applyImportJSON(_ json: String, to templates: inout [Template]) -> ImportResult {
    var result = ImportResult(updatedCount: 0, skippedCount: 0, warnings: [])
    guard let data = json.data(using: .utf8) else {
        result.warnings.append("Invalid UTF-8 data.")
        return result
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    // Try combined first, fall back to legacy
    if let combined = try? decoder.decode(CombinedExportPackage.self, from: data) {
        // Apply templates
        let templateResult = applyTemplates(from: combined.templates, to: &templates)
        result.updatedCount += templateResult.updatedCount
        result.skippedCount += templateResult.skippedCount
        result.warnings.append(contentsOf: templateResult.warnings)
        // Apply BV Notes settings if present
        if let settings = combined.bvNotesSettings {
            do {
                try saveBVNotesSettings(settings)
            } catch {
                result.warnings.append("Failed to save BV Notes settings: \(error.localizedDescription)")
            }
        }
        return result
    }
    // Legacy path (templates only)
    do {
        let package = try decoder.decode(ExportPackage.self, from: data)
        if package.version != 1 {
            result.warnings.append("Unsupported version \(package.version). Attempting best-effort import.")
        }
        let templateResult = applyTemplates(from: package.templates, to: &templates)
        result.updatedCount += templateResult.updatedCount
        result.skippedCount += templateResult.skippedCount
        result.warnings.append(contentsOf: templateResult.warnings)
    } catch {
        result.warnings.append("JSON decoding failed: \(error.localizedDescription)")
    }
    return result
}

// MARK: - New Combined helpers

func makeCombinedExportJSON(templates: [Template], bvSettings: GlobalVaccineSettings?) -> String {
    let payload = CombinedExportPackage(
        version: 2,
        templates: templates.map { t in
            ExportTemplate(
                name: t.name,
                fields: t.fields.map { f in
                    ExportField(
                        key: f.key,
                        frame: RectDTO(x: f.frame.x, y: f.frame.y, w: f.frame.width, h: f.frame.height),
                        fontSize: f.fontSize,
                        alignment: AlignmentDTO(from: f.alignment)
                    )
                }
            )
        },
        bvNotesSettings: bvSettings
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    do {
        let data = try encoder.encode(payload)
        return String(data: data, encoding: .utf8) ?? "{}"
    } catch {
        return "{}"
    }
}

private func applyTemplates(from exportTemplates: [ExportTemplate], to templates: inout [Template]) -> ImportResult {
    var result = ImportResult(updatedCount: 0, skippedCount: 0, warnings: [])
    var templateIndexByName: [String: Int] = [:]
    for (idx, t) in templates.enumerated() {
        templateIndexByName[t.name] = idx
    }
    for expTemplate in exportTemplates {
        guard let tIndex = templateIndexByName[expTemplate.name] else {
            result.skippedCount += 1
            result.warnings.append("Template not found: \(expTemplate.name)")
            continue
        }
        var fieldIndexByKey: [String: Int] = [:]
        for (fIdx, f) in templates[tIndex].fields.enumerated() {
            fieldIndexByKey[f.key] = fIdx
        }
        for expField in expTemplate.fields {
            guard let fIndex = fieldIndexByKey[expField.key] else {
                result.skippedCount += 1
                result.warnings.append("Field not found in template '\(expTemplate.name)': \(expField.key)")
                continue
            }
            templates[tIndex].fields[fIndex].frame = CGRectCodable(
                x: expField.frame.x,
                y: expField.frame.y,
                width: expField.frame.w,
                height: expField.frame.h
            )
            if let fs = expField.fontSize {
                templates[tIndex].fields[fIndex].fontSize = fs
            }
            if let al = expField.alignment {
                templates[tIndex].fields[fIndex].alignment = al.toNSTextAlignment()
            }
            result.updatedCount += 1
        }
    }
    return result
}

// MARK: - BV Notes settings persistence helpers

private func bvSettingsURL() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("bv_settings.json")
}

private func saveBVNotesSettings(_ settings: GlobalVaccineSettings) throws {
    let url = bvSettingsURL()
    let data = try JSONEncoder().encode(settings)
    try data.write(to: url, options: .atomic)
}

// MARK: - Alignment helpers

extension AlignmentDTO {
    init?(from alignment: NSTextAlignment) {
        switch alignment {
        case .left: self = .left
        case .center: self = .center
        case .right: self = .right
        default: return nil
        }
    }
    func toNSTextAlignment() -> NSTextAlignment {
        switch self {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        }
    }
}

// MARK: - Clipboard + JSON helpers

struct Clipboard {
    static func copy(_ string: String) {
        ClipboardHelper.copy(string)
    }
    static func pasteString() -> String? {
        ClipboardHelper.readString()
    }
}

func prettyJSON(_ string: String) -> String {
    guard let data = string.data(using: .utf8) else { return string }
    do {
        let obj = try JSONSerialization.jsonObject(with: data, options: [])
        let prettyData = try JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(data: prettyData, encoding: .utf8) ?? string
    } catch {
        return string
    }
}

// MARK: - Import Sheet UI (templates-only; unchanged)

struct ImportCoordinatesSheet<Store: TemplatePersisting>: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: Store
    
    @State private var text: String = ""
    @State private var errorMessage: String?
    @State private var resultMessage: String?
    @State private var isApplying: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header actions
                HStack {
                    Button("Paste") {
                        if let s = Clipboard.pasteString() {
                            text = prettyJSON(s)
                        }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding([.horizontal, .top])
                
                // Editor
                TextEditor(text: $text)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(
                        Group {
                            #if os(iOS)
                            Color(UIColor.secondarySystemBackground)
                            #elseif os(macOS)
                            Color(nsColor: .underPageBackgroundColor)
                            #endif
                        }
                    )
                
                // Messages
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.red)
                        .padding([.horizontal, .bottom])
                }
                if let resultMessage {
                    Text(resultMessage)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding([.horizontal, .bottom])
                }
            }
            .navigationTitle("Import Coordinates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isApplying ? "Applying…" : "Apply") {
                        apply()
                    }
                    .disabled(isApplying || text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func apply() {
        errorMessage = nil
        resultMessage = nil
        isApplying = true
        defer { isApplying = false }
        
        var working = store.templates
        let result = applyImportJSON(text, to: &working) // This now also saves BV settings if present
        
        if result.updatedCount == 0 && result.warnings.isEmpty {
            errorMessage = "No updates applied. Check JSON format and names."
            return
        }
        
        store.templates = working
        store.save()
        
        let summary = "Updated \(result.updatedCount) fields • \(result.skippedCount) skipped"
        if result.warnings.isEmpty {
            resultMessage = summary
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                dismiss()
            }
        } else {
            let detail = result.warnings.joined(separator: "\n• ")
            resultMessage = summary + "\nWarnings:\n• " + detail
        }
    }
}

// MARK: - Settings Helpers (Buttons)

struct TemplateCoordinateTransferView<Store: TemplatePersisting>: View {
    @EnvironmentObject var store: Store
    
    @State private var showingImport = false
    @State private var showingCopiedAlert = false
    
    var body: some View {
        VStack {
            Button("Export coordinates") {
                let json = makeExportJSON(from: store.templates)
                Clipboard.copy(json)
                showingCopiedAlert = true
            }
            Button("Import coordinates") {
                showingImport = true
            }
        }
        .alert("Copied", isPresented: $showingCopiedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Template coordinates copied to clipboard.")
        }
        .sheet(isPresented: $showingImport) {
            ImportCoordinatesSheet<Store>()
                .environmentObject(store)
        }
    }
}

#if DEBUG
struct SettingsCoordinateTransfer_Previews: PreviewProvider {
    final class MockStore: TemplatePersisting {
        @Published var templates: [Template] = [
            Template(
                name: "Active Global Medical Notes (p1)",
                backgroundImageName: "AG_MedicalNotes_p1",
                pageIndex: 1,
                fields: [
                    TemplateField(
                        key: "patient.name",
                        label: "Name",
                        kind: .text,
                        frame: CGRectCodable(x: 84, y: 112, width: 260, height: 22),
                        fontSize: 13,
                        alignment: .left,
                        placeholder: nil
                    ),
                    TemplateField(
                        key: "patient.nric",
                        label: "NRIC",
                        kind: .text,
                        frame: CGRectCodable(x: 84, y: 146, width: 220, height: 22),
                        fontSize: 13,
                        alignment: .left,
                        placeholder: nil
                    )
                ]
            )
        ]
        func save() {}
    }
    
    static var previews: some View {
        let store = MockStore()
        return NavigationView {
            Form {
                Section(header: Text("Templates")) {
                    TemplateCoordinateTransferView<MockStore>()
                        .environmentObject(store)
                }
            }
        }
    }
}
#endif
