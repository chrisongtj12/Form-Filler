//
//  ContentView.swift
//  Form Filler
//
//  Created by Christopher Ong on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    @Binding var document: Form_FillerDocument

    var body: some View {
        TextEditor(text: $document.text)
    }
}

#Preview {
    ContentView(document: .constant(Form_FillerDocument()))
}
