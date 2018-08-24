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
    @IBOutlet weak var pathLabel: NSTextField!
    
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
        
        
        self.view.window?.makeFirstResponder(nameField)
        
        if isSubmenu {
            pathLabel.isHidden = true
            pathField.isEnabled = false
            pathField.isHidden = true
        } else {
            pathLabel.isHidden = false
            pathField.isEnabled = true
            pathField.isHidden = false
        }
        
        if isAdd {
            nameField.stringValue = ""
            hotkeyField.stringValue = ""
            pathField.stringValue = ""
        } else {
            nameField.stringValue = hotlistItem?.name ?? ""
            hotkeyField.stringValue = hotlistItem?.hotkey ?? ""
            pathField.stringValue = hotlistItem?.path ?? ""
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
        
        if !isSubmenu && path.count == 0 {
            let errorAlert = NSAlert()
            errorAlert.messageText = "Path should not be empty"
            errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            return
        }
        
        if !isSubmenu {
            let escapedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
            if fileManager.fileExists(atPath: path) && escapedPath != nil {
                url = URL(fileURLWithPath: escapedPath!)
                updateItem(name, hotkey, url!)
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Folder doesn't exist"
                errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            }
        } else {
            updateItem(name, hotkey, nil)
        }
    }
    
    func updateItem(_ name: String, _ hotkey: String, _ url: URL?) {
        if isAdd {
            hotlistItem = HotlistItem(name: name, hotkey: hotkey, isSubmenu: isSubmenu, url: url)
        } else {
            hotlistItem?.name = name
            hotlistItem?.hotkey = hotkey
            hotlistItem?.url = url
        }
        
        self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSApplication.ModalResponse.alertFirstButtonReturn)
    }
    
}
