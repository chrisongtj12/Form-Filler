//
//  PlatformImage.swift
//  Speedoc Clinical Notes
//
//  Cross-platform image wrapper for loading template backgrounds
//

import SwiftUI

enum PlatformImage {
    #if os(iOS)
    typealias Native = UIImage
    #elseif os(macOS)
    typealias Native = NSImage
    #endif
    
    /// Load an asset by name and return a SwiftUI.Image for display in views.
    static func swiftUIImage(named name: String) -> Image? {
        #if os(iOS)
        if let ui = UIImage(named: name) {
            return Image(uiImage: ui)
        }
        #elseif os(macOS)
        if let ns = NSImage(named: NSImage.Name(name)) {
            return Image(nsImage: ns)
        }
        #endif
        return nil
    }
}

