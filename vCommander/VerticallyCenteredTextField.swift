//
//  VerticallyCenteredTextField.swift
//  vCommander
//
//  Created by Jamie on 15/7/19.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class VerticallyCenteredTextField: NSTextFieldCell {
    override func titleRect(forBounds theRect: NSRect) -> NSRect {
        var titleFrame = super.titleRect(forBounds: theRect)
        let titleSize = self.attributedStringValue.size
        titleFrame.origin.y = theRect.origin.y - 1.0 + (theRect.size.height - titleSize().height) / 2.0
        return titleFrame
    }
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let titleRect = self.titleRect(forBounds: cellFrame)
        self.attributedStringValue.draw(in: titleRect)
    }
}
