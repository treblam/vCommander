//
//  VerticallyCenteredTextField.swift
//  SimpleCommander
//
//  Created by Jamie on 15/7/19.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class VerticallyCenteredTextField: NSTextFieldCell {
    override func titleRectForBounds(theRect: NSRect) -> NSRect {
        var titleFrame = super.titleRectForBounds(theRect)
        let titleSize = self.attributedStringValue.size
        titleFrame.origin.y = theRect.origin.y - 1.0 + (theRect.size.height - titleSize().height) / 2.0
        return titleFrame
    }
    
    override func drawInteriorWithFrame(cellFrame: NSRect, inView controlView: NSView) {
        let titleRect = self.titleRectForBounds(cellFrame)
        self.attributedStringValue.drawInRect(titleRect)
    }
}
