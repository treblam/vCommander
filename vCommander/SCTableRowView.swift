//
//  SCTableRowView.swift
//  vCommander
//
//  Created by Jamie on 15/7/5.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTableRowView: NSTableRowView {
    
    override func drawSelection(in dirtyRect: NSRect) {
        if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyle.none) {
            if self.isEmphasized {
                NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1.0).setStroke()
            } else {
                NSColor(calibratedWhite: 0.82, alpha: 1.0).setStroke()
            }
            
            let selectionPath = NSBezierPath(rect: dirtyRect)
            selectionPath.lineWidth = 3.0
            selectionPath.stroke()
        }
    }

//    override func drawSelection(in dirtyRect: NSRect) {
//        if self.selectionHighlightStyle != .none {
//            let selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
//            NSColor(calibratedWhite: 0.65, alpha: 1).setStroke()
//            NSColor(calibratedWhite: 0.82, alpha: 1).setFill()
//            let selectionPath = NSBezierPath.init(roundedRect: selectionRect, xRadius: 6, yRadius: 6)
//            selectionPath.fill()
//            selectionPath.stroke()
//        }
//    }
    
//    override var wantsLayer: Bool {
//        set {
//            self.wantsLayer = newValue
//        }
//        get {
//            return false
//        }
//    }
    
    override var interiorBackgroundStyle: NSBackgroundStyle {
        return NSBackgroundStyle.light
    }
    
//    override var isSelected: Bool {
//        willSet(newValue) {
//            super.isSelected = newValue;
//            needsDisplay = true
//        }
//    }
    
//    override func drawBackground(in dirtyRect: NSRect) {
//    
//        let context = NSGraphicsContext.current()!.cgContext
//    
////        super.drawBackground(in: dirtyRect)
//    
//        Swift.print("drawBackgroundInRect called.")
//    
//        if !self.isSelected {
//            self.print("drawBackgroundInRect called. marked")
//            context.setFillColor(NSColor.red.cgColor);
//            super.drawBackground(in: dirtyRect)
//        } else {
//            self.print("drawBackgroundInRect called. not marked")
//            context.setFillColor(NSColor.alternateSelectedControlColor.cgColor)
//            context.setStrokeColor(NSColor.white.cgColor)
//            context.fill(dirtyRect)
//        }
//    }

}
