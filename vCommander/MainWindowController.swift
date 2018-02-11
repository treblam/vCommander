//
//  MainWindowController.swift
//  vCommander
//
//  Created by Jamie on 15/5/12.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate, MMTabBarViewDelegate, NSTouchBarDelegate {
    
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var toolbar: NSToolbar!
    
    let preferenceManager = PreferenceManager()
    
    let preferenceController = SCPreferenceController()
    
    var subWindowController: MainWindowController?
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name(rawValue: "MainWindowController")
    }
    
    let leftPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil, isPrimary: true)!
    
    let rightPanel = CommanderPanel(nibName: "CommanderPanel", bundle: nil, isPrimary: false)!
    
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
        
        leftView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[leftPanel(>=400)]-0-|", options: [NSLayoutConstraint.FormatOptions.alignAllTop, NSLayoutConstraint.FormatOptions.alignAllBottom], metrics: nil, views: views))
        
        leftView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[leftPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[rightPanel(>=400)]-0-|", options: [NSLayoutConstraint.FormatOptions.alignAllTop, NSLayoutConstraint.FormatOptions.alignAllBottom], metrics: nil, views: views))
        
        rightView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[rightPanel(>=400)]-3-|", options: [], metrics: nil, views: views))
        
        self.window?.titleVisibility = .hidden
        self.window?.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
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
    
    func switchFocus() {
        print("start to switch focus")
        let tableview = (inactivePanel.tabView.selectedTabViewItem?.viewController as! TabItemController).tableview
        self.window?.makeFirstResponder(tableview)
        isPrimaryActive = !isPrimaryActive
        invalidateRestorableState()
        
        notifyFocusChanged()
    }
    
    func notifyFocusChanged() {
        let notificationKey = "FocusChanged"
        print("Start to notify for key \(notificationKey)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: self)
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
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
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
    }
    
    func window(_ window: NSWindow, didDecodeRestorableState state: NSCoder) {
        print("didDecodeRestorableState in MainWindowController called")
    }
    
}
