//
//  SCTableView.swift
//  vCommander
//
//  Created by Jamie on 15/6/14.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTableView: NSTableView {
    
    var markedRows = NSMutableIndexSet()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func convertToInt(_ str: String) -> Int {
        let s1 = str.unicodeScalars
        let s2 = s1[s1.startIndex].value
        return Int(s2)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        Swift.print("SCTableView, keyDown called, keycode: " + theEvent.keyCode.description)
        
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
        
        let hasCommand = flags.contains(.command)
        
        let hasShift = flags.contains(.shift)
        
        let hasAlt = flags.contains(.option)
        
        let hasControl = flags.contains(.control)
        
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
                if markedRows.contains(row) {
                    self.markedRows.remove(row)
//                    rowView.marked = false
                    Swift.print("row: " + row.description + " was removed from markedRows")
                } else {
                    self.markedRows.add(row)
//                    rowView.marked = true
                    Swift.print("row: " + row.description + " was added to markedRows")
                }
                
                Swift.print("markedRows: " + markedRows.description)
                
                notifyDelegate()
                
//                self.selectRowIndexes(NSIndexSet(index: ++row), byExtendingSelection: false)
                self.setNeedsDisplay()
            }
            
        case NSTabFunctionKey:  // tab键
            self.nextResponder?.keyDown(with: theEvent)
            
// Temporarily comment vim mode, make normal mode easy to use first.
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
            super.keyDown(with: theEvent)
            
        }
    }
    
    func notifyDelegate() {
        (self.delegate as? SCTableViewDelegate)?.tableViewMarkedViewsDidChange()
    }
    
    func isRowMarked(_ row: Int) -> Bool {
        return markedRows.contains(row)
    }
    
    func markRowIndexes(_ indexes: IndexSet, byExtendingSelection extend: Bool) {
        if !extend {
            markedRows.removeAllIndexes()
        }
        
        if markedRows.contains(indexes) {
            return
        }
        
        markedRows.add(indexes)
        notifyDelegate()
    }
    
    func unmark(_ row: Int) {
        markedRows.remove(row)
        notifyDelegate()
    }
    
    func unmarkAll() {
        markedRows.removeAllIndexes()
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
    
    override func mouseDown(with theEvent: NSEvent) {
        super.mouseDown(with: theEvent)
        
        let clickedRow = self.row(at: self.convert(theEvent.locationInWindow, from: nil))
        if isRowMarked(clickedRow) {
            markRowIndexes(IndexSet(integer: clickedRow), byExtendingSelection: false)
        } else {
            unmarkAll()
        }
    }
    
    func cleanData() {
        markedRows.removeAllIndexes()
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let row = self.row(at: self.convert(event.locationInWindow, from: nil))
        
        if (row != -1) {
            self.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            self.markRowIndexes(IndexSet(integer: row), byExtendingSelection: isRowMarked(row))
        }
        
        return super.menu
    }
    
    // Do not show animation when drag items
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.animatesToDestination = false
        return true
    }
    
}

protocol SCTableViewDelegate: NSTableViewDelegate {
    func tableViewMarkedViewsDidChange()
}


