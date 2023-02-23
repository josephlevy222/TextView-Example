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
    
    let defaultFont = UIFont.preferredFont(from: .body)
    
    func makeUIView(context: Context) -> UITextView {
        let uiView = MyTextView()
        uiView.font = defaultFont
        uiView.typingAttributes = [.font : defaultFont ]
        uiView.allowsEditingTextAttributes = allowsEditingTextAttributes
        //uiView.editMenu(for: .init(), suggestedActions: [] )
        uiView.contentInset = UIEdgeInsets()
        
        uiView.delegate = context.coordinator
        uiView.attributedText = attributedText.nsAttributedString
        return uiView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
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
            if let newValue = textView.attributedText {
                print("update",newValue)
                self.text.wrappedValue = { do { return try AttributedString(newValue, including: \.uiKit) }
                    catch { return AttributedString(newValue)}}().resetFonts()
            }
        }
    }
    
    class MyTextView: UITextView {
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            let menuController = UIMenuController.shared
            if var menuItems = menuController.menuItems,
               (menuItems.map { $0.action })
                .elementsEqual([.toggleBoldface, .toggleItalics, .toggleUnderline]) {
                // The font style menu is about to become visible
                // Add a new menu item for strikethrough style
                // iOS 16 must use
                //let editMenuInteraction = UIEditMenuInteraction(delegate: UIMenu) //UIEditMenuInteractionDelegate())
                menuItems.append(UIMenuItem(title: "Strikethrough", action: .toggleStrikethrough))
                // UIMenuItem is Deprecated in iOS 16 use UIEditMenuIteraction instead (?)
                menuController.menuItems = menuItems
            }
            return super.canPerformAction(action, withSender: sender)
        }
        
        @objc func toggleStrikethrough(_ sender: Any?) {
            //let controller = sender as? UIMenuController
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllStrikethrough = true
            attributedString.enumerateAttribute(.strikethroughStyle, in: selectedRange, options: []) {(value, range, stopFlag) in
                let strikethrough = value as? NSNumber
                if strikethrough == nil {
                    isAllStrikethrough = false
                    stopFlag.pointee = true
                }
            }
            if isAllStrikethrough {
                attributedString.removeAttribute(.strikethroughStyle, range: selectedRange)
            } else {
                attributedString.addAttribute(.strikethroughStyle, value: 2, range: selectedRange)
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc override func toggleBoldface(_ sender: Any?) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllBold = true
            attributedString.enumerateAttribute(.font, in: selectedRange, options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if let descriptor = uiFont?.fontDescriptor {
                    let isBold = descriptor.symbolicTraits.intersection(.traitBold) == .traitBold
                    isAllBold = isAllBold && isBold
                    if !isBold { stopFlag.pointee = true }
                    print("Boldfacing - Bold: \(isBold), AllBold: \(isAllBold)")
                }
            }
            attributedString.enumerateAttribute(.font, in: selectedRange, options: [.reverse]) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if  let descriptor = uiFont?.fontDescriptor {
                    if let fontDescriptor = isAllBold ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(.traitBold))
                        : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitBold)) {
                        attributedString.addAttribute(.font, value: UIFont(descriptor: fontDescriptor, size: descriptor.pointSize), range: range)
                    }
                }
            }
            attributedText = attributedString
            super.toggleBoldface(sender)
        }
    }
}

fileprivate extension Selector {
    static let toggleBoldface = #selector(TextView.MyTextView.toggleBoldface(_:))
    static let toggleItalics = #selector(TextView.MyTextView.toggleItalics(_:))
    static let toggleUnderline = #selector(TextView.MyTextView.toggleUnderline(_:))
    static let toggleStrikethrough = #selector(TextView.MyTextView.toggleStrikethrough(_:))
}


