//
//  ContentView.swift
//  TextView-Example
//
//  Created by Joseph Levy on 1/31/23.
//
import SwiftUI

let aText: AttributedString = AttributedString("Big").setFont(to: .largeTitle).setItalic().setBold() + (AttributedString(" Hello,",attributes: AttributeContainer().kern(3)).setFont(to: .title2).setItalic()
    + AttributedString(" world!",attributes: AttributeContainer().foregroundColor(.yellow).backgroundColor(.blue)).setFont(to: .title2)).setBold() + AttributedString(" in body").setFont(to: .body.weight(.ultraLight))

let dumpfont = Font.body.weight(.ultraLight).italic().bold()

struct ContentView: View {
    
    @State var text : AttributedString
    //{ didSet {  nsText = NSAttributedString(text) } }
    //@State var nsText: NSAttributedString
    @State var state: Int = 0
    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            TextView(attributedText: $text, allowsEditingTextAttributes: true).frame(height: 100)
            //UTextView(attributedText: $nsText, allowsEditingTextAttributes: true).frame(height: 100)
            Text(text)
                .textSelection(.enabled)
                .padding(4)
              
            Button("Change Text") {
                state = state + 1
                if state == 5 { state = 0 }
                switch state {
                case 0: text = aText
                case 1: text = text.setItalic()
                case 2: text = text.setBold();
                case 3: text = text.setItalic()
                case 4: text = text.setBold()
                default: break
                }
                print(state); attributedStringDump(text)
            }
            Spacer()
        }
        .padding()
//            .onAppear {
//        //            print("Dumping Font.body.weight(.ultraLight");
//                    dump(dumpfont)
//                    print(resolveFont(dumpfont)?.font(with: nil))
//                print(state)
//                attributedStringDump(text)
//                }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(text: aText)
    }
}


func attributedStringDump(_ text: AttributedString) {
//    for run in text.runs {
//        //print("\(text[run.range]){")
//        dump(run)
//    }
//    print(text.nsAttributedString)
}
