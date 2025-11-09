//
//  LentorHVRecordFormView.swift
//  Speedoc Clinical Notes
//
//  Form for filling out Lentor Service Attendance Record
//

import SwiftUI

struct LentorHVRecordFormView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var showingPreview = false
    @State private var pdfData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let serviceTypeCodes = ["HN - Home Nursing", "HM - Home Medical", "HPC - Home Personal Care", "HT - Home Therapy"]
    
    var body: some View {
        Form {
            // Client Information
            Section(header: Text("Client Information")) {
                TextField("Client Name", text: $appState.lentorHVRecordDraft.clientName)
                    .onChange(of: appState.lentorHVRecordDraft.clientName) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
                
                TextField("Client NRIC", text: $appState.lentorHVRecordDraft.clientNRIC)
                    .onChange(of: appState.lentorHVRecordDraft.clientNRIC) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
            }
            
            // Service Location
            Section(header: Text("Service Location")) {
                TextField("Location", text: $appState.lentorHVRecordDraft.serviceLocation)
                    .onChange(of: appState.lentorHVRecordDraft.serviceLocation) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
                
                TextField("Contact No", text: $appState.lentorHVRecordDraft.serviceContact)
                    .onChange(of: appState.lentorHVRecordDraft.serviceContact) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
            }
            
            // Caregiver Information
            Section(header: Text("Caregiver Information")) {
                TextField("Caregiver Name", text: $appState.lentorHVRecordDraft.caregiverName)
                    .onChange(of: appState.lentorHVRecordDraft.caregiverName) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
                
                TextField("Caregiver NRIC", text: $appState.lentorHVRecordDraft.caregiverNRIC)
                    .onChange(of: appState.lentorHVRecordDraft.caregiverNRIC) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
                
                TextField("Caregiver Address", text: $appState.lentorHVRecordDraft.caregiverAddress)
                    .onChange(of: appState.lentorHVRecordDraft.caregiverAddress) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
                
                TextField("Caregiver Contact", text: $appState.lentorHVRecordDraft.caregiverContact)
                    .onChange(of: appState.lentorHVRecordDraft.caregiverContact) { _ in
                        appState.saveLentorHVRecordDraft()
                    }
            }
            
            // Attendance Records
            Section(header:
                HStack {
                    Text("Attendance Records")
                    Spacer()
                    Button(action: addRow) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            ) {
                if appState.lentorHVRecordDraft.rows.isEmpty {
                    Text("No attendance records yet. Tap + to add.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(appState.lentorHVRecordDraft.rows.indices, id: \.self) { index in
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
                            
                            TextField("Date", text: $appState.lentorHVRecordDraft.rows[index].date)
                                .onChange(of: appState.lentorHVRecordDraft.rows[index].date) { _ in
                                    appState.saveLentorHVRecordDraft()
                                }
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Start Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("e.g. 09:00", text: $appState.lentorHVRecordDraft.rows[index].timeStart)
                                        .onChange(of: appState.lentorHVRecordDraft.rows[index].timeStart) { _ in
                                            appState.saveLentorHVRecordDraft()
                                        }
                                }
                                
                                VStack(alignment: .leading) {
                                    Text("End Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("e.g. 10:00", text: $appState.lentorHVRecordDraft.rows[index].timeEnd)
                                        .onChange(of: appState.lentorHVRecordDraft.rows[index].timeEnd) { _ in
                                            appState.saveLentorHVRecordDraft()
                                        }
                                }
                            }
                            
                            TextField("Total Hours", text: $appState.lentorHVRecordDraft.rows[index].totalHours)
                                .onChange(of: appState.lentorHVRecordDraft.rows[index].totalHours) { _ in
                                    appState.saveLentorHVRecordDraft()
                                }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Type of Services")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("e.g. HN, HM, HPC, HT", text: $appState.lentorHVRecordDraft.rows[index].typeOfServices)
                                    .onChange(of: appState.lentorHVRecordDraft.rows[index].typeOfServices) { _ in
                                        appState.saveLentorHVRecordDraft()
                                    }
                            }
                            
                            TextField("Caregiver Signature", text: $appState.lentorHVRecordDraft.rows[index].caregiverSignature)
                                .onChange(of: appState.lentorHVRecordDraft.rows[index].caregiverSignature) { _ in
                                    appState.saveLentorHVRecordDraft()
                                }
                            
                            TextField("HC Staff Signature", text: $appState.lentorHVRecordDraft.rows[index].hcStaffSignature)
                                .onChange(of: appState.lentorHVRecordDraft.rows[index].hcStaffSignature) { _ in
                                    appState.saveLentorHVRecordDraft()
                                }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            
            // Legend
            Section(header: Text("Service Type Legend")) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(serviceTypeCodes, id: \.self) { code in
                        Text(code)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Generate PDF Button
            Section {
                Button(action: generatePDF) {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Preview & Export PDF")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Lentor Attendance Record")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPreview) {
            if let data = pdfData {
                let filename = filenameForExport()
                PDFPreviewView(pdfData: data, filename: filename, showingExport: .constant(false))
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Helper Functions
    
    private func addRow() {
        appState.lentorHVRecordDraft.rows.append(LentorAttendanceRow())
        appState.saveLentorHVRecordDraft()
    }
    
    private func deleteRow(at index: Int) {
        appState.lentorHVRecordDraft.rows.remove(at: index)
        appState.saveLentorHVRecordDraft()
    }
    
    private func filenameForExport() -> String {
        let patient = appState.lentorHVRecordDraft.clientName.isEmpty ? "Client" : appState.lentorHVRecordDraft.clientName
        if let descriptor = FormRegistry.shared.descriptor(institution: .lentor, kind: .homeVisitRecord) {
            return descriptor.exportFilenameFormat.replacingOccurrences(of: "{PATIENT_NAME}", with: patient)
        } else {
            return "\(patient) Lentor HV.pdf"
        }
    }
    
    private func generatePDF() {
        guard !appState.lentorHVRecordDraft.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            alertMessage = "Please enter a client name before exporting."
            showingAlert = true
            return
        }
        
        guard let template = appState.templates.first(where: { $0.backgroundImageName.contains("Lentor_HomeVisitRecord") }) else {
            alertMessage = "Lentor Attendance Record template not found. Please check Settings or restore defaults."
            showingAlert = true
            return
        }
        guard let image = PlatformImage.load(named: template.backgroundImageName) else {
            alertMessage = "Could not load form image. Please add asset Lentor_HomeVisitRecord."
            showingAlert = true
            return
        }
        
        var instructions: [DrawInstruction] = []
        
        // Header fields
        for field in template.fields where field.key.hasPrefix("lentorHV.") {
            let text = appState.lentorHVRecordDraft.value(for: field.key)
            instructions.append(DrawInstruction(
                text: text,
                frame: field.frame.cgRect,
                fontSize: field.fontSize,
                alignment: field.alignment,
                isMultiline: field.kind == .multiline
            ))
        }
        
        // Rows: draw up to 10 rows (pad with empties)
        let rowPrototype = template.fields.filter { $0.key.hasPrefix("lentorRow.") }
        let rowHeight: CGFloat = 40
        var rows = appState.lentorHVRecordDraft.rows
        if rows.count < 10 {
            rows.append(contentsOf: Array(repeating: LentorAttendanceRow(), count: 10 - rows.count))
        } else if rows.count > 10 {
            rows = Array(rows.prefix(10))
        }
        
        for (index, row) in rows.enumerated() {
            let yOffset = CGFloat(index) * rowHeight
            for field in rowPrototype {
                var frame = field.frame.cgRect
                frame.origin.y += yOffset
                let text = row.value(for: field.key)
                instructions.append(DrawInstruction(
                    text: text,
                    frame: frame,
                    fontSize: field.fontSize,
                    alignment: field.alignment,
                    isMultiline: false
                ))
            }
        }
        
        let page = RenderedPage(backgroundImage: image, instructions: instructions)
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

#Preview {
    NavigationView {
        LentorHVRecordFormView()
            .environmentObject(AppState())
    }
}

