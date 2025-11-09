//
//  CrossPlatform.swift
//  Speedoc Clinical Notes
//
//  Small helpers to bridge iOS and macOS differences.
//

import SwiftUI
import Foundation

// MARK: - Clipboard

enum ClipboardHelper {
    static func copy(_ string: String) {
        #if os(iOS)
        import UIKit
        UIPasteboard.general.string = string
        #elseif os(macOS)
        import AppKit
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
        #endif
    }
    
    static func readString() -> String? {
        #if os(iOS)
        import UIKit
        return UIPasteboard.general.string
        #elseif os(macOS)
        import AppKit
        return NSPasteboard.general.string(forType: .string)
        #endif
    }
}

// MARK: - Platform Image

enum PlatformImage {
    #if os(iOS)
    typealias Native = UIImage
    #elseif os(macOS)
    typealias Native = NSImage
    #endif
    
    static func load(named name: String) -> Native? {
        #if os(iOS)
        return UIImage(named: name)
        #elseif os(macOS)
        return NSImage(named: name)
        #endif
    }
    
    static func swiftUIImage(named name: String) -> Image? {
        #if os(iOS)
        if let ui = UIImage(named: name) { return Image(uiImage: ui) }
        return nil
        #elseif os(macOS)
        if let ns = NSImage(named: name) { return Image(nsImage: ns) }
        return nil
        #endif
    }
}

