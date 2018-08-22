//
//  HotlistAddSubmenuController.swift
//  vCommander
//
//  Created by Jerry's Macbook on 2018/8/22.
//  Copyright © 2018年 Jamie. All rights reserved.
//

import Cocoa

class HotlistAddSubmenuController: NSViewController {

    @IBOutlet weak var nameField: NSTextField!
    
    @IBOutlet weak var hotkeyField: NSTextField!
    
    @IBOutlet weak var pathField: NSTextField!
    
    let fileManager = FileManager.default
    
    var hotlistItem: HotlistItem?
    
    var isAdd = true
    var isSubmenu = true
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?, isAdd: Bool, isSubmenu: Bool) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.isAdd = isAdd
        self.isSubmenu = isSubmenu
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        print("viewDidLoad")
    }
    
    override func viewWillAppear() {
        nameField.stringValue = ""
        hotkeyField.stringValue = ""
        pathField.stringValue = ""
        
        self.view.window?.makeFirstResponder(nameField)
        
        if isSubmenu {
            pathField.isEnabled = false
        } else {
            pathField.isEnabled = true
        }
    }
    
    @IBAction func cancel(_ sender: Any?) {
        self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSApplication.ModalResponse.cancel)
    }
    
    @IBAction func confirm(_ sender: Any?) {
        let name = nameField.stringValue
        let hotkey = hotkeyField.stringValue
        let path = pathField.stringValue
        let url: URL?
        
        if name.count == 0 {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Name should not be empty"
            errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            return
        }
        
        if !isSubmenu {
            let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            if fileManager.fileExists(atPath: path) && escapedPath != nil {
                url = URL(fileURLWithPath: escapedPath!)
                hotlistItem = HotlistItem(name: name, hotkey: hotkey, isSubmenu: isSubmenu, url: url)
                self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSApplication.ModalResponse.alertFirstButtonReturn)
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Folder doesn't exist"
                errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            }
        }
    }
    
}
