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
        uiView.textContainerInset = .zero
        if #available(iOS 16.0, *) {
            //uiView.editMenu(for: .init(), suggestedActions: [] )
        } else {
            // Fallback on earlier versions
        } //iOS 16 only
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
        
        func editMenu(for textRange: UITextRange, suggestedActions: [UIMenuElement]) -> UIMenu? {
            let indentationMenu = UIMenu(title: "Indentation", image: UIImage(systemName: "list.bullet.indent"), children: [
                UIAction(title: "Increase", image: UIImage(systemName: "increase.indent")) { (action) in
                    // Increase indentation action.
                },
                UIAction(title: "Decrease", image: UIImage(systemName: "decrease.indent")) { (action) in
                    // Decrease indentation action.
                }
            ])
            
            var actions = suggestedActions
            actions.append(indentationMenu)
            return UIMenu(children: actions)
        }
        func textViewDidChange(_ textView: UITextView) {
            let oldValue = textView.attributedText ?? NSAttributedString()
            let newValue = NSMutableAttributedString(attributedString: oldValue)
            print("update",newValue)
            let newAS = { do { return try AttributedString(oldValue, including: \.uiKit) }
                catch { return AttributedString(oldValue)}}().resetFonts()
            self.text.wrappedValue = {
                var aString = AttributedString()
                newValue.enumerateAttributes(in: NSRange(location: 0, length: newValue.length)) { (attributes, range, stopFlag) in
                    var newRun = AttributedString()
                    if let indexRange = Range(range, in: newAS) {
                        newRun = AttributedString(newAS[indexRange])
                        if let strikethroughStyle = attributes[.strikethroughStyle] {
                            newRun.strikethroughStyle = strikethroughStyle as? Text.LineStyle ?? .init(pattern: .solid, color: nil)
                        }
                    }
                    aString.append(newRun)
                }
                return aString.resetFonts()
            }()
            textView.attributedText = text.wrappedValue.nsAttributedString
        }
    }

    class MyTextView: UITextView {
        
        override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
            let menuController = UIMenuController.shared
            if var menuItems = menuController.menuItems,
               (menuItems.map { $0.title })
                .elementsEqual(["Bold", "Italic", "Underline"]) {
                // The font style menu is about to become visible -- Add a new menu item for strikethrough style
                // iOS 16 must use UIEditMenuIteraction instead (How?) since UIMenuItem is deprecated in iOS 16
                //let editMenuInteraction = UIEditMenuInteraction(delegate: UIMenu) //UIEditMenuInteractionDelegate())
                menuItems.append(UIMenuItem(title: "Strikethrough", action: .toggleStrikethrough))
                menuItems.append(UIMenuItem(title: "More", action: .moreItems))
                menuController.menuItems = menuItems
            }
            return super.canPerformAction(action, withSender: sender)
        }
        
        @objc func toggleStrikethrough(_ sender: Any?) {
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
                attributedString.addAttribute(.strikethroughStyle, value: 1, range: selectedRange)
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc override func toggleUnderline(_ sender: Any?) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAllUnderlined = true
            attributedString.enumerateAttribute(.underlineStyle, in: selectedRange, options: []) {(value, range, stopFlag) in
                let underline = value as? NSNumber ?? 0
                if underline == 0  {
                    isAllUnderlined = false
                    stopFlag.pointee = true
                }
            }
            attributedString.enumerateAttributes(in: selectedRange, options: []) {(value, range, stopFlag) in
                if isAllUnderlined {
                    attributedString.removeAttribute(.underlineStyle, range: range)
                } else {
                    attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                }
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
        
        private func toggleSymbolicTrait(_ sender: Any?, trait: UIFontDescriptor.SymbolicTraits) {
            let attributedString = NSMutableAttributedString(attributedString: attributedText)
            var isAll = true
            attributedString.enumerateAttribute(.font, in: selectedRange, options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if let descriptor = uiFont?.fontDescriptor {
                    let isTrait = descriptor.symbolicTraits.intersection(trait) == trait
                    isAll = isAll && isTrait
                    if !isTrait { stopFlag.pointee = true }
                }
            }
            attributedString.enumerateAttribute(.font, in: selectedRange, options: []) {(value, range, stopFlag) in
                let uiFont = value as? UIFont
                if  let descriptor = uiFont?.fontDescriptor {
                    if let fontDescriptor = isAll ? descriptor.withSymbolicTraits(descriptor.symbolicTraits.subtracting(trait))
                        : descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(trait))?.withWeight(trait == .traitBold ? .bold : nil ) {
                                              //       Needed to fix Title0 bug in UITextView  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                        attributedString.addAttribute(.font, value: UIFont(descriptor: fontDescriptor, size: descriptor.pointSize), range: range)
                    }
                }
            }
            attributedText = attributedString
            if let update = self.delegate?.textViewDidChange { update(self) }
        }
        
        @objc func toggleSubscript(_ sender: Any?) {
            print("toggleSubscript pressed")
        }
        
        @objc func moreItems(_ sender: Any?) {
            print("moreItems pressed")
        }
    }
}

fileprivate extension Selector {
    static let toggleBoldface = #selector(TextView.MyTextView.toggleBoldface(_:))
    static let toggleItalics = #selector(TextView.MyTextView.toggleItalics(_:))
    static let toggleUnderline = #selector(TextView.MyTextView.toggleUnderline(_:))
    static let toggleStrikethrough = #selector(TextView.MyTextView.toggleStrikethrough(_:))
    static let moreItems = #selector(TextView.MyTextView.moreItems(_:))
    //static let toggleSubscript = #selector(TextView.MyTextView.toggleSubscript(_:))
}


