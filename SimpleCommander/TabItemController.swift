//
//  TabItemController.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

import Quartz

class TabItemController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, DirectoryMonitorDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate {

    @IBOutlet weak var tableview: SCTableView!
    
    var curFsItem: FileSystemItem!
    
    let fileManager = NSFileManager()
    
    let dateFormatter = NSDateFormatter()
    
    let workspace = NSWorkspace.sharedWorkspace()
    
    var dm: DirectoryMonitor!
    
    var lastChildDir: NSURL?
    
    var isQLMode = false
    
    var isGpressed = false
    
    var textField: NSTextField?
    
    var isLeft: Bool {
        let windowController = self.view.window!.windowController as! MainWindowController
        return self === windowController.leftTab
    }
    
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
        
        let index = selectedIndex.firstIndex
        
        return curFsItem.children[index]
    }
    
    func getMarkedItems(isUseSelect: Bool=true) -> [FileSystemItem] {
        var items: [FileSystemItem] = []
        
        if isUseSelect && tableview.markedRows.count == 0 {
            let selectedItem = getSelectedItem()
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

        let item = getSelectedItem()
        
        if let fsItem = item {
            print("fileURL: " + fsItem.fileURL.path!)
            if (fsItem.isDirectory) {
                changeDirectory(fsItem.fileURL)
            } else {
                print("it's not directory, can't step into")
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
        
        let colIdentifier: String = tableColumn!.identifier
        
        let result: NSTableCellView = tableView.makeViewWithIdentifier(colIdentifier, owner: self) as! NSTableCellView
        
        let item = self.curFsItem.children[row]
        
        if item.fileURL.isEqual(lastChildDir) {
            // if this row is to be selected, scroll it to visible
            selectRow(row)
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
    
    func tableView(tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        let sortDescriptors = tableview.sortDescriptors
        let objectsArray = curFsItem.children as NSArray
        let sortedObjects = objectsArray.sortedArrayUsingDescriptors(sortDescriptors)
        curFsItem.children = sortedObjects as! [FileSystemItem]
        tableview.reloadData()
    }
    
    func tableViewMarkedViewsDidChange() {
        tableview.enumerateAvailableRowViewsUsingBlock { rowView, rowIndex in
            
            for (var column = 0; column < rowView.numberOfColumns; column++) {
                let cellView: AnyObject? = rowView.viewAtColumn(column)
                
                if let tableCellView = cellView as? NSTableCellView {
                    let textField = tableCellView.textField
                    if let _ = rowView as? SCTableRowView {
                        if let text = textField {
                            let isMarked = self.tableview.isRowMarked(rowIndex)
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
        
        if isQLMode {
            QLPreviewPanel.sharedPreviewPanel().reloadData()
        }
    }
    
    func onDirChange(url: NSURL) {
        let suc = fileManager.changeCurrentDirectoryPath(url.path!)
        
        if (!suc) {
            print("change directory fail")
        }
        
        print(fileManager.currentDirectoryPath)
        
        curFsItem = FileSystemItem(fileURL: NSURL.fileURLWithPath(fileManager.currentDirectoryPath))
        
        title = curFsItem.localizedName
        
        // Clean the data for last directory
        if (tableview !== nil) {
            print("clean data")
            tableview.cleanData()
        }
        
        print("Change directory success")
        
        if self.view !== nil && self.view.superview !== nil {
            let tabItem = (self.view.superview as! NSTabView).selectedTabViewItem
            let model = tabItem?.identifier as! TabBarModel
            
            model.title = title ?? "Untitled"
            tabItem?.identifier = model
        }
        
        dm = DirectoryMonitor(URL: curFsItem.fileURL)
        dm.delegate = self
        dm.startMonitoring()
        
        print("start monitor " + curFsItem.fileURL.path!)
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
    
    func convertToInt(str: String) -> Int {
        let s1 = str.unicodeScalars
        let s2 = s1[s1.startIndex].value
        return Int(s2)
    }
    
    override func keyDown(theEvent: NSEvent) {
        print("keyCode: " + String(theEvent.keyCode))
        
        let flags = theEvent.modifierFlags
        
        let s = theEvent.charactersIgnoringModifiers!
        
        let char = convertToInt(s)
        
        print("char:" + String(char))
        
        let hasCommand = flags.contains(.CommandKeyMask)
        
        let hasShift = flags.contains(.ShiftKeyMask)
        
        let hasAlt = flags.contains(.AlternateKeyMask)
        
        let hasControl = flags.contains(.ControlKeyMask)
        
        print("hasCommand: " + String(hasCommand))
        print("hasShift: " + String(hasShift))
        print("hasAlt: " + String(hasAlt))
        print("hasControl: " + String(hasControl))
        
        let noneModifiers = !hasCommand && !hasShift && !hasAlt && !hasControl
        
        print("noneModifiers: " + String(noneModifiers))
        
        let NSBackspaceFunctionKey = 127
        
        let NSEnterFunctionKey = 13
        
        switch char {
        case NSBackspaceFunctionKey where noneModifiers,
            convertToInt("h") where noneModifiers,
            NSLeftArrowFunctionKey where noneModifiers:
            // delete or h or left arrow
            // h was used to emulate vim hotkeys
            // 127 is backspace key
            
            if let field = textField {
                if !field.hidden {
                    let stringValue = field.stringValue
                    let len = stringValue.characters.count
                    
                    if len > 0 {
                        field.stringValue = stringValue.substringToIndex(stringValue.endIndex.predecessor())
                    }
                    
                    return
                }
            }
            
            let parentUrl = curFsItem.fileURL.URLByDeletingLastPathComponent
            
            // Remember last directory, this dir should be selected when backed to parent dir
            lastChildDir = curFsItem.fileURL
            
            if let url = parentUrl {
                changeDirectory(url)
                return
            }
            
        case NSEnterFunctionKey where noneModifiers,
            convertToInt("l") where noneModifiers,
            NSRightArrowFunctionKey where noneModifiers:
            // enter or l or right arrow
            // l is used to emulate vim hotkeys
            dblClk(tableview)
            return
            
        case convertToInt("h") where hasControl:
            if !isLeft {
                insertTab(nil)
            }
            return
            
        case convertToInt("l") where hasControl:
            if isLeft {
                insertTab(nil)
            }
            return
            
        case NSF5FunctionKey where noneModifiers:
            copySelectedFiles()
            return
            
        case NSF6FunctionKey where noneModifiers:
            moveSelectedFiles()
            return
            
        case NSF7FunctionKey where noneModifiers:
            // create new directory
            return;
            
        case NSF8FunctionKey where noneModifiers:
            deleteSelectedFiles()
            return
            
        case convertToInt("g") where noneModifiers:
            if isGpressed {
                selectRow(0)
            } else {
                isGpressed = true
                NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "clearGPressed", userInfo: nil, repeats: false)
            }
            return
            
        case convertToInt("G") where hasShift:
            let count = numberOfRowsInTableView(tableview)
            selectRow(count - 1)
            return
            
        default:
            break
        }
        
        interpretKeyEvents([theEvent])
        super.keyDown(theEvent)
    }
    
    func selectLastRow() {
        let indexSet = NSIndexSet(index: numberOfRowsInTableView(tableview))
        tableview.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
    
    func selectRow(row: Int) {
        let indexSet = NSIndexSet(index: row)
        tableview.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableview.scrollRowToVisible(row)
    }
    
    func clearGPressed() {
        isGpressed = false
    }
    
    @IBAction func showQuickLookPanel(sender: NSMenuItem) {
        QLPreviewPanel.sharedPreviewPanel().makeKeyAndOrderFront(self)
    }
    
    func copySelectedFiles() {
        let item = getSelectedItem()
        
        if let fsItem = item {
            let windowController = self.view.window!.windowController as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.path
            let files = [fsItem.name]
            let result = workspace.performFileOperation(NSWorkspaceCopyOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
            
            if result {
                print("copy succeeded")
            }
        }
        
    }
    
    func moveSelectedFiles() {
        let item = getSelectedItem()
        if let fsItem = item {
            let windowController = self.view.window!.windowController as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.path
            let files = [fsItem.name]
            let result = workspace.performFileOperation(NSWorkspaceMoveOperation, source: curFsItem.path, destination: destination, files: files, tag: nil)
            
            if result {
                print("move succeeded")
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
                    print("delete succeeded")
                }
            default:
                break
            }
        })
    }
    
    // tab键按下
    override func insertTab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController as! MainWindowController
        windowController.switchFocus()
    }
    
    // shift + tab键按下
    override func insertBacktab(sender: AnyObject?) {
        let windowController = self.view.window!.windowController as! MainWindowController
        windowController.switchFocus()
    }
    
    override func insertText(insertString: AnyObject) {
        print(insertString)
        
        var stringValue: String
        
        if let field = textField {
            if field.hidden {
                field.hidden = false
            }
            
            stringValue = field.stringValue + (insertString as! String)
        } else {
            let frameRect = NSMakeRect(20, 20, 100, 20)
            textField = NSTextField(frame: frameRect)
            stringValue = insertString as! String
            
            self.view.addSubview(textField!)
//            self.view.window!.makeFirstResponder(textField!)
        }
        
        let filtered = curFsItem.children.filter {
            return $0.localizedName.rangeOfString(stringValue, options: .CaseInsensitiveSearch) != nil
        }
        
        if filtered.count > 0 {
            textField!.stringValue = stringValue
        }
        
    }
    
    override func cancelOperation(sender: AnyObject?) {
        print("esc pressed")
        
        textField?.stringValue = ""
        textField?.hidden = true
    }
    
    convenience override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: nil)
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, url: NSURL?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let homeDir = NSHomeDirectory();
        
        dateFormatter.dateStyle = .MediumStyle
        dateFormatter.timeStyle = .MediumStyle
        let dirUrl = url ?? NSURL.fileURLWithPath(homeDir, isDirectory: true)
        onDirChange(dirUrl)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func directoryMonitorDidObserveChange(directoryMonitor: DirectoryMonitor) {
        print("directoryMonitorDidObserveChange")
        
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
                
                let theError: NSErrorPointer = nil
                do {
                    try self.fileManager.createDirectoryAtURL(dirUrl, withIntermediateDirectories: false, attributes: nil)
                } catch let error as NSError {
                    theError.memory = error
                    // handle the error
                } catch {
                    fatalError()
                }
            default:
                break
            }
        })
    }
    
    func execcmd(cmdname: String) -> NSString {
        var outstr = ""
        let task = NSTask()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", cmdname]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: NSUTF8StringEncoding) {
            print(output)
            outstr = output as String
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        print(status)
        
        return outstr
    }
    
    @IBAction func compare(sender: NSMenuItem) {
        let curItems = getMarkedItems(false)
        
        let windowController = self.view.window!.windowController as! MainWindowController
        let targetViewController = windowController.getTargetTabItem()
        let targetItems = targetViewController.getMarkedItems(false)
        
        if curItems.count >= 2 {
            execcmd("/usr/local/bin/bcompare \"" + curItems[0].path + "\" \"" + curItems[1].path + "\"")
        } else if curItems.count == 1 && targetItems.count >= 1 {
            if isLeft {
                execcmd("/usr/local/bin/bcompare \"" + curItems[0].path + "\" \"" + targetItems[0].path + "\"")
            } else {
                execcmd("/usr/local/bin/bcompare \"" + targetItems[0].path + "\" \"" + curItems[0].path + "\"")
            }
        } else if curItems.count == 1 {
            execcmd("/usr/local/bin/bcompare \"" + curItems[0].path + "\"")
        }
    }
    
    func numberOfPreviewItemsInPreviewPanel(panel: QLPreviewPanel!) -> Int {
        return 1
    }
    
    func previewPanel(panel: QLPreviewPanel!, previewItemAtIndex index: Int) -> QLPreviewItem! {
        print("previewPanel previewItemAtIndex method called.")
        let item = getSelectedItem()
        return item?.fileURL ?? NSURL()
    }
    
    func previewPanel(panel: QLPreviewPanel!, handleEvent event: NSEvent!) -> Bool {
        if event.type == .KeyDown {
            tableview.keyDown(event)
            return true
        }
        
        return false
    }
    
    override func acceptsPreviewPanelControl(panel: QLPreviewPanel!) -> Bool {
        return true
    }
    
    override func beginPreviewPanelControl(panel: QLPreviewPanel!) {
        panel.delegate = self
        panel.dataSource = self
        isQLMode = true
        print("begin preview panel")
    }
    
    override func endPreviewPanelControl(panel: QLPreviewPanel!) {
        isQLMode = false
        print("end preview panel")
    }
    
    
    
}
