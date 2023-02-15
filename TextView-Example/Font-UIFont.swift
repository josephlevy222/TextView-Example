//
//  Font-UIFont.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//

import SwiftUI
// Conversion code for SwiftUI.Font to UIFont and AttributedString to
// NSAttributedString Starts here
extension UIFont {
    convenience init(font: Font, traitCollection: UITraitCollection? = nil) {
        if let uiFont = resolveFont(font) { self.init(descriptor: uiFont.fontDescriptor(with: traitCollection), size: 0)}
        else { self.init() }
    }
}

extension AttributedString {
    
    var nsAttributedString : NSAttributedString { print("Converting", self); return convertToUIAttributes() }
    
    func convertToUICompatible(traitCollection: UITraitCollection? = nil) -> AttributedString {
        AttributedString(convertToUIAttributes(traitCollection: traitCollection))
    }
    
    func convertToUIAttributes(traitCollection: UITraitCollection? = nil) -> NSMutableAttributedString {
        var nsAttributes = [NSAttributedString.Key : Any ]()
        let nsAttributedString = NSMutableAttributedString(self)
        for run in runs {
            print("Run of: ",self[run.range])
            let nsRange = NSRange(run.range, in: self[run.range])
            // Handle font  /// A property for accessing a font attribute.
            let isNSFont = run.attributes.description.contains("NSFont")
            if !isNSFont {
                if let uiFont = resolveFont(run.font ?? .body)?.font(with: traitCollection) {
                    nsAttributes[.font] = uiFont
                    print("Now with NSFont: \(uiFont) with weight \(String(describing: uiFont.weight))")
                }
            } else { //NSFont
                
            }
            // Handle other SwiftUIAttributes
            // foregroundColor /// A property for accessing a foreground color attribute.
            if let color = run.foregroundColor { nsAttributes[.foregroundColor] = UIColor(color) }
            else { if !isNSFont { nsAttributes.removeValue(forKey:.foregroundColor) }}
            // backgroundColor /// A property for accessing a background color attribute.
            if let color = run.backgroundColor {  nsAttributes[.backgroundColor] = UIColor(color) }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .backgroundColor) }}
            // strikethrough /// A property for accessing a strikethrough style attribute.
            if let strikethroughStyle = run.strikethroughStyle { nsAttributes[.strikethroughStyle] = strikethroughStyle }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .strikethroughStyle) }}
            // underlineStyle /// A property for accessing an underline style attribute.
            if let underlineStyle = run.underlineStyle { nsAttributes[.underlineStyle] = underlineStyle }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .underlineStyle) }}
            // kern /// A property for accessing a kerning attribute.
            if let kern = run.kern { nsAttributes[.kern] = kern }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .kern) }}
            // tracking /// A property for accessing a tracking attribute.
            if  let tracking = run.tracking { nsAttributes[.tracking] = tracking }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .tracking) }}
            // baselineOffset /// A property for accessing a baseline offset attribute.
            if let baselineOffset = run.baselineOffset { nsAttributes[.baselineOffset] = baselineOffset }
            else { if !isNSFont { nsAttributes.removeValue(forKey: .baselineOffset) }}
            if !nsAttributes.isEmpty {
                nsAttributedString.setAttributes(nsAttributes, range: nsRange)
            }
    }
    return nsAttributedString
}
}

// AttributedString(styledMarkdown: String, fonts: [Font]) puts fonts into Headers 1-6
// and setFont for SwiftUI.Font, along with setBold, and setItalic that work with SwiftUI.Font and UIFont
// embedded in the attributed string
fileprivate let defaultHeaderFonts: [Font] = [.body,.largeTitle,.title,.title2,.title3,.headline,.subheadline]

extension AttributedString {
    init(styledMarkdown markdownString: String, fonts: [Font] = defaultHeaderFonts) throws {
        let output = try AttributedString(
            markdown: markdownString,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .full,
                failurePolicy: .returnPartiallyParsedIfPossible
            ),
            baseURL: nil
        )
        self = output
        self = styledHeaders(fonts: fonts)
        
    }
    
    func styledHeaders(fonts: [Font] = defaultHeaderFonts) -> AttributedString {
        var output = self
        for (intentBlock, intentRange) in output.runs[AttributeScopes.FoundationAttributes.PresentationIntentAttribute.self].reversed() {
            guard let intentBlock = intentBlock else { continue }
            for intent in intentBlock.components {
                for level in 1..<fonts.count where intent.kind == .header(level: level) {
                    print("header level \(level)")
                    output[intentRange].font = UIFont.preferredFont(from: fonts[level]) as CTFont
                }
            }
            
            if intentRange.lowerBound != output.startIndex {
                output.characters.insert(contentsOf: "\n", at: intentRange.lowerBound)
            }
        }
        return output
    }
    
    func setFont(to: Font) -> AttributedString {
        var a = self
        a.font = to
        return a
    }
    
    func setBold() -> AttributedString {
        var newAS = self
        for run in runs {
            if let font = run.font { newAS[run.range].font = font.bold() }
            else { // assume NSFont
                let uiFont = run.attributes.font ?? UIFont.preferredFont(forTextStyle: .body)
                newAS[run.range].font = uiFont.bold()
            }
        }
        return newAS
    }
    
    func setItalic() -> AttributedString {
        var newAS = self
        for run in runs {
            if let font = run.font { newAS[run.range].font = font.italic() }
            else { // assume NSFont
                let uiFont = run.attributes.font ?? UIFont.preferredFont(forTextStyle: .body)
                newAS[run.range].font = uiFont.italic()
            }
        }
        return newAS
    }
    
    func resetFonts() -> AttributedString {
        var newAS = self
        for run in runs {
            if let font = run.font { newAS[run.range].font = font }
            else {
                let ctFont = run.attributes.font ?? UIFont.preferredFont(forTextStyle: .body)
                let weight = ctFont.weight
                let width = ctFont.width
                let attributesDescription = run.attributes.description
                if  let r1 = attributesDescription.range(of: "font-family: \""),
                    let r2 = attributesDescription.range(of: "\"",
                                                         range: r1.upperBound..<attributesDescription.endIndex) {
                    let styleString = attributesDescription[r1.upperBound..<r2.lowerBound]
                    let style = UIFont.TextStyle(rawValue: String(styleString))
                    let uiFont = UIFont.preferredFont(forTextStyle: style).withWeight(weight).withWidth(width)
                    newAS[run.range].font = uiFont
                }
            }
        }
        return newAS
    }
}

extension UIFontDescriptor {
    func withWeight(_ weight: UIFont.Weight?) -> UIFontDescriptor {
        if let weight { return addingAttributes([.traits: [UIFontDescriptor.TraitKey.weight: weight]])} else { return self }
    }
    func withWidth(_ width: UIFont.Width?) -> UIFontDescriptor {
        if let width { return addingAttributes([.traits: [UIFontDescriptor.TraitKey.width: width]]) } else { return self }
    }
    var weight: UIFont.Weight { // nil means no weight trait is set
        let traits = object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
        guard let weightNumber = traits[.weight] as? NSNumber else { return .regular }
        return UIFont.Weight(rawValue: weightNumber.doubleValue)
    }
    var width: UIFont.Width {
        let traits = object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
        guard let widthNumber = traits[.width] as? NSNumber else { return .standard }
        return UIFont.Width(rawValue: widthNumber.doubleValue)
    }
}

extension UIFont {
    // get font weight
    var weight: UIFont.Weight? { fontDescriptor.weight }
    // get font width
    var width: UIFont.Width { fontDescriptor.width }
    
    // Add bold trait
    func bold() -> UIFont? {
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(.traitBold))
        else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize).withWidth(width)
    }
    
    // Add italic trait
    func italic() -> UIFont? {
        guard let newDescriptor = fontDescriptor.withSymbolicTraits(fontDescriptor.symbolicTraits.union(.traitItalic))
        else { return nil }
        return UIFont(descriptor: newDescriptor, size: pointSize).withWeight(weight).withWidth(width)
    }
    
    func withWeight(_ weight: UIFont.Weight?) -> UIFont {
        guard let weight else { return self }
        return UIFont(descriptor: fontDescriptor.withWeight(weight), size: pointSize)
    }
    
    func withWidth(_ width: UIFont.Width?) -> UIFont {
        guard let width else { return self }
        return UIFont(descriptor: fontDescriptor.withWidth(width), size: pointSize)
    }
    
    static var styleDictionary: [Font.TextStyle : UIFont.TextStyle] = [
        .largeTitle : .largeTitle, .title : .title1, .title2 : .title2,
        .title3 : .title3, .headline : .headline, .callout : .callout,
        .caption : .caption1, .caption2 : .caption2, .footnote : .footnote,
        .body : .body
    ]
    
    static var fontDictionary: [ Font : UIFont.TextStyle ] = [
        .largeTitle : .largeTitle, .title : .title1, .title2 : .title2,
        .title3 : .title3, .headline : .headline, .callout : .callout,
        .caption : .caption1, .caption2 : .caption2, .footnote : .footnote,
        .body : .body
    ]
    
    // Return UIFont.TextStyle from SwiftUI.Font.TextStyle
    class func preferredFontStyle(from: Font.TextStyle) -> UIFont.TextStyle {
        styleDictionary[from] ?? .body
    }
    // Return UIFont from SwiftUI.Font
    class func preferredFont(from font: Font) -> UIFont {
        let style = fontDictionary[font] ?? .body
        let uiFont = UIFont.preferredFont(forTextStyle: style)
        //print("\(style): \(uiFont.fontName) @ \(uiFont.pointSize)")
        return uiFont
    }
}
// To convert Font to UIFont
// First, we define protocols for providers and modifiers
protocol FontProvider {
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor
}

extension FontProvider {
    func font(with traitCollection: UITraitCollection?) -> UIFont {
        UIFont(descriptor: fontDescriptor(with: traitCollection), size: 0)
    }
}

protocol FontModifier {
    func modify(_ fontDescriptor: inout UIFontDescriptor)
}

protocol StaticFontModifier: FontModifier {
    init()
}

protocol FontValueModifier: FontModifier {
    init(value: Any)
}

//Next, we can implement the “root” providers, for example System­Provider and Named­Provider:
struct SystemProvider: FontProvider {
    var size: CGFloat
    var design: UIFontDescriptor.SystemDesign
    var weight: UIFont.Weight?
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor {
        UIFont
            .preferredFont(forTextStyle: .body, compatibleWith: traitCollection)
            .fontDescriptor
            .withDesign(design)!
            .addingAttributes([
                .size: size
            ])
    }
}

struct NamedProvider: FontProvider {
    var name: String
    var size: CGFloat
    var textStyle: UIFont.TextStyle?
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor {
        if let textStyle {
            let metrics = UIFontMetrics(forTextStyle: textStyle )
            return UIFontDescriptor(fontAttributes: [
                .family: name,
                .size: metrics.scaledValue(for: size, compatibleWith: traitCollection)
            ])
        } else {
            return UIFontDescriptor(fontAttributes: [
                .family: name,
                .size: size
            ])
        }
    }
}

struct TextStyleProvider: FontProvider {
    var style: UIFont.TextStyle?
    var design: UIFontDescriptor.SystemDesign
    var weight: UIFont.Weight?
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor {
        let uiFont = UIFont
            .preferredFont(forTextStyle: style ?? UIFont.TextStyle(rawValue: "UICTFontTextStyleBody"), compatibleWith: traitCollection)
            .withWeight(weight)
        //if let style { print("style=\(style)") } else { print("style = .body")}
        if let descriptor = uiFont.fontDescriptor
            .withDesign(design)?
            .addingAttributes([.size : uiFont.pointSize])
            .withWeight(weight) {
            return descriptor
        }
        return uiFont.fontDescriptor
    }
}
// The ModifierProvider holds a a reference to another FontProvider and a value
struct ModifierProvider<M: FontValueModifier> : FontProvider {
    var base: FontProvider
    var value: CGFloat
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor {
        var descriptor = base.fontDescriptor(with: traitCollection)
        M(value: value).modify(&descriptor)
        return descriptor
    }
}

struct WidthModifier: FontValueModifier {
    func modify(_ fontDescriptor: inout UIFontDescriptor) {
        if let width {
            fontDescriptor = fontDescriptor.withWidth(width) }
    }
    var width : UIFont.Width?
    init(value: Any) { self.width = UIFont.Width(value as? CGFloat ?? 0.0) }
}

struct WeightModifier: FontValueModifier {
    func modify(_ fontDescriptor: inout UIFontDescriptor) {
        if let weight {
            fontDescriptor = fontDescriptor.withWeight(weight) }
    }
    var weight : UIFont.Weight?
    init(value: Any) { self.weight = UIFont.Weight(value as? CGFloat ?? 0.0) }
}

//The Static­Modifier­Provider holds a reference to another Font­Provider:
struct StaticModifierProvider<M: StaticFontModifier>: FontProvider {
    var base: FontProvider
    func fontDescriptor(with traitCollection: UITraitCollection?) -> UIFontDescriptor {
        var descriptor = base.fontDescriptor(with: traitCollection)
        M().modify(&descriptor)
        return descriptor
    }
}

//The Italic­Modifier is handed a UIFont­Descriptor and adds trait­Italic:
struct ItalicModifier: StaticFontModifier {
    init() {}
    func modify(_ fontDescriptor: inout UIFontDescriptor) {
        let weight = fontDescriptor.weight
        let traits = fontDescriptor.symbolicTraits.union(.traitItalic)
        if let fd = fontDescriptor.withSymbolicTraits(traits) {
            fontDescriptor = weight == .regular ? fd : fd.withWeight(weight)
        } else { print("fontDescriptor can't be made italic") }
    }
}
//The BoldModifier is handed a UIFont­Descriptor and adds trait­Bold:
struct BoldModifier: StaticFontModifier {
    init() {}
    func modify(_ fontDescriptor: inout UIFontDescriptor) {
        let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any] ?? [:]
        //print("Traits in BoldModifier: ", traits)
        let traits0 = fontDescriptor.symbolicTraits.union(.traitBold)
        fontDescriptor = fontDescriptor.withSymbolicTraits(traits0) ?? fontDescriptor
    }
}

/// With the providers in place, we now need to initialize them with the data we saw in our dumps earlier.
/// Through reflection, we can attempt to access the provider property of a Font and match its type against one of
/// the types we've discovered earlier. Based on the type, we then read the relevant properties such as text style
/// or font weight and create a parallel hierarchy of our own structs.
func resolveFont(_ font: Font) -> FontProvider? {
    let mirror = Mirror(reflecting: font)
    guard let provider = mirror.descendant("provider", "base") else {
        return nil
    }
    return resolveFontProvider(provider)
}

func resolveFontProvider(_ provider: Any) -> FontProvider? {
    let mirror = Mirror(reflecting: provider)
    //print("Mirroring: ", mirror)
    let providerType = String(describing: type(of: provider))
    switch providerType {
        
    case "StaticModifierProvider<ItalicModifier>":
        guard let base = mirror.descendant("base", "provider", "base") else {
            return nil
        }
        return resolveFontProvider(base).map(StaticModifierProvider<ItalicModifier>.init)
        
    case "StaticModifierProvider<BoldModifier>":
        guard let base = mirror.descendant("base", "provider", "base") else {
            return nil
        }
        return resolveFontProvider(base).map(StaticModifierProvider<BoldModifier>.init)
        
    case "SystemProvider":
        guard let size = mirror.descendant("size") as? CGFloat,
              let design = mirror.descendant("design") as? UIFontDescriptor.SystemDesign else {
            return nil
        }
        let weight = mirror.descendant("weight") as? UIFont.Weight
        return SystemProvider(size: size, design:  design, weight: weight)
        
    case "NamedProvider":
        guard let name = mirror.descendant("name") as? String,
              let size = mirror.descendant("size") as? CGFloat else {
            return nil
        }
        let textStyle = mirror.descendant("textStyle") as? UIFont.TextStyle
        return NamedProvider(name: name, size: size, textStyle: textStyle)
        
    case "TextStyleProvider":
        guard let style = mirror.descendant("style") as? Font.TextStyle else {
            return nil
        }
        let design = mirror.descendant("design") as? UIFontDescriptor.SystemDesign ?? UIFontDescriptor.SystemDesign.default
        let weight = mirror.descendant("weight") as? UIFont.Weight ; print("TextStyleProvider weight: \(String(describing: weight))")
        let uiStyle = UIFont.preferredFontStyle(from: style)
        return TextStyleProvider(style: uiStyle, design: design , weight: weight)
        
    case "ModifierProvider<WeightModifier>":
        guard let base = mirror.descendant("base", "provider", "base"),
              let weight = mirror.descendant("modifier", "weight", "value")  else {
            return nil
        }
        return resolveFontProvider(base).map {base in ModifierProvider<WeightModifier>(base: base, value: weight as! CGFloat) }
        
    case "ModifierProvider<WidthModifier>":
        guard let base = mirror.descendant("base", "provider", "base"),
              let width = mirror.descendant("modifier", "width", "value")  else {
            return nil
        }
        return resolveFontProvider(base).map {base in ModifierProvider<WidthModifier>(base: base, value: width as! CGFloat) }
        
        // Not exhaustive, more providers need to be handled here.
    default:
        // Maybe it is already a UIFont
        print("Default case")
        // if its a UIFont the FontProvider needs to reflect that
        return nil
    }
}















