//
//  ContentView.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//
import SwiftUI

let aText: AttributedString = (AttributedString("Hello,",attributes: AttributeContainer().kern(1.5)).setFont(to: .title2).setItalic()
                               + AttributedString(" world!",attributes: AttributeContainer().foregroundColor(.yellow).backgroundColor(.blue)).setFont(to: .title2)).setBold() + AttributedString(" in body").setFont(to: .body.weight(.ultraLight))

struct ContentView: View {
    
    @State var text : AttributedString
    
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(text)
            Button("Change Text") { text = text.setItalic() }
            
            TextView(attributedText: $text, allowsEditingTextAttributes: true)
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
        ContentView(text: aText)
    }
}


