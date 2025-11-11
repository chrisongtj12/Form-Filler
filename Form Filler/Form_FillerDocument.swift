//
//  Form_FillerDocument.swift
//  Form Filler
//
//  Created by Christopher Ong on 8/11/25.
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated struct Form_FillerDocument: FileDocument {
    var text: String

    init(text: String = "Hello, world!") {
        self.text = text
    }

    // Use a public UTI instead of a custom "com.example.*"
    static let readableContentTypes: [UTType] = [
        .plainText // maps to "public.plain-text"
    ]

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}
