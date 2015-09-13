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
    
    var lastChildDir: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        let clSelector:Selector = "dblClk:"
        tableview.doubleAction = clSelector
        tableview.target = self
        
        //tableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.None
    }
    
    func getSelectedItem() -> FileSystemItem? {
        let selectedIndex = tableview.selectedRowIndexes
        if selectedIndex.count == 0 {
            return nil
        }
        
        var index = selectedIndex.firstIndex
        
        return curFsItem.children[index]
    }
    
    func getMarkedItems() -> [FileSystemItem] {
        var items: [FileSystemItem] = []
        
        if tableview.markedRows.count == 0 {
            var selectedItem = getSelectedItem()
            if let item = selectedItem {
                items.append(item)
            }
        } else {
            for index in tableview.markedRows {
                items.append(curFsItem.children[index])
            }
        }
        
        return items
    }
    
    func dblClk(sender:AnyObject){
        let tableview = sender as! NSTableView
        let row = tableview.clickedRow
        let item = getSelectedItem()
        
        if let fsItem = item {
            println("fileURL: " + fsItem.fileURL.path!)
            if (fsItem.isDirectory) {
                changeDirectory(fsItem.fileURL)
            } else {
                println("it's not directory, can't step into")
                workspace.openFile(fsItem.fileURL.path!)
            }
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
        
        if item.fileURL.isEqual(lastChildDir) {
            tableView.selectRowIndexes(NSIndexSet(index: row), byExtendingSelection: false)
        }
        
        switch colIdentifier {
            case "localizedName":
                result.textField!.stringValue = item.localizedName
                result.imageView!.image = item.icon
                
            case "dateOfLastModification":
                result.textField!.stringValue = dateFormatter.stringFromDate(item.dateOfLastModification)
                
            case "size":
                result.textField!.stringValue = item.localizedSize
                
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
        }
        
        return result
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 22.0
    }
    
    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [AnyObject]) {
        let sortDescriptors = tableview.sortDescriptors
        let objectsArray = curFsItem.children as NSArray
        let sortedObjects = objectsArray.sortedArrayUsingDescriptors(sortDescriptors)
        curFsItem.children = sortedObjects as! [FileSystemItem]
        tableview.reloadData()
    }
    
    func tableViewMarkedViewsDidChange() {
        tableview.enumerateAvailableRowViewsUsingBlock { rowView, rowIndex in
            
            for (var column = 0; column < rowView.numberOfColumns; column++) {
                var cellView: AnyObject? = rowView.viewAtColumn(column)
                
                if let tableCellView = cellView as? NSTableCellView {
                    var textField = tableCellView.textField
                    if let scRowView = rowView as? SCTableRowView {
                        if let text = textField {
                            var isMarked = self.tableview.isRowMarked(rowIndex)
                            if isMarked {
                                text.textColor = NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1)
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
        
        println("start monitor " + curFsItem.fileURL.path!)
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
        
        if theEvent.keyCode == 51 { // delete or backspace
            let parentUrl = curFsItem.fileURL.URLByDeletingLastPathComponent
            
            // Remember last directory, this dir should be selected when backed to parent dir
            lastChildDir = curFsItem.fileURL
            
            if let url = parentUrl {
                changeDirectory(url)
                return
            }
        } else if theEvent.keyCode == 36 {  // enter
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
        
        if let fsItem = item {
            let windowController = self.view.window!.windowController() as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.path
            let files = [fsItem.name]
            var tag: NSNumber = 0
            let result = workspace.performFileOperation(NSWorkspaceCopyOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
            
            if result {
                println("copy succeeded")
            }
        }
        
    }
    
    func moveSelectedFiles() {
        let item = getSelectedItem()
        if let fsItem = item {
            let windowController = self.view.window!.windowController() as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.path
            let files = [fsItem.name]
            var tag: NSNumber = 0
            let result = workspace.performFileOperation(NSWorkspaceMoveOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
            
            if result {
                println("move succeeded")
            }
        }
    }
    
    func deleteSelectedFiles() {
        let items = getMarkedItems()
        
        if items.count == 0 {
            return
        }
        
        let files = items.map { $0.name }
        
        let alert = NSAlert()
        alert.messageText = "删除"
        
        var informativeText = "确定删除选中的文件/文件夹吗？"
        var showCount = files.count
        var suffix = ""
        if files.count > 5 {
            showCount = 5
            suffix = "\n..."
        }
        
        for var i = 0; i < showCount; i++ {
            informativeText += ("\n" + files[i])
        }
        informativeText += suffix
        
        alert.informativeText = informativeText
        alert.addButtonWithTitle("确定")
        alert.addButtonWithTitle("取消")
        
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: { responseCode in
            switch responseCode {
            case NSAlertFirstButtonReturn:
                if self.workspace.performFileOperation(NSWorkspaceRecycleOperation, source: self.curFsItem.path, destination: "", files: files, tag: nil) {
                    println("delete succeeded")
                }
            default:
                break
            }
        })
    }
    
    // tab键按下
    override func insertTab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController() as! MainWindowController
        windowController.switchFocus()
    }
    
    // shift + tab键按下
    override func insertBacktab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController() as! MainWindowController
        windowController.switchFocus()
    }
    
    convenience override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: nil)
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, url: NSURL?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        var homeDir = NSHomeDirectory();
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        let dirUrl = url ?? NSURL.fileURLWithPath(homeDir, isDirectory: true)
        onDirChange(dirUrl!)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        println("directoryMonitorDidObserveChange")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.refreshData()
            self.tableview.reloadData()
        })
    }
    
    func refreshData() {
        curFsItem = FileSystemItem(fileURL: curFsItem.fileURL)
    }
    
    @IBAction func newDirectory(sender: NSMenuItem) {
        let alert = NSAlert()
        alert.addButtonWithTitle("确定")
        alert.addButtonWithTitle("取消")
        alert.messageText = "新建文件夹"
        alert.informativeText = "请输入文件夹名称"
        
        let textField = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
        textField.placeholderString = "文件夹名称"
        alert.accessoryView = textField
        
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: { responseCode in
            switch responseCode {
            case NSAlertFirstButtonReturn:
                let dirName = textField.stringValue
                let dirUrl = self.curFsItem.fileURL.URLByAppendingPathComponent(dirName)
                
                var theError: NSErrorPointer = nil
                if !self.fileManager.createDirectoryAtURL(dirUrl, withIntermediateDirectories: false, attributes: nil, error: theError) {
                    // handle the error
                }
            default:
                break
            }
        })
    }
    
    @IBAction func quicklook(sender: NSMenuItem) {
        
    }
    
}
