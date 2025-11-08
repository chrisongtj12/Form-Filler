//
//  Form_FillerApp.swift
//  Form Filler
//
//  Created by Christopher Ong on 8/11/25.
//

import SwiftUI

@main
struct Form_FillerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: Form_FillerDocument()) { file in
            ContentView(document: file.$document)
        }
    }
}
