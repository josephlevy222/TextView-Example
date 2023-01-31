# TextView-Example
A UIKit UITextView is created for use with SwiftUI that takes an AttributedString binding

TextView takes a binding to an AttributedString and the flag allowsEditingTextAttributes
the flag defaults to false. If true the attributes (at least some of them) can be edited
in TextView which has a NSAttributedString converted from the AttributedString and converts
any changes back to the AttributedString.  

The tricky part was that there is no support for SwiftUI.Font conversion to UIFont and so all
the SwiftUI.Fonts ended up as the default UIFont which is Helvatica 12pt.  This lead me down a
rabbit hole of how to make UIFonts from SwiftUI.Fonts.  

I found an article at https://movingparts.io/fonts-in-swiftui 
Titled: UIFont - SwiftUI under the Hood: Fonts 
The article showed a way to convert the SwiftUI fonts to UIFonts using the Mirror function after the 
SwiftUI fonts were examined with dump(font).  The code in the article didn't work probably because of 
changes to Swift since it was written but the idea was there and I added a number of things to the code
to make a general converter for SwiftUI.Fonts to UIFonts.  

As I write this the an AttributedString with SwiftUI Fonts converts to an NSAttributedString with UIFont and back for
regular, bold, italic, and underline text in the dynamic sizes and custom sizes in my testing.  I have not tested the 
various designs, like monospace, etc, or strikethrough, superscripts, subscripts, and colors to name a few.  Only a few 
modifiers like bold and italic are included but weight and I'm sure others are not. 

It is far from complete and I hope some will take
interest in filling in more cases. 

