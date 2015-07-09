//
//  TabItemController.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class TabItemController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, DirectoryMonitorDelegate {

    @IBOutlet weak var tableview: SCTableView!
    
    var curFsItem: FileSystemItem!
    
    let fileManager = NSFileManager()
    
    let dateFormatter = NSDateFormatter()
    
    let workspace = NSWorkspace.sharedWorkspace()
    
    var dm: DirectoryMonitor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let clSelector:Selector = "dblClk:"
        tableview.doubleAction = clSelector
        tableview.target = self
        
        tableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.None
    }
    
    func getSelectedItem() -> FileSystemItem {
        let selectedIndex = tableview.selectedRowIndexes
        var index = selectedIndex.firstIndex
        return curFsItem.children[index]
    }
    
    func dblClk(sender:AnyObject){
        println("ran")
        
        let tableview = sender as! NSTableView
        let row = tableview.clickedRow
        let item = getSelectedItem()
        
        println("fileURL: " + item.fileURL.path!)
        
        if (item.isDirectory) {
            changeDirectory(item.fileURL)
        } else {
            println("it's not direcotory, can't step into")
            workspace.openFile(item.fileURL.path!)
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
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let cellId = "cell_identifier"
        
        var result = tableView.makeViewWithIdentifier(cellId, owner: self) as? SCTableRowView
        
        if result == nil {
            result = SCTableRowView(frame: NSMakeRect(0, 0, tableview.frame.size.width, 80))
            result?.identifier = cellId
        } else {
            // Restore to default values
            result?.marked = false
        }
        
        return result
    }
    
    func tableViewMarkedViewsDidChange() {
        tableview.enumerateAvailableRowViewsUsingBlock { rowView, _ in
            
            for (var column = 0; column < rowView.numberOfColumns; column++) {
                var cellView: AnyObject? = rowView.viewAtColumn(column)
                
                if let tableCellView = cellView as? NSTableCellView {
                    var textField = tableCellView.textField
                    if let scRowView = rowView as? SCTableRowView {
                        if let text = textField {
                            if scRowView.marked {
                                text.textColor = NSColor.whiteColor()
                            } else {
                                if let str = tableCellView.identifier {
                                    switch str {
                                    case "localizedName":
                                        text.textColor = NSColor.controlTextColor()
                                    default:
                                        text.textColor = NSColor.disabledControlTextColor()
                                    }
                                }
                                
                            }
                        }
                    }
                }
                
            }
            
            
        }
    }
    
    
    // TODO: This is to be removed if apple fixed its bug
    func tableViewSelectionDidChange(notification: NSNotification) {
        tableview.setNeedsDisplay()
    }
    
    func onDirChange(url: NSURL) {
        var suc = fileManager.changeCurrentDirectoryPath(url.path!)
        
        if (!suc) {
            println("change directory fail")
        }
        
        println(fileManager.currentDirectoryPath)
        curFsItem = FileSystemItem(fileURL: NSURL.fileURLWithPath(fileManager.currentDirectoryPath)!)
        title = curFsItem.localizedName
        
        // Clean the data for last directory
        if (tableview !== nil) {
            println("clean data")
            tableview.cleanData()
        }
        
        println("Change directory success")
        
        if self.view !== nil && self.view.superview !== nil {
            var tabItem = (self.view.superview as! NSTabView).selectedTabViewItem
            var model = tabItem?.identifier as! TabBarModel
            
            model.title = title ?? "Untitled"
            tabItem?.identifier = model
        }
        
        dm = DirectoryMonitor(URL: curFsItem.fileURL)
        dm.delegate = self
        dm.startMonitoring()
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
        } else if theEvent.keyCode == 96 {  // F5
            copySelectedFiles()
            return
        } else if theEvent.keyCode == 97 {  // F6
            moveSelectedFiles()
        } else if theEvent.keyCode == 98 {  // F7
            // create new directory
        } else if theEvent.keyCode == 100 { // F8
            deleteSelectedFiles()
            return
        }
        
        interpretKeyEvents([theEvent])
        super.keyDown(theEvent)
    }
    
    func copySelectedFiles() {
        let item = getSelectedItem()
        let windowController = self.view.window!.windowController() as! MainWindowController
        let targetViewController = windowController.getTargetTabItem()
        let destination = targetViewController.curFsItem.path
        let files = [item.name]
        var tag: NSNumber = 0
        let result = workspace.performFileOperation(NSWorkspaceCopyOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
        
        if result {
            println("copy succeeded")
        }
    }
    
    func moveSelectedFiles() {
        let item = getSelectedItem()
        let windowController = self.view.window!.windowController() as! MainWindowController
        let targetViewController = windowController.getTargetTabItem()
        let destination = targetViewController.curFsItem.path
        let files = [item.name]
        var tag: NSNumber = 0
        let result = workspace.performFileOperation(NSWorkspaceMoveOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
        
        if result {
            println("move succeeded")
        }
    }
    
    func deleteSelectedFiles() {
        let item = getSelectedItem()
        let windowController = self.view.window!.windowController() as! MainWindowController
        let targetViewController = windowController.getTargetTabItem()
        let destination = targetViewController.curFsItem.path
        let files = [item.name]
        var tag: NSNumber = 0
        let result = workspace.performFileOperation(NSWorkspaceRecycleOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
        
        if result {
            println("delete succeeded")
        }
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
    
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        println("directoryMonitorDidObserveChange")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.tableview.reloadData()
        })
    }
    
}
