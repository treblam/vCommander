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
    
    func convertToInt(str: String) -> Int {
        let s1 = str.unicodeScalars
        let s2 = s1[s1.startIndex].value
        return Int(s2)
    }
    
    override func keyDown(theEvent: NSEvent) {
        Swift.print("SCTableView, keycode " + theEvent.keyCode.description)
        
//        var keyString: String
        
        //var keyChar: Character
        
//        var rowView: SCTableRowView!
        
//        keyString = theEvent.charactersIgnoringModifiers!
        //keyChar = keyString[keyString.startIndex]
        
        let row = self.selectedRow
        
        let flags = theEvent.modifierFlags
        
        let s = theEvent.charactersIgnoringModifiers!
        
        let char = convertToInt(s)
        
        Swift.print("char:" + String(char))
        
        let hasCommand = flags.contains(.CommandKeyMask)
        
        let hasShift = flags.contains(.ShiftKeyMask)
        
        let hasAlt = flags.contains(.AlternateKeyMask)
        
        let hasControl = flags.contains(.ControlKeyMask)
        
        Swift.print("hasCommand: " + String(hasCommand))
        Swift.print("hasShift: " + String(hasShift))
        Swift.print("hasAlt: " + String(hasAlt))
        Swift.print("hasControl: " + String(hasControl))
        
        let noneModifiers = !hasCommand && !hasShift && !hasAlt && !hasControl
        
        Swift.print("noneModifiers: " + String(noneModifiers))

        
        let NSSpaceFunctionKey = 32
        let NSTabFunctionKey = 9
        
//        if row != -1 {
//            rowView = self.rowViewAtRow(row, makeIfNecessary: false) as! SCTableRowView
//        }
        
        switch char {
        case NSSpaceFunctionKey:    // space key
            if row != -1 {
                Swift.print("row != -1")
                if markedRows.containsIndex(row) {
                    self.markedRows.removeIndex(row)
//                    rowView.marked = false
                    Swift.print("row: " + row.description + " was removed from markedRows")
                } else {
                    self.markedRows.addIndex(row)
//                    rowView.marked = true
                    Swift.print("row: " + row.description + " was added to markedRows")
                }
                
                Swift.print("markedRows: " + markedRows.description)
                
                notifyDelegate()
                
//                self.selectRowIndexes(NSIndexSet(index: ++row), byExtendingSelection: false)
                self.setNeedsDisplay()
            }
            
        case NSTabFunctionKey:  // tab键
            self.nextResponder?.keyDown(theEvent)
            
// Temporarily comment vim mode, make normal mode ease to use first.
//        case convertToInt("j") where noneModifiers:  // j 模拟vim快捷键
//            var char = unichar(NSDownArrowFunctionKey)
//            let characterString = NSString(characters: &char, length: 1)
//            
//            let event = NSEvent.keyEventWithType(NSEventType.KeyDown, location: theEvent.locationInWindow, modifierFlags: theEvent.modifierFlags, timestamp: theEvent.timestamp, windowNumber: theEvent.windowNumber, context: nil, characters: characterString as String, charactersIgnoringModifiers: characterString as String, isARepeat: theEvent.ARepeat, keyCode: char)
//            
//            super.keyDown(event!)
//            
//        case convertToInt("k") where noneModifiers:  // k 模拟vim快捷键
//            var char = unichar(NSUpArrowFunctionKey)
//            let characterString = NSString(characters: &char, length: 1)
//            
//            let event = NSEvent.keyEventWithType(NSEventType.KeyDown, location: theEvent.locationInWindow, modifierFlags: theEvent.modifierFlags, timestamp: theEvent.timestamp, windowNumber: theEvent.windowNumber, context: nil, characters: characterString as String, charactersIgnoringModifiers: characterString as String, isARepeat: theEvent.ARepeat, keyCode: char)
//            
//            super.keyDown(event!)
            
        default:
            super.keyDown(theEvent)
            
        }
    }
    
    func notifyDelegate() {
        // TODO: To be reviewed
        if let delegate = self.delegate() as? TabItemController {
            delegate.tableViewMarkedViewsDidChange()
        }
    }
    
    func isRowMarked(row: Int) -> Bool {
        return markedRows.containsIndex(row)
    }
    
    func markRowIndexes(indexes: NSIndexSet, byExtendingSelection extend: Bool) {
        if !extend {
            markedRows.removeAllIndexes()
        }
        
        if markedRows.containsIndexes(indexes) {
            return
        }
        
        markedRows.addIndexes(indexes)
//        self.setNeedsDisplay()
        notifyDelegate()
    }
    
    func unmark(row: Int) {
        markedRows.removeIndex(row)
//        self.setNeedsDisplay()
        notifyDelegate()
    }
    
    func unmarkAll() {
        markedRows.removeAllIndexes()
//        self.setNeedsDisplay()
        notifyDelegate()
    }
    
//    override func rightMouseDown(theEvent: NSEvent) {
//        super.rightMouseDown(theEvent)
        
//        let row = self.rowAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
//        if isRowMarked(row) {
//            unmark(row)
//        } else {
//            markRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
//        }
//    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        let row = self.rowAtPoint(self.convertPoint(theEvent.locationInWindow, fromView: nil))
        if isRowMarked(row) {
            markRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        } else {
            unmarkAll()
        }
    }
    
    func cleanData() {
        unmarkAll()
        notifyDelegate()
    }
    
    override func menuForEvent(event: NSEvent) -> NSMenu? {
        let row = self.rowAtPoint(self.convertPoint(event.locationInWindow, fromView: nil))
        
        if (row != -1) {
            self.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
            self.markRowIndexes(NSIndexSet(index: row), byExtendingSelection: isRowMarked(row))
        }
        
        return super.menu
    }
    
}
