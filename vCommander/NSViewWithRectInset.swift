//
//  NSViewWithRectInset.swift
//  vCommander
//
//  Created by Jamie on 2017/2/23.
//  Copyright © 2017年 Jamie. All rights reserved.
//

import Cocoa

class NSViewWithRectInset: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override var alignmentRectInsets: NSEdgeInsets {
        return NSEdgeInsets(top: 0, left: 0, bottom: 50.0, right: 0)
    }
    
}
