//
//  ContentView.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//
import SwiftUI

let aText: AttributedString = AttributedString("Big").setFont(to: .largeTitle).setItalic() + (AttributedString(" Hello,",attributes: AttributeContainer().kern(1.5)).setFont(to: .title2).setItalic()
    + AttributedString(" world!",attributes: AttributeContainer().foregroundColor(.yellow).backgroundColor(.blue)).setFont(to: .title2)).setBold() + AttributedString(" in body").setFont(to: .body.weight(.ultraLight))


struct ContentView: View {
    
    @State var text : AttributedString
    { didSet {  nsText = NSAttributedString(text) } }
    @State var nsText: NSAttributedString
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(text)
                .textSelection(.enabled)
                .padding(4)
            
            TextView(attributedText: $text, allowsEditingTextAttributes: true).frame(height: 100)
            //UTextView(attributedText: $nsText, allowsEditingTextAttributes: true).frame(height: 100)
            Button("Change Text") {
                text = text.setItalic() }
            Spacer()
        }
        .padding()
        //        .onAppear {
        //            let dumpfont = Font.body.weight(.ultraLight)
        //            print("Dumping Font.body.weight(.ultraLight"); dump(dumpfont)
        //            print(resolveFont(dumpfont)?.font(with: nil))
        //        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(text: aText.convertToUICompatible(), nsText: aText.nsAttributedString)
    }
}


