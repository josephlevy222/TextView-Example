//
//  TextView.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//

import SwiftUI

struct TextView: UIViewRepresentable {
    @Binding var attributedText: AttributedString 
    @State var allowsEditingTextAttributes: Bool = false
    
    let defaultFont = UIFont.preferredFont(from: .body ) // as CTFont
    
    func makeUIView(context: Context) -> UITextView {
        let uiView = UITextView()
        uiView.font = defaultFont
        uiView.typingAttributes = [.font : defaultFont ]
        uiView.allowsEditingTextAttributes = allowsEditingTextAttributes
        uiView.editMenu(for: .init(), suggestedActions: [] )
        uiView.contentInset = UIEdgeInsets()
        
        uiView.delegate = context.coordinator
        uiView.attributedText = attributedText.nsAttributedString
        //attributedText = AttributedString(uiView.attributedText)
        return uiView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        print("updateUIView")
        uiView.attributedText = attributedText.nsAttributedString
    }
    
    func makeCoordinator() -> TextView.Coordinator {
        Coordinator($attributedText)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<AttributedString>
        
        init(_ text: Binding<AttributedString>) {
            self.text = text
        }
        
        func textViewDidChange(_ textView: UITextView) {
            print("textViewDidChange")
            self.text.wrappedValue = AttributedString(textView.attributedText ?? NSAttributedString(""))
        }
    }
}


struct UTextView: UIViewRepresentable {
    
    @Binding var attributedText: NSAttributedString
    var change: Bool = false
    @State var allowsEditingTextAttributes: Bool = false
    
    let defaultFont = UIFont.preferredFont(from: .body ) // as CTFont
    
    func makeUIView(context: Context) -> UITextView {
        let uiView = UITextView()
        uiView.font = defaultFont
        uiView.typingAttributes = [.font : defaultFont ]
        uiView.allowsEditingTextAttributes = allowsEditingTextAttributes
        uiView.editMenu(for: .init(), suggestedActions: [] )
        uiView.contentInset = UIEdgeInsets()
        
        uiView.delegate = context.coordinator
        uiView.attributedText = attributedText//.nsAttributedString
        
        return uiView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        print("updateUIView")
        uiView.attributedText = attributedText//.nsAttributedString
    }
    
    func makeCoordinator() -> UTextView.Coordinator {
        Coordinator($attributedText)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<NSAttributedString>
        
        init(_ text: Binding<NSAttributedString>) {
            self.text = text
        }
        
        func textViewDidChange(_ textView: UITextView) {
            self.text.wrappedValue = /*AttributedString*/(textView.attributedText ?? NSAttributedString(""))
        }
    }
}
