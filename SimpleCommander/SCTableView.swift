//
//  SCTableView.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/14.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTableView: NSTableView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func keyDown(theEvent: NSEvent) {
        println("SCTableView, keycode " + theEvent.keyCode.description)
        if theEvent.keyCode == 48 {
            self.nextResponder?.keyDown(theEvent)
            return
        }
        
        super.keyDown(theEvent)
    }
    
}
