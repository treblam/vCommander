//
//  HotlistConfigController.swift
//  vCommander
//
//  Created by Jerry's Macbook on 2018/8/20.
//  Copyright © 2018年 Jamie. All rights reserved.
//

import Cocoa

class HotlistConfigController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource, NSTextFieldDelegate {

    @IBOutlet weak var confirmButton: NSButton!
    
    @IBOutlet weak var cancelButton: NSButton!
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    var rootItem = HotlistItem(name: "root", hotkey: nil, isSubmenu: true)
    
    let fileManager = FileManager.default
    
    let addSubmenuController = HotlistAddSubmenuController(nibName: NSNib.Name(rawValue: "HotlistAddSubmenuController"), bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        print("viewDidLoad, start to add items")
        rootItem.children.append(HotlistItem(name: "Desktop", hotkey: "d", isSubmenu: false, url: fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first))
        let folder = HotlistItem(name: "Folder", hotkey: "f", isSubmenu: true)
        folder.children.append(HotlistItem(name: "Documents", hotkey: "d", isSubmenu: false, url: fileManager.urls(for: .documentDirectory, in: .userDomainMask).first))
        rootItem.children.append(folder)
        
        outlineView.reloadData()
    }
    
    @IBAction func cancel(_ sender: Any?) {
        self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSApplication.ModalResponse.cancel)
    }
    
    @IBAction func confirm(_ sender: Any?) {
        self.view.window?.sheetParent?.endSheet(self.view.window!, returnCode: NSApplication.ModalResponse.alertFirstButtonReturn)
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        print("outlineView numberOfChildrenOfItem called.")
        if let hotlistItem = item as? HotlistItem {
            print("return item count: \(hotlistItem.children.count)")
            return hotlistItem.children.count
        }
        print("return rootItem count: \(rootItem.children.count)")
        return rootItem.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let hotlistItem = item as? HotlistItem {
            print("return child of item: \(hotlistItem.children[index].name)")
            return hotlistItem.children[index]
        }
        
        print("return child of rootItem: \(rootItem.children[index].name)")
        return rootItem.children[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        let hotlistItem = item as! HotlistItem
        return hotlistItem.isSubmenu
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let hotlistItem = item as! HotlistItem
        var view: NSTableCellView?
        
        print("enter outlineView viewFor")
        if (tableColumn?.identifier)!.rawValue == "nameColumn" {
            print("makeView for name cell")
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "nameCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = hotlistItem.name
//                textField.sizeToFit()
            }
        } else if (tableColumn?.identifier)!.rawValue == "hotkeyColumn" {
            print("makeView for hotkey cell")
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "hotkeyCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = hotlistItem.hotkey ?? ""
//                textField.sizeToFit()
            }
        } else if (tableColumn?.identifier)!.rawValue == "pathColumn" {
            print("makeView for path cell")
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "pathCell"), owner: self) as? NSTableCellView
            if let textField = view?.textField {
                if hotlistItem.isSubmenu {
                    textField.isEditable = false
                } else {
                    textField.stringValue = hotlistItem.path ?? ""
                }
//                textField.sizeToFit()
            }
        }
        
        return view
    }
    
    func getSelectedItem() -> HotlistItem? {
        return outlineView.item(atRow: outlineView.selectedRow) as? HotlistItem
    }
    
    func getSelectedIndex(forItem item: HotlistItem) -> Int? {
        return outlineView.row(forItem: item)
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let textField = obj.object as? NSTextField
        let newName = textField?.stringValue
        let selected = getSelectedItem()
        let currentName = selected?.name
        
//        textField?.isEditable = false
        
        if newName == nil || newName == "" {
            print("New name is empty, restore to old name.")
            textField?.stringValue = currentName!
            return
        }
        
        if newName == currentName {
            print("New name is the same as the old name, do nothing.")
            return
        }
        
        print("currentName: \(String(describing: currentName))")
        print("newName: \(String(describing: newName))")
        
        guard let newValue = newName else {
            return
        }
        
        guard let currentItem = selected else {
            return
        }
        
        if textField?.tag == 0 {
            currentItem.name = newValue
        } else if textField?.tag == 1 {
            if newValue.count == 1 {
                currentItem.hotkey = newValue
            } else {
                let errorAlert = NSAlert()
                errorAlert.messageText = "Hotkey is not valid"
                errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
            }
        } else if textField?.tag == 2 {
            if !currentItem.isSubmenu {
                let escapedPath = newValue.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
                if fileManager.fileExists(atPath: newValue) && escapedPath != nil {
                    currentItem.url = URL(fileURLWithPath: escapedPath!)
                } else {
                    if let path = currentItem.url?.path {
                        textField?.stringValue = path
                    }
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Folder doesn't exist"
                    errorAlert.beginSheetModal(for: self.view.window!, completionHandler: nil)
                }
            }
        }
    }
    
    // Make the NSTextField not editable when escape key is pressed
//    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//        print("control textView doCommandBy")
//        if commandSelector == #selector(cancelOperation(_:)) {
//            if let textField = control as? NSTextField {
//                textField.isEditable = false
//            }
//        }
//        return false
//    }
    
    func addItem(_ item: HotlistItem, toSubmenu submenu: HotlistItem, withIndex index: Int) {
        let parent = submenu == rootItem ? nil : submenu
        if index >= submenu.children.count - 1 {
            submenu.children.append(item)
            outlineView.insertItems(at: IndexSet(integer: submenu.children.count - 1), inParent: parent, withAnimation: NSTableView.AnimationOptions.effectFade)
        } else {
            submenu.children.insert(item, at: index + 1)
            outlineView.insertItems(at: IndexSet(integer: index + 1), inParent: parent, withAnimation: NSTableView.AnimationOptions.effectFade)
        }
        
        if parent != nil {
            if !outlineView.isItemExpanded(parent!) {
                outlineView.expandItem(parent!)
            }
        }
    }
    
    @IBAction func addDirectory(_ sender: AnyObject?) {
        addHotlistItem(isSubmenu: false)
    }
    
    @IBAction func addSubmenu(_ sender: AnyObject?) {
        addHotlistItem(isSubmenu: true)
    }
    
    func addHotlistItem(isSubmenu: Bool) {
        var parentItem: HotlistItem?
        var insertIndex: Int?
        
        if let selected = getSelectedItem() {
            if selected.isSubmenu {
                parentItem = selected
                insertIndex = parentItem?.children.count
//                print("I am submenu, to be insert to: \(insertIndex)")
            } else {
                if let parent = outlineView.parent(forItem: selected) as? HotlistItem {
                    parentItem = parent
                    insertIndex = parentItem?.children.index(of: selected)
//                    print("got parent, and my index is: \(insertIndex)")
                } else {
                    insertIndex = rootItem.children.index(of: selected)
//                    print("no parent, my index is: \(insertIndex)")
                }
            }
        } else {
//            print("no selected, add to rootItem")
            insertIndex = rootItem.children.count
        }
        
        addSubmenuController.isSubmenu = isSubmenu
        
        if insertIndex != nil {
            self.view.window?.beginSheet(addSubmenuController.view.window!, completionHandler: { (returnCode) in
                if returnCode == NSApplication.ModalResponse.alertFirstButtonReturn {
                    if let editedItem = self.addSubmenuController.hotlistItem {
                        if parentItem == nil {
                            self.addItem(editedItem, toSubmenu: self.rootItem, withIndex: insertIndex!)
                        } else {
                            self.addItem(editedItem, toSubmenu: parentItem!, withIndex: insertIndex!)
                        }
                    }
                    
                }
            })
        }
    }
    
    @IBAction func deleteItem(_ sender: AnyObject?) {
        var parentItem: HotlistItem?
        if let selected = getSelectedItem() {
            if let parent = outlineView.parent(forItem: selected) as? HotlistItem {
                parentItem = parent
            }
            
            if parentItem == nil {
                if let removeIndex = rootItem.children.index(of: selected) {
                    rootItem.children.remove(at: removeIndex)
                    outlineView.removeItems(at: NSIndexSet(index: removeIndex) as IndexSet, inParent: parentItem, withAnimation: NSTableView.AnimationOptions.effectFade)
                }
            } else {
                if let removeIndex = parentItem?.children.index(of: selected) {
                    parentItem?.children.remove(at: removeIndex)
                    outlineView.removeItems(at: NSIndexSet(index: removeIndex) as IndexSet, inParent: parentItem, withAnimation: NSTableView.AnimationOptions.effectFade)
                }
            }
        }
        
    }
    
    
}
