//
//  HVRecordFormView.swift
//  Speedoc Clinical Notes
//
//  Form for filling out Active Global Home Visit Record
//

import SwiftUI

struct HVRecordFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPreview = false
    @State private var showingExport = false
    @State private var pdfData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let serviceTypes = ["Home Medical", "Home Nursing", "Home Therapy"]
    
    var body: some View {
        Form {
            Section(header: Text("Service Information")) {
                Picker("Service Type", selection: $appState.hvRecordDraft.serviceType) {
                    ForEach(serviceTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .onChange(of: appState.hvRecordDraft.serviceType) { _ in
                    appState.saveHVRecordDraft()
                }
                
                TextField("Clinician Name", text: $appState.hvRecordDraft.clinicianName)
                    .onChange(of: appState.hvRecordDraft.clinicianName) { _ in
                        appState.saveHVRecordDraft()
                    }
                
                Button("Use My Profile") {
                    appState.hvRecordDraft.clinicianName = appState.clinician.displayName
                    appState.saveHVRecordDraft()
                }
            }
            
            Section(header: 
                HStack {
                    Text("Visit Records")
                    Spacer()
                    Button(action: addRow) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            ) {
                if appState.hvRecordDraft.rows.isEmpty {
                    Text("No records yet. Tap + to add.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(appState.hvRecordDraft.rows.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Record \(index + 1)")
                                    .font(.headline)
                                Spacer()
                                Button(action: { deleteRow(at: index) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            
                            TextField("Client Name", text: $appState.hvRecordDraft.rows[index].clientName)
                                .onChange(of: appState.hvRecordDraft.rows[index].clientName) { _ in
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Client NRIC", text: $appState.hvRecordDraft.rows[index].clientNRIC)
                                .onChange(of: appState.hvRecordDraft.rows[index].clientNRIC) { _ in
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Date/Time of Visit", text: $appState.hvRecordDraft.rows[index].dateTimeOfVisit)
                                .onChange(of: appState.hvRecordDraft.rows[index].dateTimeOfVisit) { _ in
                                    appState.saveHVRecordDraft()
                                }
                            
                            Button("Set Now") {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "dd/MM/yyyy HH:mm"
                                appState.hvRecordDraft.rows[index].dateTimeOfVisit = formatter.string(from: Date())
                                appState.saveHVRecordDraft()
                            }
                            .font(.caption)
                            
                            TextField("Client NOK", text: $appState.hvRecordDraft.rows[index].clientNOK)
                                .onChange(of: appState.hvRecordDraft.rows[index].clientNOK) { _ in
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Signature", text: $appState.hvRecordDraft.rows[index].signatureText)
                                .onChange(of: appState.hvRecordDraft.rows[index].signatureText) { _ in
                                    appState.saveHVRecordDraft()
                                }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            Section {
                Button(action: generatePDF) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Preview & Export")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Home Visit Record")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            autoFillIfEmpty()
        }
        .sheet(isPresented: $showingPreview) {
            if let data = pdfData {
                let patientName = appState.hvRecordDraft.rows.first?.clientName ?? "Unknown"
                PDFPreviewView(
                    pdfData: data,
                    filename: "\(patientName) HV.pdf",
                    showingExport: $showingExport
                )
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func autoFillIfEmpty() {
        if appState.hvRecordDraft.clinicianName.isEmpty {
            appState.hvRecordDraft.clinicianName = appState.clinician.displayName
            appState.saveHVRecordDraft()
        }
        
        if appState.hvRecordDraft.rows.isEmpty {
            addRow()
        }
    }
    
    private func addRow() {
        let newRow = HVRecordRow()
        appState.hvRecordDraft.rows.append(newRow)
        appState.saveHVRecordDraft()
    }
    
    private func deleteRow(at index: Int) {
        appState.hvRecordDraft.rows.remove(at: index)
        appState.saveHVRecordDraft()
    }
    
    private func generatePDF() {
        guard !appState.hvRecordDraft.rows.isEmpty else {
            alertMessage = "Please add at least one visit record before exporting."
            showingAlert = true
            return
        }
        
        guard !appState.hvRecordDraft.rows[0].clientName.isEmpty else {
            alertMessage = "Please enter a client name in the first record before exporting."
            showingAlert = true
            return
        }
        
        // Get template
        guard let template = appState.templates.first(where: { 
            $0.backgroundImageName == "AG_HomeVisitRecord"
        }) else {
            alertMessage = "Home Visit Record template not found. Please check Settings."
            showingAlert = true
            return
        }
        
        guard let image = UIImage(named: template.backgroundImageName) else {
            alertMessage = "Could not load form image. Please add AG_HomeVisitRecord to Assets."
            showingAlert = true
            return
        }
        
        // Generate instructions for header fields
        var instructions: [DrawInstruction] = []
        
        for field in template.fields {
            if field.key.starts(with: "hv.") {
                let text = appState.hvRecordDraft.value(for: field.key)
                instructions.append(DrawInstruction(
                    text: text,
                    frame: field.frame.cgRect,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        // Generate instructions for table rows
        let rowFields = template.fields.filter { $0.key.starts(with: "row.") }
        let rowHeight: CGFloat = 50 // spacing between rows
        
        for (rowIndex, row) in appState.hvRecordDraft.rows.enumerated() {
            let yOffset = CGFloat(rowIndex) * rowHeight
            
            for field in rowFields {
                let text = row.value(for: field.key)
                var adjustedFrame = field.frame.cgRect
                adjustedFrame.origin.y += yOffset
                
                instructions.append(DrawInstruction(
                    text: text,
                    frame: adjustedFrame,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        let page = RenderedPage(backgroundImage: image, instructions: instructions)
        
        // Generate PDF
        let renderer = PDFRenderer()
        do {
            pdfData = try renderer.render(pages: [page])
            showingPreview = true
        } catch {
            alertMessage = "Failed to generate PDF: \(error.localizedDescription)"
            showingAlert = true
        }
    }
}
