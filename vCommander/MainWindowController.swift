//
//  MainWindowController.swift
//  vCommander
//
//  Created by Jamie on 15/5/12.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate, MMTabBarViewDelegate {
    
    @IBOutlet weak var splitView: NSSplitView!
    
    let preferenceManager = PreferenceManager()
    
    let preferenceController = SCPreferenceController()
    
    override var windowNibName: String {
        return "MainWindowController"
    }
    
    let leftPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil, panelName: "leftPanel")!
    
    let rightPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil, panelName: "rightPanel")!
    
    var leftTab: TabItemController! {
        return (leftPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
    }
    
    var rightTab: TabItemController! {
        return (rightPanel.tabView.selectedTabViewItem?.viewController as! TabItemController)
    }
    
    var isPrimaryActive = true
    
    var activePanel: CommanderPanel {
        return isPrimaryActive ? leftPanel : rightPanel
    }
    
    var inactivePanel: CommanderPanel {
        return isPrimaryActive ? rightPanel : leftPanel
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        leftPanel.view.translatesAutoresizingMaskIntoConstraints = false
        rightPanel.view.translatesAutoresizingMaskIntoConstraints = false
        
        // var contentView: NSView = self.window!.contentView as! NSView
        
        let leftView = splitView.subviews[0]
        let rightView = splitView.subviews[1]
        leftView.addSubview(leftPanel.view)
        rightView.addSubview(rightPanel.view)
        
        let views = ["leftPanel": leftPanel.view, "rightPanel": rightPanel.view]
        
        leftView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[leftPanel(>=400)]-0-|", options: [NSLayoutFormatOptions.alignAllTop, NSLayoutFormatOptions.alignAllBottom], metrics: nil, views: views))
        
        leftView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[leftPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[rightPanel(>=400)]-0-|", options: [NSLayoutFormatOptions.alignAllTop, NSLayoutFormatOptions.alignAllBottom], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[rightPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        
        self.window?.makeFirstResponder((activePanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview)
        
        self.window?.backgroundColor = NSColor(calibratedWhite: 236.0/255.0, alpha: 1)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
    override func insertTab(_ sender: Any?) {
        print("inserttab in mainwindowcontroller")
    }
    
    func switchFocus() {
        print("start to switch focus")
        let tableview = (inactivePanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview
        self.window?.makeFirstResponder(tableview)
        isPrimaryActive = !isPrimaryActive
    }
    
    func getTargetTabItem() -> TabItemController {
        return inactivePanel.tabView.selectedTabViewItem?.viewController as! TabItemController
    }
    
    func openFile(for fileName: String) -> Bool {
        return activePanel.openFile(for: fileName)
    }
    
    @IBAction func openPreferencePanel(_ sender: AnyObject?) {
        print("openPreferencePanel called.")
        preferenceController.window?.makeKeyAndOrderFront(self)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState in MainWindowController called.")
    }
    
    override func restoreState(with coder: NSCoder) {
        print("restoreState in MainWindowController called.")
    }
    
    func window(_ window: NSWindow, willEncodeRestorableState state: NSCoder) {
        print("willEncodeRestorableState in MainWindowController called")
//        leftPanel.encodeRestorableState(with: state)
//        rightPanel.encodeRestorableState(with: state)
    }
    
    func window(_ window: NSWindow, didDecodeRestorableState state: NSCoder) {
//        leftPanel =
    }
    
}
