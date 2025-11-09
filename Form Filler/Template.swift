//
//  Template.swift
//  Speedoc Clinical Notes
//
//  Template and field models for PDF form rendering
//

import Foundation
import CoreGraphics

#if os(iOS)
import UIKit // for NSTextAlignment
#elseif os(macOS)
import AppKit // for NSTextAlignment
#endif

// MARK: - Field Kind

enum FieldKind: String, Codable {
    case text
    case multiline
    case datetime
    case picker
}

// MARK: - Codable CGRect

struct CGRectCodable: Codable {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    
    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
    
    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
    
    init(rect: CGRect) {
        self.x = rect.origin.x
        self.y = rect.origin.y
        self.width = rect.size.width
        self.height = rect.size.height
    }
}

// MARK: - Template Field

struct TemplateField: Codable, Identifiable {
    var id = UUID()
    var key: String
    var label: String
    var kind: FieldKind
    var frame: CGRectCodable
    var fontSize: CGFloat
    var alignment: NSTextAlignment
    var placeholder: String?
    
    enum CodingKeys: String, CodingKey {
        case id, key, label, kind, frame, fontSize, alignment, placeholder
    }
    
    init(
        key: String,
        label: String,
        kind: FieldKind,
        frame: CGRectCodable,
        fontSize: CGFloat,
        alignment: NSTextAlignment,
        placeholder: String?
    ) {
        self.key = key
        self.label = label
        self.kind = kind
        self.frame = frame
        self.fontSize = fontSize
        self.alignment = alignment
        self.placeholder = placeholder
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        label = try container.decode(String.self, forKey: .label)
        kind = try container.decode(FieldKind.self, forKey: .kind)
        frame = try container.decode(CGRectCodable.self, forKey: .frame)
        fontSize = try container.decode(CGFloat.self, forKey: .fontSize)
        
        // Decode alignment from raw value
        let alignmentRaw = try container.decode(Int.self, forKey: .alignment)
        alignment = NSTextAlignment(rawValue: alignmentRaw) ?? .left
        
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(label, forKey: .label)
        try container.encode(kind, forKey: .kind)
        try container.encode(frame, forKey: .frame)
        try container.encode(fontSize, forKey: .fontSize)
        try container.encode(alignment.rawValue, forKey: .alignment)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
    }
}

// MARK: - Template

struct Template: Codable, Identifiable {
    var id = UUID()
    var name: String
    var backgroundImageName: String
    var pageIndex: Int
    var fields: [TemplateField]
}

