//
//  SCPreferenceController.swift
//  vCommander
//
//  Created by Jamie on 15/11/9.
//  Copyright © 2015年 Jamie. All rights reserved.
//

import Cocoa

class SCPreferenceController: NSWindowController {
    
    @IBOutlet weak var textEditorField: NSTextField!
    @IBOutlet weak var chooseEditorBtn: NSButton!
    
    @IBOutlet weak var diffToolField: NSTextField!
    @IBOutlet weak var chooseDiffBtn: NSButton!
    
    @IBOutlet weak var commonModeRadio: NSButton!
    @IBOutlet weak var vimModeRadio: NSButton!
    
    @IBOutlet weak var toolbar: NSToolbar!
    
    @IBOutlet weak var tabView: NSTabView!
    
    let preferenceManager = PreferenceManager()
    
    override var windowNibName: String {
        return "SCPreferenceController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        textEditorField.stringValue = preferenceManager.textEditor!
        
        diffToolField.stringValue = preferenceManager.diffTool!
        
        if preferenceManager.mode == 1 {
            vimModeRadio.state = 1
        } else {
            commonModeRadio.state = 1
        }
        
        toolbar.selectedItemIdentifier = "general"
    }
    
    @IBAction func chooseEditor(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
//        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        
        if clicked == NSFileHandlingPanelOKButton {
            if panel.urls.count == 1 {
                let editor = panel.urls[0].path
                textEditorField.stringValue = editor
                preferenceManager.textEditor = editor
            }
        }
    }
    
    @IBAction func chooseDiffTool(_ sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
//        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        
        if clicked == NSFileHandlingPanelOKButton {
            if panel.urls.count == 1 {
                let diffTool = panel.urls[0].path
                diffToolField.stringValue = diffTool
                preferenceManager.diffTool = diffTool
            }
        }
    }
    
    @IBAction func chooseMode(_ sender: AnyObject) {
        preferenceManager.mode = (sender as! NSButton).tag as NSNumber
    }
    
    @IBAction func setSelectedTab(_ sender: Any) {
        let toolbarItem = sender as! NSToolbarItem
        tabView.selectTabViewItem(at: toolbarItem.tag)
    }
}
