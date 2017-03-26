//
//  SCTableRowView.swift
//  vCommander
//
//  Created by Jamie on 15/7/5.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCTableRowView: NSTableRowView {
    
    var marked = false
    
    
    override func drawSelection(in dirtyRect: NSRect) {
        
        if (self.selectionHighlightStyle != NSTableViewSelectionHighlightStyle.none) {
            //            var selectionRect = NSInsetRect(self.bounds, 2.5, 2.5)
            
            //            NSColor(calibratedWhite: 0.0, alpha: 1.0).setStroke()
            if self.isEmphasized {
                NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1.0).setStroke()
            } else {
                NSColor(calibratedWhite: 0.82, alpha: 1.0).setStroke()
            }
            
            let selectionPath = NSBezierPath(rect: dirtyRect)
//            let selectionPath = NSBezierPath.init(roundedRect: dirtyRect, xRadius: 6, yRadius: 6)
            selectionPath.lineWidth = 3.0
            
            //        var lineDash: [CGFloat] = [2.0, 2.0]
            //        selectionPath.setLineDash(lineDash, count: 2, phase: 0.0)
            
//            selectionPath.fill()
            selectionPath.stroke()
            
            //        }

        }
    }
    
    
    override var interiorBackgroundStyle: NSBackgroundStyle {
        return NSBackgroundStyle.light
    }
    
//    override func drawBackgroundInRect(dirtyRect: NSRect) {
//        
//        let context = NSGraphicsContext.currentContext()!.CGContext
//        
////        super.drawBackgroundInRect(dirtyRect)
//        
//        self.print("drawBackgroundInRect called.")
//    
//        if !self.marked {
//            self.print("drawBackgroundInRect called. marked")
////            CGContextSetFillColorWithColor(context, NSColor.redColor().CGColor);
//            super.drawBackgroundInRect(dirtyRect)
//            return
//        } else {
//            self.print("drawBackgroundInRect called. not marked")
//            CGContextSetFillColorWithColor(context, NSColor.alternateSelectedControlColor().CGColor)
//            CGContextSetStrokeColorWithColor(context, NSColor.whiteColor().CGColor)
//            CGContextFillRect(context, dirtyRect);
//        }
//    }
    
}
