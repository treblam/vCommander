//
//  MainWindowController.swift
//  SimpleCommander
//
//  Created by Jamie on 15/5/12.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, MMTabBarViewDelegate {
    
    @IBOutlet weak var splitView: NSSplitView!
    
    let preferenceManager = PreferenceManager()
    
    let preferenceController = SCPreferenceController()
    
    override var windowNibName: String {
        return "MainWindowController"
    }
    
    let leftPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil)!
    
    let rightPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil)!
    
    var leftTab: TabItemController! {
        return (leftPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
    }
    
    var rightTab: TabItemController! {
        return (rightPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        leftPanel.view.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.view.translatesAutoresizingMaskIntoConstraints = false
        
        // var contentView: NSView = self.window!.contentView as! NSView
        
        let leftView = splitView.subviews[0] 
        let rightView = splitView.subviews[1] 
        self.window?.makeFirstResponder(leftPanel.tabView.selectedTabViewItem?.viewController?.view)
        
        leftView.addSubview(leftPanel.view)
        rightView.addSubview(rightPanel.view)
        
        let views = ["leftPanel": leftPanel.view, "rightPanel": rightPanel.view]
        
        leftView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[leftPanel(>=400)]-0-|", options: [NSLayoutFormatOptions.AlignAllTop, NSLayoutFormatOptions.AlignAllBottom], metrics: nil, views: views))
        
        leftView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[leftPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[rightPanel(>=400)]-0-|", options: [NSLayoutFormatOptions.AlignAllTop, NSLayoutFormatOptions.AlignAllBottom], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[rightPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        self.window?.backgroundColor = NSColor(calibratedWhite: 236.0/255.0, alpha: 1)
        
    }
    
    override func keyDown(theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func insertTab(sender: AnyObject?) {
        print("inserttab in mainwindowcontroller")
    }
    
    func switchFocus() {
        print("start to switch focus")
        
        print("firstResponder: " + self.window!.firstResponder.description)
        
        let leftTableView = (leftPanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview
        let rightTableView = (rightPanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview
        
        print("leftPanel.tabView.selectedTabViewItem?.viewController!.view: " + leftTableView!.description)
        
        if self.window?.firstResponder === leftTableView {
            self.window?.makeFirstResponder(rightTableView)
        } else if self.window?.firstResponder === rightTableView {
            self.window?.makeFirstResponder(leftTableView)
        }
    }
    
    func getTargetTabItem() -> TabItemController {
        let leftViewController = (leftPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
        let rightViewController = (rightPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
        
        var result: TabItemController!
        
        if self.window?.firstResponder === leftViewController.tableview {
            result = rightViewController
        } else if self.window?.firstResponder === rightViewController.tableview {
            result = leftViewController
        }
        
        return result
    }
    
    @IBAction func openPreferencePanel(sender: AnyObject?) {
        print("openPreferencePanel called.")
        preferenceController.window?.makeKeyAndOrderFront(self)
    }
    
}
