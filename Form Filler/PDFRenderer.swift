//
//  PDFRenderer.swift
//  Speedoc Clinical Notes
//
//  PDF generation with background images and text overlay
//

import SwiftUI
import PDFKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Draw Instruction

struct DrawInstruction {
    let text: String
    let frame: CGRect
    let fontSize: CGFloat
    let alignment: NSTextAlignment
    let isMultiline: Bool
}

// MARK: - Rendered Page

struct RenderedPage {
    let backgroundImage: PlatformImage.Native
    let instructions: [DrawInstruction]
}

// MARK: - PDF Renderer

class PDFRenderer {
    
    enum PDFError: Error {
        case noPages
        case renderingFailed
    }
    
    /// Renders pages to a flattened PDF
    func render(pages: [RenderedPage]) throws -> Data {
        guard !pages.isEmpty else {
            throw PDFError.noPages
        }
        
        #if os(iOS)
        return try render_iOS(pages: pages)
        #elseif os(macOS)
        return try render_macOS(pages: pages)
        #endif
    }
    
    // MARK: - iOS implementation
    
    #if os(iOS)
    private func render_iOS(pages: [RenderedPage]) throws -> Data {
        let pdfMetaData = [
            kCGPDFContextCreator: "Speedoc Clinical Notes",
            kCGPDFContextAuthor: "Speedoc"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // A4
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            for page in pages {
                context.beginPage()
                
                let image = page.backgroundImage
                let imageSize = image.size
                let scale = min(pageRect.width / imageSize.width, pageRect.height / imageSize.height)
                let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
                let imageRect = CGRect(
                    x: (pageRect.width - scaledSize.width) / 2,
                    y: (pageRect.height - scaledSize.height) / 2,
                    width: scaledSize.width,
                    height: scaledSize.height
                )
                
                image.draw(in: imageRect)
                
                // Draw text
                let scaleX = scaledSize.width / imageSize.width
                let scaleY = scaledSize.height / imageSize.height
                let offsetX = imageRect.origin.x
                let offsetY = imageRect.origin.y
                
                for instruction in page.instructions {
                    let scaledFrame = CGRect(
                        x: instruction.frame.origin.x * scaleX + offsetX,
                        y: instruction.frame.origin.y * scaleY + offsetY,
                        width: instruction.frame.width * scaleX,
                        height: instruction.frame.height * scaleY
                    )
                    
                    drawText_iOS(
                        instruction.text,
                        in: scaledFrame,
                        fontSize: instruction.fontSize * scale,
                        alignment: instruction.alignment,
                        isMultiline: instruction.isMultiline
                    )
                }
            }
        }
        
        saveToDocuments(data: data, filename: "last_generated.pdf")
        return data
    }
    
    private func drawText_iOS(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        alignment: NSTextAlignment,
        isMultiline: Bool
    ) {
        guard !text.isEmpty else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = isMultiline ? .byWordWrapping : .byTruncatingTail
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        if isMultiline {
            attributedString.draw(in: rect)
        } else {
            let textSize = attributedString.size()
            let yOffset = (rect.height - textSize.height) / 2
            let drawRect = CGRect(x: rect.origin.x, y: rect.origin.y + yOffset, width: rect.width, height: textSize.height)
            attributedString.draw(in: drawRect)
        }
    }
    #endif
    
    // MARK: - macOS implementation
    
    #if os(macOS)
    private func render_macOS(pages: [RenderedPage]) throws -> Data {
        // Create a PDFDocument and append PDFPages rendered via AppKit
        let document = PDFDocument()
        
        // A4 page size in points (72 DPI)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        
        for (index, page) in pages.enumerated() {
            guard let pdfPage = renderOnePage_macOS(page: page, pageRect: pageRect) else {
                throw PDFError.renderingFailed
            }
            document.insert(pdfPage, at: index)
        }
        
        guard let data = document.dataRepresentation() else {
            throw PDFError.renderingFailed
        }
        
        saveToDocuments(data: data, filename: "last_generated.pdf")
        return data
    }
    
    private func renderOnePage_macOS(page: RenderedPage, pageRect: CGRect) -> PDFPage? {
        // Render into an NSImage, then wrap into a PDFPage
        let repSize = pageRect.size
        let image = NSImage(size: repSize)
        image.lockFocusFlipped(false)
        defer { image.unlockFocus() }
        
        guard let ctx = NSGraphicsContext.current?.cgContext else { return nil }
        
        // Background color white
        ctx.setFillColor(NSColor.white.cgColor)
        ctx.fill(pageRect)
        
        // Draw background image scaled to fit
        let imageSize = page.backgroundImage.size
        let scale = min(pageRect.width / imageSize.width, pageRect.height / imageSize.height)
        let scaledSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let imageRect = CGRect(
            x: (pageRect.width - scaledSize.width) / 2,
            y: (pageRect.height - scaledSize.height) / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        page.backgroundImage.draw(in: imageRect)
        
        // Draw text instructions
        let scaleX = scaledSize.width / imageSize.width
        let scaleY = scaledSize.height / imageSize.height
        let offsetX = imageRect.origin.x
        let offsetY = imageRect.origin.y
        
        for instruction in page.instructions {
            let scaledFrame = CGRect(
                x: instruction.frame.origin.x * scaleX + offsetX,
                y: instruction.frame.origin.y * scaleY + offsetY,
                width: instruction.frame.width * scaleX,
                height: instruction.frame.height * scaleY
            )
            drawText_macOS(
                instruction.text,
                in: scaledFrame,
                fontSize: instruction.fontSize * scale,
                alignment: instruction.alignment,
                isMultiline: instruction.isMultiline
            )
        }
        
        // Convert NSImage to PDFPage via PDFImageRep
        guard let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        let pdfData = bitmap.representation(using: .pdf, properties: [:])
        if let pdfData, let pdfDoc = PDFDocument(data: pdfData), let first = pdfDoc.page(at: 0) {
            return first
        }
        return nil
    }
    
    private func drawText_macOS(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        alignment: NSTextAlignment,
        isMultiline: Bool
    ) {
        guard !text.isEmpty else { return }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = isMultiline ? .byWordWrapping : .byTruncatingTail
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: NSColor.black
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        if isMultiline {
            attributedString.draw(in: rect)
        } else {
            let textSize = attributedString.size()
            let yOffset = (rect.height - textSize.height) / 2
            let drawRect = CGRect(x: rect.origin.x, y: rect.origin.y + yOffset, width: rect.width, height: textSize.height)
            attributedString.draw(in: drawRect)
        }
    }
    #endif
    
    private func saveToDocuments(data: Data, filename: String) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        try? data.write(to: fileURL)
    }
}

// MARK: - PDF Preview View

struct PDFPreviewView: View {
    let pdfData: Data
    let filename: String
    @Binding var showingExport: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let pdfDocument = PDFDocument(data: pdfData) {
                    CrossPlatformPDFView(document: pdfDocument)
                } else {
                    Text("Failed to load PDF preview")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    #if os(iOS)
                    Button("Export") {
                        showingShareSheet = true
                    }
                    #elseif os(macOS)
                    Button("Export") {
                        presentSavePanel(data: pdfData, suggestedFilename: filename)
                    }
                    #endif
                }
            }
            #if os(iOS)
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [PDFFile(data: pdfData, filename: filename)])
            }
            #endif
        }
    }
}

#if os(macOS)
// Present NSSavePanel directly from the current NSWindow to avoid ShareKit path
private func presentSavePanel(data: Data, suggestedFilename: String) {
    var name = suggestedFilename.trimmingCharacters(in: .whitespacesAndNewlines)
    if name.isEmpty { name = "Export.pdf" }
    if name.lowercased().hasSuffix(".pdf") == false {
        name += ".pdf"
    }
    
    let panel = NSSavePanel()
    panel.allowedFileTypes = ["pdf"]
    panel.canCreateDirectories = true
    panel.nameFieldStringValue = name
    
    if let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApplication.shared.windows.first {
        panel.beginSheetModal(for: window) { response in
            if response == .OK, let url = panel.url {
                try? data.write(to: url)
            }
        }
    } else {
        let response = panel.runModal()
        if response == .OK, let url = panel.url {
            try? data.write(to: url)
        }
    }
}
#endif

// MARK: - CrossPlatform PDFKit View

#if os(iOS)
import UIKit

struct CrossPlatformPDFView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

class PDFFile: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String
    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        data
    }
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        data
    }
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        filename
    }
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        "com.adobe.pdf"
    }
}

#elseif os(macOS)
import AppKit

struct CrossPlatformPDFView: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
}
#endif

// MARK: - Previews

#if os(iOS)
import UIKit
#endif

#Preview("PDF Preview View") {
    let renderer = PDFRenderer()
    #if os(iOS)
    let sampleBG = UIImage(systemName: "doc.fill")!
    #elseif os(macOS)
    let sampleBG = NSImage(size: NSSize(width: 200, height: 200), flipped: false) { rect in
        NSColor.lightGray.setFill()
        rect.fill()
        return true
    }
    #endif
    let page = RenderedPage(
        backgroundImage: sampleBG,
        instructions: [
            DrawInstruction(
                text: "Sample Preview",
                frame: CGRect(x: 100, y: 100, width: 400, height: 50),
                fontSize: 24,
                alignment: .center,
                isMultiline: false
            )
        ]
    )
    if let pdfData = try? renderer.render(pages: [page]) {
        PDFPreviewView(
            pdfData: pdfData,
            filename: "Sample.pdf",
            showingExport: .constant(false)
        )
    } else {
        PDFPreviewView(
            pdfData: Data(),
            filename: "Error.pdf",
            showingExport: .constant(false)
        )
    }
}
