//
//  SCPreferenceController.swift
//  SimpleCommander
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
    
    
    let preferenceManager = PreferenceManager()
    
    override var windowNibName: String {
        return "SCPreferenceController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        print("abc")
        
        textEditorField.stringValue = preferenceManager.textEditor!
        
        diffToolField.stringValue = preferenceManager.diffTool!

        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    @IBAction func chooseEditor(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        
        if clicked == NSFileHandlingPanelOKButton {
            if panel.URLs.count == 1 {
                let editor = panel.URLs[0].path!
                textEditorField.stringValue = editor
                preferenceManager.textEditor = editor
            }
        }
    }
    
    @IBAction func chooseDiffTool(sender: AnyObject) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        
        let clicked = panel.runModal()
        
        if clicked == NSFileHandlingPanelOKButton {
            if panel.URLs.count == 1 {
                let diffTool = panel.URLs[0].path!
                diffToolField.stringValue = diffTool
                preferenceManager.diffTool = diffTool
            }
        }
    }
    
}
