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
                .onChange(of: appState.hvRecordDraft.serviceType) {
                    appState.saveHVRecordDraft()
                }
                
                TextField("Clinician Name", text: $appState.hvRecordDraft.clinicianName)
                    .onChange(of: appState.hvRecordDraft.clinicianName) {
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
                                .onChange(of: appState.hvRecordDraft.rows[index].clientName) {
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Client NRIC", text: $appState.hvRecordDraft.rows[index].clientNRIC)
                                .onChange(of: appState.hvRecordDraft.rows[index].clientNRIC) {
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Date & Time of Visit", text: $appState.hvRecordDraft.rows[index].dateTimeOfVisit)
                                .onChange(of: appState.hvRecordDraft.rows[index].dateTimeOfVisit) {
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Client/NOK", text: $appState.hvRecordDraft.rows[index].clientNOK)
                                .onChange(of: appState.hvRecordDraft.rows[index].clientNOK) {
                                    appState.saveHVRecordDraft()
                                }
                            
                            TextField("Signature", text: $appState.hvRecordDraft.rows[index].signatureText)
                                .onChange(of: appState.hvRecordDraft.rows[index].signatureText) {
                                    appState.saveHVRecordDraft()
                                }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Home Visit Record")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func addRow() {
        appState.hvRecordDraft.rows.append(HVRecordRow())
        appState.saveHVRecordDraft()
    }
    
    private func deleteRow(at index: Int) {
        appState.hvRecordDraft.rows.remove(at: index)
        appState.saveHVRecordDraft()
    }
}
