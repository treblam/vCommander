//
//  TabItemController.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class TabItemController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var tableview: NSTableView!
    
    var curFsItem: FileSystemItem!
    
    let fileManager = NSFileManager()
    
    let dateFormatter = NSDateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let clSelector:Selector = "dblClk:"
        tableview.doubleAction = clSelector
        tableview.target = self

    }
    
    func dblClk(sender:AnyObject){
        println("ran")
        
        let tableview = sender as! NSTableView
        let row = tableview.clickedRow
        let selectedIndex = tableview.selectedRowIndexes
        var index = selectedIndex.firstIndex
        let item = curFsItem.children[index]
        
        println("index: " + index.description)
        
        println("item: " + item.description)
        println("fileURL: " + item.fileURL.path!)
        
        if (item.isDirectory) {
            changeDirectory(item.fileURL)
        } else {
            println("it's not direcotory, can't step into")
            NSWorkspace.sharedWorkspace().openFile(item.fileURL.path!)
        }
        
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if (curFsItem == nil) {
            return 0
        } else {
            return curFsItem.children.count
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var colIdentifier: String = tableColumn!.identifier
        
        var result: NSTableCellView = tableView.makeViewWithIdentifier(colIdentifier, owner: self) as! NSTableCellView
        
        let item = self.curFsItem.children[row]
        
        switch colIdentifier {
        case "localizedName":
            println("localizedName")
            result.textField!.stringValue = item.localizedName
            result.imageView!.image = item.icon
            println(result.textField!.stringValue)
            
        case "dateOfLastModification":
            println(result.identifier!)
            result.textField!.stringValue = dateFormatter.stringFromDate(item.dateOfLastModification)
            println(result.textField!.stringValue)
            
        case "size":
            println("result.identifier: " + result.identifier!)
            result.textField!.stringValue = item.size
            println("item.size", item.size)
            println("result.textField!.stringValue: " + result.textField!.stringValue)
            
        case "localizedType":
            if item.localizedType != nil {
                result.textField!.stringValue = item.localizedType
            }
            
        default:
            result.textField!.stringValue = ""
            
        }
        
        return result
    }
    
    func onDirChange(url: NSURL) {
        var suc = fileManager.changeCurrentDirectoryPath(url.path!)
        
        if (!suc) {
            println("change directory fail")
        }
        
        println(fileManager.currentDirectoryPath)
        curFsItem = FileSystemItem(fileURL: NSURL.fileURLWithPath(fileManager.currentDirectoryPath)!)
        title = curFsItem.localizedName
        
        println("change directory success")
    }
    
    func changeDirectory(url: NSURL) {
        onDirChange(url)
        tableview.reloadData()
        
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    override func keyDown(theEvent: NSEvent) {
        println(theEvent.keyCode)
        
        if theEvent.keyCode == 51 {
            let parentUrl = curFsItem.fileURL.URLByDeletingLastPathComponent
            if let url = parentUrl {
                changeDirectory(url)
                return
            }
        } else if theEvent.keyCode == 36 {
            dblClk(tableview)
            return
        }
        
        interpretKeyEvents([theEvent])
        super.keyDown(theEvent)
    }
    
    override func insertTab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController() as! MainWindowController
        windowController.switchFocus()
    }
    
    override func insertBacktab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController() as! MainWindowController
        windowController.switchFocus()
    }
    
    convenience override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: nil)
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, url: NSURL?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        let dirUrl = url ?? NSURL.fileURLWithPath("/Users/jamie", isDirectory: true)
        
        onDirChange(dirUrl!)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
