//
//  ClipboardHelper.swift
//  Cross-platform clipboard helper for iOS/macOS
//

import Foundation

#if os(iOS) || os(tvOS) || os(visionOS)
import UIKit
#endif

#if os(macOS)
import AppKit
#endif

enum ClipboardHelper {
    static func copy(_ string: String) {
        #if os(iOS) || os(tvOS) || os(visionOS)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
        #else
        // Unsupported platform: no-op
        #endif
    }
    
    static func readString() -> String? {
        #if os(iOS) || os(tvOS) || os(visionOS)
        return UIPasteboard.general.string
        #elseif os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #else
        return nil
        #endif
    }
}
