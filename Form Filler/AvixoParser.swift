//
//  AvixoParser.swift
//  Speedoc Clinical Notes
//
//  Parser for AVIXO Home Medical Notes text format
//

import Foundation

/// Parses AVIXO-formatted clinical notes text into structured data
func parseAvixoDump(_ text: String) -> ClinicalNote {
    var note = ClinicalNote()
    
    // Normalize line endings
    let normalizedText = text.replacingOccurrences(of: "\r\n", with: "\n")
                              .replacingOccurrences(of: "\r", with: "\n")
    
    // Parse single-line fields
    note.patientName = extractSingleLineField(
        from: normalizedText,
        headers: ["Name"]
    )
    
    note.nric = extractSingleLineField(
        from: normalizedText,
        headers: ["NRIC", "IC"]
    )
    
    note.dateOfVisit = extractSingleLineField(
        from: normalizedText,
        headers: ["Date of Visit", "Date", "Visit Date"]
    )
    
    note.clientOrNOK = extractSingleLineField(
        from: normalizedText,
        headers: ["Client/NOK", "Client / NOK", "NOK"]
    )
    
    note.bp = extractSingleLineField(
        from: normalizedText,
        headers: ["BP", "Blood Pressure"]
    )
    
    note.spo2 = extractSingleLineField(
        from: normalizedText,
        headers: ["SpO2", "SPO2", "Spo2", "O2 Sat"]
    )
    
    note.pr = extractSingleLineField(
        from: normalizedText,
        headers: ["PR", "Pulse Rate", "Pulse"]
    )
    
    note.hypocount = extractSingleLineField(
        from: normalizedText,
        headers: ["Hypocount", "Hypo Count", "Hypo"]
    )
    
    // Parse multi-line fields
    note.pmh = extractMultiLineField(
        from: normalizedText,
        headers: ["Past Medical History", "PMH", "Medical History"]
    )
    
    note.presentingComplaint = extractMultiLineField(
        from: normalizedText,
        headers: ["Presenting Complaint", "History of Presenting Complaint", "HPI", "Complaint"]
    )
    
    note.physicalExam = extractMultiLineField(
        from: normalizedText,
        headers: ["Physical Examination", "Physical Exam", "PE", "Examination"]
    )
    
    note.issues = extractMultiLineField(
        from: normalizedText,
        headers: ["Issues", "Diagnosis", "Assessment"]
    )
    
    note.plan = extractMultiLineField(
        from: normalizedText,
        headers: ["Plan", "Management", "Treatment Plan"]
    )
    
    return note
}

// MARK: - Private Helpers

/// Extracts a single-line field value
/// Handles cases where value is on same line or next line
private func extractSingleLineField(from text: String, headers: [String]) -> String {
    for header in headers {
        // Try pattern: "Header: value" (value on same line)
        let sameLinePattern = makeHeaderPattern(header) + "\\s*(.+?)\\s*$"
        if let match = text.range(of: sameLinePattern, options: [.regularExpression, .caseInsensitive, .anchored]) {
            let matchedText = String(text[match])
            if let colonIndex = matchedText.firstIndex(of: ":") {
                let value = String(matchedText[matchedText.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }
        }
        
        // Try pattern: "Header:\n value" (value on next line)
        let nextLinePattern = makeHeaderPattern(header) + "\\s*\\n\\s*(.+?)\\s*$"
        if let match = text.range(of: nextLinePattern, options: [.regularExpression, .caseInsensitive, .anchored]) {
            let matchedText = String(text[match])
            let lines = matchedText.components(separatedBy: .newlines)
            if lines.count >= 2 {
                let value = lines[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !value.isEmpty {
                    return value
                }
            }
        }
        
        // Try matching anywhere in text (not just anchored)
        let anywherePattern = "(?m)^\\s*" + makeHeaderPattern(header) + "\\s*(.*)$"
        if let regex = try? NSRegularExpression(pattern: anywherePattern, options: .caseInsensitive) {
            let nsText = text as NSString
            if let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) {
                if match.numberOfRanges > 1 {
                    let valueRange = match.range(at: 1)
                    if valueRange.location != NSNotFound {
                        let value = nsText.substring(with: valueRange)
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if !value.isEmpty {
                            return value
                        }
                        
                        // Value might be on next line
                        let headerEndLocation = match.range.location + match.range.length
                        if headerEndLocation < nsText.length {
                            // Find the next non-empty line
                            let remainingText = nsText.substring(from: headerEndLocation)
                            if let nextLine = remainingText.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                                let trimmed = nextLine.trimmingCharacters(in: .whitespacesAndNewlines)
                                // Make sure it's not another header
                                if !isHeaderLine(trimmed) {
                                    return trimmed
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return ""
}

/// Extracts a multi-line field value (everything until next header or end)
private func extractMultiLineField(from text: String, headers: [String]) -> String {
    for header in headers {
        let headerPattern = "(?im)^\\s*" + makeHeaderPattern(header) + "\\s*$"
        
        guard let regex = try? NSRegularExpression(pattern: headerPattern) else {
            continue
        }
        
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else {
            continue
        }
        
        // Start capturing after the header line
        let startLocation = match.range.location + match.range.length
        guard startLocation < nsText.length else {
            continue
        }
        
        let remainingText = nsText.substring(from: startLocation)
        
        // Find the next header or end of text
        let allHeadersPattern = makeAllHeadersPattern()
        let nextHeaderRegex = try? NSRegularExpression(pattern: allHeadersPattern, options: [.caseInsensitive, .anchorsMatchLines])
        
        let remainingNSText = remainingText as NSString
        var endLocation = remainingNSText.length
        
        if let nextHeaderRegex = nextHeaderRegex,
           let nextMatch = nextHeaderRegex.firstMatch(in: remainingText, range: NSRange(location: 0, length: remainingNSText.length)) {
            endLocation = nextMatch.range.location
        }
        
        let value = remainingNSText.substring(with: NSRange(location: 0, length: endLocation))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !value.isEmpty {
            return value
        }
    }
    
    return ""
}

/// Creates a regex pattern for matching a header (case-insensitive, flexible spacing)
private func makeHeaderPattern(_ header: String) -> String {
    // Escape special regex characters and allow flexible whitespace
    let escaped = NSRegularExpression.escapedPattern(for: header)
    return escaped.replacingOccurrences(of: " ", with: "\\s+")
        .replacingOccurrences(of: "/", with: "\\s*/\\s*")
        + "\\s*:"
}

/// Creates a pattern matching any known header
private func makeAllHeadersPattern() -> String {
    let allHeaders = [
        "Name",
        "NRIC",
        "IC",
        "Date of Visit",
        "Date",
        "Visit Date",
        "Client/NOK",
        "Client / NOK",
        "NOK",
        "BP",
        "Blood Pressure",
        "SpO2",
        "SPO2",
        "Spo2",
        "O2 Sat",
        "PR",
        "Pulse Rate",
        "Pulse",
        "Hypocount",
        "Hypo Count",
        "Hypo",
        "Past Medical History",
        "PMH",
        "Medical History",
        "Presenting Complaint",
        "History of Presenting Complaint",
        "HPI",
        "Complaint",
        "Physical Examination",
        "Physical Exam",
        "PE",
        "Examination",
        "Issues",
        "Diagnosis",
        "Assessment",
        "Plan",
        "Management",
        "Treatment Plan",
        "Notes"
    ]
    
    let patterns = allHeaders.map { makeHeaderPattern($0) }
    return "(?m)^\\s*(" + patterns.joined(separator: "|") + ")"
}

/// Checks if a line appears to be a header
private func isHeaderLine(_ line: String) -> Bool {
    let pattern = makeAllHeadersPattern()
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
        return false
    }
    
    let nsLine = line as NSString
    return regex.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) != nil
}
