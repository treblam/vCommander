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
    
    var subWindowController: MainWindowController?
    
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
    
    var activeTab: TabItemController {
        return activePanel.tabView.selectedTabViewItem?.viewController as! TabItemController
    }
    
    var inactivePanel: CommanderPanel {
        return isPrimaryActive ? rightPanel : leftPanel
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
//        self.window.allowsAutomaticWindowTabbing
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
        
        print("isPrimaryActive: \(isPrimaryActive)")
        
        print(activeTab.title ?? "no title")
        if (activeTab.tableview == nil) {
            print("tableview is nil")
        }
        self.window?.makeFirstResponder(activeTab.tableview)
        
//        self.window?.backgroundColor = NSColor(calibratedWhite: 236.0/255.0, alpha: 1)
        
        self.window?.titleVisibility = .hidden
//        self.window?.titlebarAppearsTransparent = true
        self.window?.styleMask.insert(.fullSizeContentView)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        interpretKeyEvents([theEvent])
    }
    
//    @IBAction override func newWindowForTab(_ sender: Any?) {
//        let windowController = MainWindowController()
//        if #available(OSX 10.12, *) {
//            self.window?.addTabbedWindow(windowController.window!, ordered: .above)
//            self.subWindowController = windowController
//            windowController.window?.orderFront(self.window)
//            windowController.window?.makeKey()
//        } else {
//            // Fallback on earlier versions
//        }
//    }
    
    override func insertTab(_ sender: Any?) {
        print("inserttab in mainwindowcontroller")
    }
    
    func switchFocus() {
        print("start to switch focus")
        let tableview = (inactivePanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview
        self.window?.makeFirstResponder(tableview)
        isPrimaryActive = !isPrimaryActive
        invalidateRestorableState()
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
    
//    override var acceptsFirstResponder: Bool {
//        return true
//    }
    
    override func mouseDown(with event: NSEvent) {
        print("mouseDown in mainWindowController called.")
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState in MainWindowController called.")
        super.encodeRestorableState(with: coder)
        coder.encode(isPrimaryActive, forKey: "isPrimaryActive")
    }
    
    override func restoreState(with coder: NSCoder) {
        print("restoreState in MainWindowController called.")
        super.restoreState(with: coder)
        isPrimaryActive = coder.decodeBool(forKey: "isPrimaryActive")
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
