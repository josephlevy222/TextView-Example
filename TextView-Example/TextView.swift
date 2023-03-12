//
//  TextView.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//  Working for iOS 15 and 16 3/8/23

import SwiftUI

struct TextView: UIViewRepresentable {
    
    @Binding var attributedText: AttributedString
    @State var allowsEditingTextAttributes: Bool = false
    
    let defaultFont = UIFont.preferredFont(from: .body)
    
    func makeUIView(context: Context) -> UITextView {
        let uiView = MyTextView()
        uiView.font = defaultFont
        //uiView.typingAttributes = [.font : defaultFont ]
        uiView.allowsEditingTextAttributes = allowsEditingTextAttributes
        uiView.textContainerInset = .zero
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
            self.text.wrappedValue = {
                do { return try AttributedString(textView.attributedText, including: \.uiKit) }
                catch { return AttributedString(textView.attributedText)}}()
        }
    }
    
    class MyTextView: UITextView {
        // This works in iOS 16 never called in 15 I believe
        open override func buildMenu(with builder: UIMenuBuilder) {
            builder.remove(menu: .lookup) // Lookup, Translate, Search Web
            //builder.remove(menu: .standardEdit) // Keep Cut, Copy, Paste
            //builder.remove(menu: .replace) // Keep Replace
            builder.remove(menu: .share) // Remove Share
            //builder.remove(menu: .textStyle) // Keep Format
            // Add new .textStyle actions
            let strikethroughAction = UIAction(title: "Strikethough") { action in
                self.toggleStrikethrough(action.sender)
            }
            let subscriptAction = UIAction(image: UIImage(systemName: "textformat.subscript")) { action in
                self.toggleSubscript(action.sender)
            }
            let superscriptAction = UIAction(image: UIImage(systemName: "textformat.superscript")) { action in
                self.toggleSuperscript(action.sender)
            }
            builder.replaceChildren(ofMenu: .textStyle)  {
                var children = $0
                children.append(strikethroughAction)
                children.append(subscriptAction)
                children.append(superscriptAction)
                return children
            }
            super.buildMenu(with: builder)
        }
        
        // This is needed for iOS 15
        open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            if #unavailable(iOS 16.0) {
                let menuController = UIMenuController.shared
                if var menuItems = menuController.menuItems,
                   menuItems[0].title == "Bold" && menuItems.count < 6 {
                    
                    menuItems.append(UIMenuItem(title: "Strikethrough", action: .toggleStrikethrough))
                    menuItems.append(UIMenuItem(title: "Subscript", action: .toggleSubscript))
                    menuItems.append(UIMenuItem(title: "Superscript", action: .toggleSuperscript))
                    menuController.menuItems = menuItems
                }
                // Get rid of menu item not wanted
                if action.description.contains("_share") // Share
                    || action.description.contains("_translate") // Translate
                    || action.description.contains("_define") { // Blocks Lookup
                    return false
                }
            }
            return super.canPerformAction(action, withSender: sender)
        }
        
        @objc func toggleStrikethrough(_ sender: Any?) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllStrikethrough = true
            attributedString.enumerateAttribute(.strikethroughStyle,
                                                in: selectedRange,
                                                options: []) { (value, range, stopFlag) in
                let strikethrough = value as? NSNumber
                if strikethrough == nil {
                    isAllStrikethrough = false
                    stopFlag.pointee = true
                }
            }
            if isAllStrikethrough {
                attributedString.removeAttribute(.strikethroughStyle, range: selectedRange)
            } else {
                attributedString.addAttribute(.strikethroughStyle, value: 1, range: selectedRange)
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc override func toggleUnderline(_ sender: Any?) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllUnderlined = true
            attributedString.enumerateAttribute(.underlineStyle,
                                                in: selectedRange,
                                                options: []) { (value, range, stopFlag) in
                let underline = value as? NSNumber
                if  underline == nil  {
                    isAllUnderlined = false
                    stopFlag.pointee = true
                }
            }
            if isAllUnderlined { // Bug in iOS 15 when all selected and underlined?
                attributedString.removeAttribute(.underlineStyle, range: selectedRange)
            } else {
                attributedString.addAttribute(.underlineStyle,
                                              value: 1,
                                              range: selectedRange)
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc override func toggleBoldface(_ sender: Any?) {
            toggleSymbolicTrait(sender, trait: .traitBold)
        }
        
        @objc override func toggleItalics(_ sender: Any?) {
            toggleSymbolicTrait(sender, trait: .traitItalic)
        }
        @objc  func interactions(_ sender: Any?)  {
            print(interactions )
        }
        private func toggleSymbolicTrait(_ sender: Any?, trait: UIFontDescriptor.SymbolicTraits) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAll = true
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) { (value, range, stopFlag) in
                let uiFont = value as? UIFont
                if let descriptor = uiFont?.fontDescriptor {
                    isAll = isAll && descriptor.symbolicTraits.intersection(trait) == trait
                    if !isAll { stopFlag.pointee = true }
                }
            }
            attributedString.enumerateAttribute(.font, in: selectedRange,
                                                options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if  let descriptor = uiFont?.fontDescriptor {
                    let weight = trait != .traitBold ? descriptor.weight : (isAll ? nil : .bold)
                    if let fontDescriptor = isAll ?
                        descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                        : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait)) {
                        attributedString.addAttribute(.font,
                                                      value: UIFont(descriptor: fontDescriptor.withWeight(weight),
                                                                    size: descriptor.pointSize),
                                                      range: range)
                    }
                }
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc func toggleSubscript(_ sender: Any?) { toggleScript(sender, sub: true) }
        
        @objc func toggleSuperscript(_ sender: Any?) { toggleScript(sender, sub: false) }
        
        func toggleScript(_ sender: Any?, sub: Bool = false) {
            let sign = sub ? -1.0 : 1.0
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllScript = true
            attributedString.enumerateAttributes(in: selectedRange,
                                                 options: []) { (attributes, range, stopFlag) in
                if let offset = attributes[.baselineOffset] {
                    let result = (offset as? CGFloat ?? 0.0) * sign
                    if result <=  0.0 { // otherscript or normal
                        isAllScript = false
                        if result < 0.0 { // otherscript
                            // Enlarge font and remove baselineOffset
                            let descriptor: UIFontDescriptor
                            if let font = attributes[.font] as? UIFont {descriptor = font.fontDescriptor }
                            else { descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body) }
                            let newFont = UIFont(descriptor: descriptor, size: descriptor.pointSize/0.75)
                            attributedString.addAttribute(.font, value: newFont, range: range)
                            attributedString.removeAttribute(.baselineOffset, range: range)
                        }
                    }
                }
            }
            attributedString.enumerateAttributes(in: selectedRange,
                                                 options: []) {(attributes, range, stopFlag) in
                let descriptor: UIFontDescriptor
                if let font = attributes[.font] as? UIFont {descriptor = font.fontDescriptor }
                else { descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body) }
                if let offset = attributes[.baselineOffset] , sign*(offset as? CGFloat ?? 0.0) > 0.0 {
                    if isAllScript {
                        attributedString.removeAttribute(.baselineOffset, range: range)
                        let newFont = UIFont(descriptor: descriptor, size: descriptor.pointSize/0.75)
                        attributedString.addAttribute(.font, value: newFont, range: range)
                    }
                } else {
                    attributedString.addAttribute(.baselineOffset, value: (sub ? -0.3 : 0.4)*descriptor.pointSize,
                                                  range: range)
                    let newFont = UIFont(descriptor: descriptor, size: 0.75*descriptor.pointSize)
                    attributedString.addAttribute(.font, value: newFont, range: range)
                }
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
    }
}


fileprivate extension Selector {
    static let toggleBoldface = #selector(TextView.MyTextView.toggleBoldface(_:))
    static let toggleItalics = #selector(TextView.MyTextView.toggleItalics(_:))
    static let toggleUnderline = #selector(TextView.MyTextView.toggleUnderline(_:))
    static let toggleStrikethrough = #selector(TextView.MyTextView.toggleStrikethrough(_:))
    static let toggleSubscript = #selector(TextView.MyTextView.toggleSubscript(_:))
    static let toggleSuperscript = #selector(TextView.MyTextView.toggleSuperscript(_:))
}



