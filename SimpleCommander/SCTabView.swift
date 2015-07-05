//
//  SCTabView.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/14.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTabView: NSTabView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func insertTab(sender: AnyObject?) {
        println("aaaa")
        
        let mainWindowController = self.window?.windowController() as! MainWindowController
        mainWindowController.switchFocus()
    }
    
    override func insertBacktab(sender: AnyObject?) {
        println("bbbb")
        self.window!.selectPreviousKeyView(sender)
    }
    
}
