//
//  PDFRenderer.swift
//  Speedoc Clinical Notes
//
//  PDF generation with background images and text overlay
//

import UIKit
import PDFKit
import SwiftUI

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
    let backgroundImage: UIImage
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
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Speedoc Clinical Notes",
            kCGPDFContextAuthor: "Speedoc"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Use A4 page size (595 x 842 points)
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            for page in pages {
                context.beginPage()
                
                // Draw background image scaled to fit page
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
                    // Scale frame to match the scaled background
                    let scaledFrame = CGRect(
                        x: instruction.frame.origin.x * scaleX + offsetX,
                        y: instruction.frame.origin.y * scaleY + offsetY,
                        width: instruction.frame.width * scaleX,
                        height: instruction.frame.height * scaleY
                    )
                    
                    drawText(
                        instruction.text,
                        in: scaledFrame,
                        fontSize: instruction.fontSize * scale,
                        alignment: instruction.alignment,
                        isMultiline: instruction.isMultiline,
                        context: context.cgContext
                    )
                }
            }
        }
        
        // Also save to Documents folder
        saveToDocuments(data: data, filename: "last_generated.pdf")
        
        return data
    }
    
    private func drawText(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        alignment: NSTextAlignment,
        isMultiline: Bool,
        context: CGContext
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
            // Draw multiline text with wrapping
            attributedString.draw(in: rect)
        } else {
            // Draw single line text vertically centered
            let textSize = attributedString.size()
            let yOffset = (rect.height - textSize.height) / 2
            let drawRect = CGRect(
                x: rect.origin.x,
                y: rect.origin.y + yOffset,
                width: rect.width,
                height: textSize.height
            )
            attributedString.draw(in: drawRect)
        }
    }
    
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
                    PDFKitView(document: pdfDocument)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [PDFFile(data: pdfData, filename: filename)])
            }
        }
    }
}

// MARK: - PDFKit View Wrapper

struct PDFKitView: UIViewRepresentable {
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

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - PDF File for Sharing

class PDFFile: NSObject, UIActivityItemSource {
    let data: Data
    let filename: String
    
    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return data
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return filename
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "com.adobe.pdf"
    }
}
