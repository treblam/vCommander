//
//  SCTableView.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/14.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTableView: NSTableView {
    
    var markedRows = NSMutableIndexSet()
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    override func keyDown(theEvent: NSEvent) {
        println("SCTableView, keycode " + theEvent.keyCode.description)
        
        var keyString: String
        
        var keyChar: Character
        
        keyString = theEvent.charactersIgnoringModifiers!
        keyChar = keyString[keyString.startIndex]
        
        var row = self.selectedRow
        
        var rowView = self.rowViewAtRow(row, makeIfNecessary: false) as! SCTableRowView
        
        switch theEvent.keyCode {
        case 49:
            if row != -1 {
                println("row != -1")
                if markedRows.containsIndex(row) {
                    self.markedRows.removeIndex(row)
                    rowView.marked = false
                    println("row: " + row.description + " was removed from markedRows")
                } else {
                    self.markedRows.addIndex(row)
                    rowView.marked = true
                    println("row: " + row.description + " was added to markedRows")
                }
                
                println("markedRows: " + markedRows.description)
                
                // TODO: To be reviewed
                if let delegate = self.delegate() as? TabItemController {
                    delegate.tableViewMarkedViewsDidChange()
                }
                
                self.selectRowIndexes(NSIndexSet(index: ++row), byExtendingSelection: false)
                self.setNeedsDisplay()
            }
            
        case 48:
            self.nextResponder?.keyDown(theEvent)
            
        default:
            super.keyDown(theEvent)
            
        }
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        var row = self.rowAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
        if self.markedRows.containsIndex(row) {
            self.markedRows.removeIndex(row)
        } else {
            self.markedRows.addIndex(row)
        }
        
        self.setNeedsDisplay()
    }
    
    func cleanData() {
        markedRows.removeAllIndexes()
    }
    
}
