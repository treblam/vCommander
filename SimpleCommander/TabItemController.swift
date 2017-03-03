//
//  TabItemController.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

import Quartz

class TabItemController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, DirectoryMonitorDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, NSMenuDelegate, SCTableViewDelegate
{

    @IBOutlet weak var tableview: SCTableView!
    
    var curFsItem: FileSystemItem!
    
    let fileManager = FileManager()
    
    let dateFormatter = DateFormatter()
    
    let workspace = NSWorkspace.shared()
    
    let preferenceManager = PreferenceManager()
    
    var dm: DirectoryMonitor!
    
    var lastChildDir: URL?
    var lastChildDirIndex: Int?
    
    var isQLMode = false
    
    var isGpressed = false
    
    // Variables for type select
    var typeSelectTextField: NSTextField?
    var typeSelectIndices: [Int]?
    var typeSelectIndex: Int?
    
    var lastRenamedFileURL: URL?
    
    var lastRenamedFileIndex: Int?
    
    let pasteboard = NSPasteboard.general()
    
    var selectedItems = [URL]()
    var markedItems = [URL]()
    
    var isLeft: Bool {
        let windowController = self.view.window!.windowController as! MainWindowController
        return self === windowController.leftTab
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
//        tableview.target = self
        tableview.register(forDraggedTypes: [NSFilenamesPboardType])
        //tableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.None
        tableview.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
    }
    
    override func viewWillDisappear() {
        dm.stopMonitoring()
    }
    
    func getSelectedItem() -> FileSystemItem? {
        let selectedIndex = tableview.selectedRowIndexes
        if selectedIndex.count == 0 {
            return nil
        }
        
        let index = selectedIndex.first
        
        return curFsItem.children[index!]
    }
    
    func getMarkedItems(_ isUseSelect: Bool=true) -> [FileSystemItem] {
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
    
    @IBAction func onDoubleClick(_ sender:AnyObject) {
        openFileOrDirectory(true)
    }
    
    @IBAction func onRowClicked(_ sender:AnyObject) {
        print("row was clicked, \(tableview.clickedRow)")
        
        if typeSelectIndices != nil && typeSelectIndices!.count > 0 {
            clearTypeSelect()
            
            if tableview.clickedRow >= 0 {
                selectRow(tableview.clickedRow)
            }
        }
    }
    
    func openFileOrDirectory(_ isMouseClick: Bool) {
        let item = getSelectedItem()
        
        if isMouseClick && tableview.clickedRow == -1 {
            return
        }
        
        if let fsItem = item {
            print("fileURL: " + fsItem.fileURL.path)
            if (fsItem.isDirectory) {
                changeDirectory(fsItem.fileURL as URL)
            } else {
                print("It's not directory, can't step into")
                workspace.openFile(fsItem.fileURL.path)
            }
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if (curFsItem == nil) {
            return 0
        } else {
            return curFsItem.children.count
        }
    }
    
    func updateMarkedRowsApperance() {
        tableview.enumerateAvailableRowViews { rowView, rowIndex in
            for column in 0 ..< rowView.numberOfColumns {
                let cellView: AnyObject? = rowView.view(atColumn: column) as AnyObject?
                
                if let tableCellView = cellView as? NSTableCellView {
                    let textField = tableCellView.textField
                    if let _ = rowView as? SCTableRowView {
                        if let text = textField {
                            let isMarked = self.tableview.isRowMarked(rowIndex)
                            //                            print("rowIndex: \(rowIndex)")
                            //                            print("isMarked: \(isMarked)")
                            
                            if isMarked {
                                text.textColor = NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1)
                            } else {
                                if let str = tableCellView.identifier {
                                    switch str {
                                    case "localizedName":
                                        text.textColor = NSColor.controlTextColor
                                    default:
                                        text.textColor = NSColor.disabledControlTextColor
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let colIdentifier: String = tableColumn!.identifier
        
        let tableCellView = tableView.make(withIdentifier: colIdentifier, owner: self) as! NSTableCellView
        
        let item = self.curFsItem.children[row]
        
        // Customize appearance for marked rows
        let isMarked = self.tableview.isRowMarked(row)
        
        if let textField = tableCellView.textField {
            if isMarked {
                textField.textColor = NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1)
            } else {
                if let identifier = tableCellView.identifier {
                    switch identifier {
                    case "localizedName":
                        textField.textColor = NSColor.controlTextColor
                    default:
                        textField.textColor = NSColor.disabledControlTextColor
                    }
                }
            }
        }
        
        switch colIdentifier {
            case "localizedName":
                tableCellView.textField!.stringValue = item.localizedName
                tableCellView.imageView!.image = item.icon
                
            case "dateOfLastModification":
                tableCellView.textField!.stringValue = dateFormatter.string(from: item.dateOfLastModification as Date)
                
            case "size":
                tableCellView.textField!.stringValue = item.localizedSize
                
            case "localizedType":
                if item.localizedType != nil {
                    tableCellView.textField!.stringValue = item.localizedType
                }
                
            default:
                tableCellView.textField!.stringValue = ""
            
        }
        
        return tableCellView
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let cellId = "cell_identifier"
        
        var tableRowView = tableView.make(withIdentifier: cellId, owner: self) as? SCTableRowView
        
        if tableRowView == nil {
            tableRowView = SCTableRowView(frame: NSMakeRect(0, 0, tableview.frame.size.width, 80))
            tableRowView?.identifier = cellId
        }
        
        tableRowView?.marked = tableView.isRowSelected(row)
        
        return tableRowView
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 22.0
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        print("sortDescriptorsDidChange called.")
        refreshTableview()
    }
    
    func refreshTableview() {
        print("refreshTableview called")
        
        var selectedIndexes = NSMutableIndexSet()
        
        sortData()
        
        tableview.reloadData()
        
        if let url = lastRenamedFileURL {
            lastRenamedFileIndex = curFsItem.children.index {fileItem in
                return fileItem.fileURL.path == url.path
            }
            
            if let theIndex = lastRenamedFileIndex {
                selectedIndexes.add(theIndex)
            } else {
                selectedIndexes = getIndexesForItems(selectedItems)
            }
            print("lastRenamedFileURL: \(lastRenamedFileURL)")
            print("lastRenamedFileIndex: \(lastRenamedFileIndex)")
            lastRenamedFileURL = nil
        } else {
            selectedIndexes = getIndexesForItems(selectedItems)
        }
        
        print("Start to reselect")
        if selectedIndexes.count > 0 {
            selectRow(selectedIndexes.firstIndex)
        }
        tableview.markRowIndexes(getIndexesForItems(markedItems) as IndexSet, byExtendingSelection: false)
    }
    
    func sortData() {
        let sortDescriptors = tableview.sortDescriptors
        let objectsArray = curFsItem.children as NSArray
        let sortedObjects = objectsArray.sortedArray(using: sortDescriptors)
        
        curFsItem.children = sortedObjects as! [FileSystemItem]
    }
    
    func getIndexesForItems(_ items: [URL]) -> NSMutableIndexSet {
        let indexes = NSMutableIndexSet()
        
        for item in items {
            let index = curFsItem.children.index {
                ($0.fileURL as NSURL).fileReferenceURL() == item
            }
            
            if let theIndex = index {
                indexes.add(theIndex)
            }
        }
        
        return indexes
    }
    
    func rememberMarkedItems() {
        markedItems.removeAll()
        
        tableview.markedRows.enumerate({(index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            // todo: To be optimized for file deletion or move
            if index < 0 || index >= self.curFsItem.children.count {
                return
            }
            let fileRefURL = (self.curFsItem.children[index].fileURL as NSURL).fileReferenceURL()
            print("add \(fileRefURL) to markedItems")
            self.markedItems.append(fileRefURL!)
        })
    }
    
    func rememberSelectedItems(_ selectedIndexes: IndexSet) {
        print("Start to remember selected items")
        selectedItems.removeAll()
        
        selectedIndexes.forEach {
            if $0 < 0 || $0 >= self.curFsItem.children.count {
                return
            }
            
            let fileRefURL = (self.curFsItem.children[$0].fileURL as NSURL).fileReferenceURL()
            print("selectedIndex: \($0)")
            print("add file to selectedItems: \(fileRefURL!)")
            self.selectedItems.append(fileRefURL!)
        }
    }
    
    func tableViewMarkedViewsDidChange() {
        print("tableViewMarkedViewsDidChange() called, start to rememberMarkedItems()")
        rememberMarkedItems()
        updateMarkedRowsApperance()
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDigChange called. index: \(tableview.selectedRowIndexes.first)")
        
        if isQLMode {
            QLPreviewPanel.shared().reloadData()
        }
    }
    
    func onDirChange(_ url: URL) {
        if !fileManager.fileExists(atPath: url.relativePath) {
            backToParentDirectory()
            return
        }
        
        let suc = fileManager.changeCurrentDirectoryPath(url.path)
        if (!suc) {
            print("change directory fail")
        }
        
        print(fileManager.currentDirectoryPath)
        
        curFsItem = FileSystemItem(fileURL: URL(fileURLWithPath: fileManager.currentDirectoryPath))
        
        title = curFsItem.localizedName
        
        // Clean the data for last directory
        if (tableview !== nil) {
            print("clean data")
            cleanTableViewData()
        }
        
        print("Change directory success")
        
        // Notify the panel the directory was changed.
//        sendNotification()
        
       // let tabItem = (self.view.superview as! NSTabView).selectedTabViewItem
       // let model = tabItem?.identifier as! TabBarModel
        
       // model.title = title ?? "Untitled"
       // tabItem?.identifier = model

        if let tabview = (self.view.superview as? NSTabView) {
            let tabItem = tabview.selectedTabViewItem
            let model = tabItem?.identifier as? TabBarModel
            model?.title = title ?? "Untitled"
            tabItem?.identifier = model
        }
        
        dm = DirectoryMonitor(URL: curFsItem.fileURL)
        dm.delegate = self
        dm.startMonitoring()
        print("start monitor \(curFsItem.fileURL.path)")
    }

    func cleanTableViewData() {
        tableview.cleanData()
        clearTypeSelect()
    }
    
    func changeDirectory(_ url: URL) {
        onDirChange(url)
        tableview.reloadData()
        selectRowIfNecessary()
    }
    
    func sendNotification() {
        let notificationKey = "DirectoryChanged"
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: self)
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    func convertToInt(_ str: String) -> Int {
        let s1 = str.unicodeScalars
        let s2 = s1[s1.startIndex].value
        return Int(s2)
    }
    
    func backToParentDirectory() {
        var parentUrl = curFsItem.fileURL.deletingLastPathComponent()
        while !fileManager.fileExists(atPath: parentUrl.relativePath) {
            parentUrl = parentUrl.deletingLastPathComponent()
        }
        
        // Remember last directory, this dir should be selected when backed to parent dir
        lastChildDir = curFsItem.fileURL as URL
        changeDirectory(parentUrl)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        print("keyCode: " + String(theEvent.keyCode))
        
        let flags = theEvent.modifierFlags
        let s = theEvent.charactersIgnoringModifiers!
        let char = convertToInt(s)
        print("char:" + String(char))
        
        let hasCommand = flags.contains(.command)
        let hasShift = flags.contains(.shift)
        let hasAlt = flags.contains(.option)
        let hasControl = flags.contains(.control)
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
//            convertToInt("h") where noneModifiers,
            NSLeftArrowFunctionKey where noneModifiers:
            // delete or h or left arrow
            // h was used to emulate vim hotkeys
            // 127 is backspace key
            
            if char == NSBackspaceFunctionKey && noneModifiers {
                if let field = typeSelectTextField {
                    if !field.isHidden {
                        let stringValue = field.stringValue
                        let len = stringValue.characters.count
                        
                        if len > 0 {
                            let filterString = stringValue.substring(to: stringValue.characters.index(before: stringValue.endIndex))
                            field.stringValue = filterString
                            updateTypeSelectMatches(byString: filterString)
                        }
                        
                        return
                    }
                }
            }
            
            backToParentDirectory()
            return
            
        case NSEnterFunctionKey where noneModifiers,
//            convertToInt("l") where noneModifiers,
            NSRightArrowFunctionKey where noneModifiers:
            // enter or l or right arrow
            // l is used to emulate vim hotkeys
            openFileOrDirectory(false)
            return
            
//        case convertToInt("h") where hasControl:
//            if !isLeft {
//                insertTab(nil)
//            }
//            return
//            
//        case convertToInt("l") where hasControl:
//            if isLeft {
//                insertTab(nil)
//            }
//            return
            
        case NSF5FunctionKey where noneModifiers:
            copySelectedFiles(nil)
            return
            
        case NSF6FunctionKey where noneModifiers:
            moveSelectedFiles(nil)
            return
            
        case NSF7FunctionKey where noneModifiers:
            // create new directory
            return;
            
        case NSF8FunctionKey where noneModifiers:
            deleteSelectedFiles(nil)
            return
            
//        case convertToInt("g") where noneModifiers:
//            if isGpressed {
//                selectRow(0)
//            } else {
//                isGpressed = true
//                NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "clearGPressed", userInfo: nil, repeats: false)
//            }
//            return
//            
//        case convertToInt("G") where hasShift:
//            let count = numberOfRowsInTableView(tableview)
//            selectRow(count - 1)
//            return
            
        default:
            break
        }
        
        interpretKeyEvents([theEvent])
        super.keyDown(with: theEvent)
    }
    
    func selectLastRow() {
        let indexSet = IndexSet(integer: numberOfRows(in: tableview))
        tableview.selectRowIndexes(indexSet, byExtendingSelection: false)
    }
    
    func selectRow(_ row: Int) {
        let indexSet = IndexSet(integer: row)
        tableview.selectRowIndexes(indexSet, byExtendingSelection: false)
        tableview.scrollRowToVisible(row)
    }
    
    func selectRowIfNecessary() {
        var toBeSelectedRowIndex: Int?
        if curFsItem.children.count > 0 {
            if let lastViewedDir = lastChildDir {
                toBeSelectedRowIndex = curFsItem.children.index(where: {$0.fileURL == lastViewedDir})
                lastChildDir = nil
            }
            
            if toBeSelectedRowIndex != nil && toBeSelectedRowIndex! >= 0 {
                selectRow(toBeSelectedRowIndex!)
            }
        }
    }
    
    func clearGPressed() {
        isGpressed = false
    }
    
    @IBAction func showQuickLookPanel(_ sender: AnyObject?) {
        QLPreviewPanel.shared().makeKeyAndOrderFront(self)
    }
    
    @IBAction func copySelectedFiles(_ sender: AnyObject?) {
        let items = getMarkedItems()
        
        if items.count > 0 {
            let windowController = self.view.window!.windowController as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.fileURL
            
            for item in items {
                let toUrl = URL(string: item.fileURL.lastPathComponent, relativeTo: destination)
                
                do {
                   try fileManager.copyItem(at: item.fileURL, to: toUrl!)
                } catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
        }
    }
    
    @IBAction func moveSelectedFiles(_ sender: AnyObject?) {
        let items = getMarkedItems()
        
        if items.count > 0 {
            let windowController = self.view.window!.windowController as! MainWindowController
            let targetViewController = windowController.getTargetTabItem()
            let destination = targetViewController.curFsItem.fileURL
            var fileName: String
            var toURL: URL
            
            for item in items {
                fileName = item.fileURL.lastPathComponent.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)!
                toURL = URL(string: fileName, relativeTo: destination)!
                
                do {
                    try fileManager.moveItem(at: item.fileURL, to: toURL)
                } catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
        }
    }
    
    @IBAction func deleteSelectedFiles(_ sender: AnyObject?) {
        let items = getMarkedItems()
        
        if items.count == 0 {
            return
        }
        
        let files = items.map { $0.name }
        let fileUrls = items.map { $0.fileURL }
        
        let alert = NSAlert()
        alert.messageText = "删除"
        
        var informativeText = "确定删除选中的文件/文件夹吗？"
        var showCount = files.count
        var suffix = ""
        if files.count > 5 {
            showCount = 5
            suffix = "\n..."
        }
        
        for i in 0 ..< showCount {
            informativeText += ("\n" + files[i]!)
        }
        informativeText += suffix
        
        alert.informativeText = informativeText
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        alert.alertStyle = .warning
        alert.window.initialFirstResponder = alert.buttons[0]
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { responseCode in
            
            switch responseCode {
            case NSAlertFirstButtonReturn:
                self.workspace.recycle(fileUrls, completionHandler: {(newUrls, error) in
                    if error != nil {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "删除失败"
                        errorAlert.addButton(withTitle: "确定")
                        errorAlert.runModal()
                    } else {
                        print("删除成功")
                    }
                })
            default:
                break
            }
        })
    }
    
    @IBAction func editSelectedFile(_ sender: NSMenuItem) {
        let item = getSelectedItem()
        
        if let fsItem = item {
            print("fileURL: " + fsItem.fileURL.path)
            if (fsItem.isDirectory) {
                let alert = NSAlert()
                alert.messageText = "不支持编辑该类型的文件"
                alert.informativeText = "不支持编辑该类型的文件"
                alert.beginSheetModal(for: self.view.window!, completionHandler: {responseCode in
                    
                })
            } else {
                print("it's not directory, can't step into")
                workspace.openFile(fsItem.fileURL.path, withApplication: preferenceManager.textEditor!)
            }
        }
    }
    
    @IBAction func markAll(_ sender: NSMenuItem) {
        let count = self.curFsItem.children.count
        let indexSet = IndexSet(integersIn: 0..<count)
        tableview.markRowIndexes(indexSet, byExtendingSelection: true)
    }
    
    // tab键按下
    override func insertTab(_ sender: Any?) {
        print("Tab pressed")
        switchFocus()
    }
    
    // shift + tab键按下
    override func insertBacktab(_ sender: Any?) {
        print("Back tab pressed")
        switchFocus()
    }
    
    func switchFocus() {
        let windowController = self.view.window!.windowController as! MainWindowController
        clearTypeSelect()
        windowController.switchFocus()
    }
    
    // Temporarily remove this feature.
    override func insertText(_ insertString: Any) {
        print(insertString)
        
        var stringValue: String
        
        // If the textfield already exists
        if let field = typeSelectTextField {
            if field.isHidden {
                field.isHidden = false
            }
            
            stringValue = field.stringValue + (insertString as! String)
        } else {
            // Create a new NSTextField
            typeSelectTextField = NSTextField()
            stringValue = insertString as! String
            
            typeSelectTextField!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(typeSelectTextField!)
            typeSelectTextField?.isEditable = false
            typeSelectTextField?.drawsBackground = false
            
            let trailingConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20)
            let bottomConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -20)
            let widthConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150)
            let heightConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
            self.view.addConstraints([widthConstraint, heightConstraint, trailingConstraint, bottomConstraint])
//            self.view.window!.makeFirstResponder(textField!)
        }
        
        updateTypeSelectMatches(byString: stringValue)
        
        if typeSelectIndices!.count > 0 {
            typeSelectTextField!.stringValue = stringValue
            typeSelectIndex = 0;
            
            selectRow(typeSelectIndices![typeSelectIndex!])
        }
    }
    
    func updateTypeSelectMatches(byString string: String) {
        typeSelectIndices = curFsItem.children.enumerated().filter {
            $0.element.localizedName.transformToPinYin().range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil
            }.map {
                $0.offset
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        print("esc pressed, clear type select")
        clearTypeSelect()
    }
    
    func clearTypeSelect() {
        print("Start to clear type select")
        typeSelectTextField?.stringValue = ""
        typeSelectTextField?.isHidden = true
        typeSelectIndices = nil
        typeSelectIndex = nil
    }
    
    convenience override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: nil)
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, url: URL?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        let homeDir = NSHomeDirectory();
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        
        let dirUrl = url ?? URL(fileURLWithPath: homeDir, isDirectory: true)
        onDirChange(dirUrl)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func directoryMonitorDidObserveChange(_ directoryMonitor: DirectoryMonitor) {
        print("directoryMonitorDidObserveChange")
        
        DispatchQueue.main.async(execute: {
            // If the current directory was deleted, go to its parent directory
            if !self.fileManager.fileExists(atPath: self.curFsItem.fileURL.relativePath) {
                self.backToParentDirectory()
                return
            }
            self.refreshData()
            self.refreshTableview()
        })
    }
    
    // Refresh the items if directory changes
    func refreshData() {
        curFsItem = FileSystemItem(fileURL: curFsItem.fileURL)
    }
    
    @IBAction func newDirectory(_ sender: NSMenuItem) {
        let alert = NSAlert()
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        alert.messageText = "新建文件夹"
        alert.informativeText = "请输入文件夹名称"
        
        let textField = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
        textField.placeholderString = "文件夹名称"
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { responseCode in
            switch responseCode {
            case NSAlertFirstButtonReturn:
                let dirName = textField.stringValue
                let dirUrl = self.curFsItem.fileURL.appendingPathComponent(dirName)
                
                let theError: NSErrorPointer? = nil
                do {
                    try self.fileManager.createDirectory(at: dirUrl, withIntermediateDirectories: false, attributes: nil)
                    // Select the new directory after create
                    self.lastRenamedFileURL = dirUrl
                } catch let error as NSError {
                    theError??.pointee = error
                    // handle the error
                    print("def");
                } catch {
                    print("ghi")
                    fatalError()
                }
            default:
                break
            }
        })
    }
    
    func execcmd(_ cmdname: String) -> NSString {
        var outstr = ""
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", cmdname]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            print(output)
            outstr = output as String
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        print(status)
        
        return outstr as NSString
    }
    
    @IBAction func compare(_ sender: AnyObject?) {
        let curItems = getMarkedItems(false)
        
        let windowController = self.view.window!.windowController as! MainWindowController
        let targetViewController = windowController.getTargetTabItem()
        let targetItems = targetViewController.getMarkedItems(false)
        
        if curItems.count >= 2 {
            _ = execcmd(preferenceManager.diffTool! + " \"" + curItems[0].path + "\" \"" + curItems[1].path + "\"")
        } else if curItems.count == 1 && targetItems.count >= 1 {
            if isLeft {
                _ = execcmd(preferenceManager.diffTool! + " \"" + curItems[0].path + "\" \"" + targetItems[0].path + "\"")
            } else {
                _ = execcmd(preferenceManager.diffTool! + " \"" + targetItems[0].path + "\" \"" + curItems[0].path + "\"")
            }
        } else if curItems.count == 1 {
            _ = execcmd(preferenceManager.diffTool! + " \"" + curItems[0].path + "\"")
        }
    }
    
    // Choose an app to open current file
    @IBAction func openWith(_ sender: AnyObject?) {
        let file = getSelectedItem()
        let filePath = file?.path
        let appDirURL: URL
        
        let appDirURLArr = fileManager.urls(for: .applicationDirectory, in: .systemDomainMask)
        
        if appDirURLArr.count > 0 {
            appDirURL = appDirURLArr[0]
            let chooseAppDialog = NSOpenPanel()
            chooseAppDialog.directoryURL = appDirURL
            chooseAppDialog.canChooseDirectories = false
            chooseAppDialog.canCreateDirectories = false
            chooseAppDialog.canChooseFiles = true
            chooseAppDialog.allowedFileTypes = ["app"]
            chooseAppDialog.begin { (result) -> Void in
                if result == NSFileHandlingPanelOKButton {
                    let appPath = chooseAppDialog.url?.path
                    if appPath != nil && filePath != nil {
                        self.workspace.openFile(filePath!, withApplication: appPath)
                    }
                }
            }
        }
    }
    
    @IBAction func revealInFinder(_ sender: AnyObject?) {
        let selectedFiles = getMarkedItems()
        
        let fileURLs = selectedFiles.map {
            return $0.fileURL
        }
        
        workspace.activateFileViewerSelecting(fileURLs as [URL])
    }
    
    @IBAction func rename(_ sender: AnyObject?) {
        let row = tableview.selectedRow
        let selected = getSelectedItem()
        print("path:" + (selected?.path)!)
        print("row:" + String(row))
        
        let cellview = tableview.view(atColumn: 0, row: row, makeIfNecessary: false) as! NSTableCellView
        cellview.textField?.isEditable = true
        tableview.editColumn(0, row: row, with: nil, select: true)
    }
    
    @IBAction func paste(_ sender: AnyObject?) {
        let classArray : Array<AnyClass> = [NSURL.self]
        
        let canReadData = self.containsAcceptableURLsFromPasteboard(pasteboard)
        if canReadData {
            print("canReadData: \(canReadData)")
            let objectsToPaste = pasteboard.readObjects(forClasses: classArray, options: nil) as! Array<URL>
            var toURL: URL!
            var fileName: String!
            for url in objectsToPaste {
                fileName = url.lastPathComponent
                if #available(OSX 10.11, *) {
                    toURL = URL(fileURLWithPath: fileName, relativeTo: curFsItem.fileURL as URL)
                } else {
                    // Fallback on earlier versions
                    let escapedFileName = fileName.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                    toURL = URL(string: escapedFileName!, relativeTo: curFsItem.fileURL as URL)
                }
                
                do {
                    try fileManager.copyItem(at: url, to: toURL)
                } catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                }
            }
        }
    }
    
    @IBAction func copy(_ sender: AnyObject?) {
        let files = getMarkedItems()
        let objectsToCopy: Array<URL>
        
        if files.count > 0 {
            pasteboard.clearContents()
            objectsToCopy = files.map {
                return ($0.fileURL as URL)
            }
            pasteboard.writeObjects(objectsToCopy as [NSPasteboardWriting])
        }
    }
    
    @IBAction func getInfo(_ sender: AnyObject?) {
        let files = getMarkedItems()
        let filesToGetInfo = NSMutableArray()
        
        for file in files {
            filesToGetInfo.add(file.fileURL.path)
        }
        let pasteboard = NSPasteboard.withUniqueName()
        pasteboard.declareTypes([NSStringPboardType], owner: nil)
        print("filesToGetInfo: \(filesToGetInfo)")
        pasteboard.setPropertyList(filesToGetInfo, forType: NSFilenamesPboardType)
        NSPerformService("Finder/Show Info", pasteboard);
    }
    
    @IBAction func copyFullPath(_ sender: AnyObject?) {
        let files = getMarkedItems()
        let result = files.reduce("", {
            return $0 + "\n" + $1.path
        });
        
        pasteboard.clearContents()
        pasteboard.writeObjects([result as NSPasteboardWriting])
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let textField = obj.object as? NSTextField
        let newName = textField?.stringValue
        let selected = getSelectedItem()
        let currentName = selected?.fileURL.lastPathComponent
        
        if newName == nil || newName == "" {
            print("New name is empty, restore to old name.")
            textField?.stringValue = currentName!
            return
        }
        
        if newName == currentName {
            print("New name is the same as the old name, do nothing.")
            return
        }
        
        print("currentName: \(currentName)")
        print("newName: \(newName)")
        
        if textField!.tag == 1 {
            do {
                print("start to change name")
                try fileManager.moveItem(atPath: currentName!, toPath: newName!)
                // Remember the path after rename
                print("Rename done.")
                
                let encodedNewName = newName!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                if let theEncodedNewName = encodedNewName {
                    lastRenamedFileURL = URL(string: theEncodedNewName, relativeTo: curFsItem.fileURL as URL)!
                }
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
        
        textField?.isEditable = false
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        let items = getMarkedItems()
        return items.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        print("previewPanel previewItemAtIndex method called.")
        let items = getMarkedItems()
        let item = items[index]
        return item.fileURL as QLPreviewItem!
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        if event.type == .keyDown {
            tableview.keyDown(with: event)
            return true
        }
        
        return false
    }
    
    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        return true
    }
    
    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.delegate = self
        panel.dataSource = self
        isQLMode = true
        print("begin preview panel")
    }
    
    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        isQLMode = false
        print("end preview panel")
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([NSFilenamesPboardType], owner: self)
        pboard.setData(data, forType: NSFilenamesPboardType)
        return true
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = self.curFsItem.children[row]
        return item.fileURL as NSPasteboardWriting?
    }
    
//    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
//        print("shouldSelectRow called")
//        if let indices = typeSelectIndices {
//            if indices.count > 0 && indices.contains(row) {
//                return true
//            } else {
//                return false
//            }
//        } else {
//            return true
//        }
//    }
    
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        print("selectionIndexesForProposedSelection called.")
        
        let proposedIndex = proposedSelectionIndexes.first
        let currentIndex = tableView.selectedRowIndexes.first
        
        var myArrIndex: Int?
        var myProposedIndex: Int?
        
        var isAccept = false
        
        
        if let indices = typeSelectIndices {
            
            print("typeSelectIndices is not nil, count: \(indices.count)")
            
            myArrIndex = indices.index(of: currentIndex ?? -1)
            print("myArrIndex: \(myArrIndex)")
            if indices.count > 1 && myArrIndex != nil && proposedIndex != nil && currentIndex != nil {
                // Already at the upper bounds, and user pressed up arrow
                if myArrIndex! == 0 && proposedIndex! < currentIndex! {
                    myProposedIndex = indices[indices.count - 1]
                }
                // Already at the bottom bounds, and user clicked down arrow
                if myArrIndex! == indices.count - 1 && proposedIndex! > currentIndex!  {
                    myProposedIndex = indices[0]
                }
            }
            
            // proposedIndex is in my array
            if indices.index(of: proposedIndex ?? -1) != nil {
                isAccept = true
            }
        } else {
            isAccept = true
        }
        
        print("proposedIndex: \(proposedIndex)")
        print("currentIndex: \(currentIndex)")
        if isAccept {
            print("return proposedIndex: \(proposedIndex)")
            rememberSelectedItems(proposedSelectionIndexes)
            return proposedSelectionIndexes
        } else {
            if let mpIndex = myProposedIndex {
                selectRow(mpIndex)
            }
            print("return currentIndex: \(currentIndex)")
            return IndexSet(integer: currentIndex ?? 0)
        }
    }

    func pasteboardReadingOptions() -> [String: AnyObject] {
        return [
            NSPasteboardURLReadingFileURLsOnlyKey: true as AnyObject
        ]
    }
    
    func containsAcceptableURLsFromPasteboard(_ pasteboard: NSPasteboard) -> Bool {
        return pasteboard.canReadObject(forClasses: [NSURL.self], options: self.pasteboardReadingOptions())
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableViewDropOperation) -> NSDragOperation {
        
        if dropOperation == NSTableViewDropOperation.above {
            if info.draggingSource() as? NSTableView == tableView {
                // Reorder, implement later.
            } else {
                let canReadData = self.containsAcceptableURLsFromPasteboard(info.draggingPasteboard())
                if canReadData {
                    info.animatesToDestination = true
                    return NSDragOperation.copy
                }
            }
        }
        
        return NSDragOperation()
    }
    
    func tableView(_ tableView: NSTableView, updateDraggingItemsForDrag draggingInfo: NSDraggingInfo) {
        if (draggingInfo.draggingSource() as? NSTableView != tableView) {
            let tableCellView = tableView.make(withIdentifier: "localizedName", owner: self) as! NSTableCellView
            var validCount = 0
            
            draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.init(rawValue: 0), for: tableView, classes: [NSURL.self, NSPasteboardItem.self], searchOptions: self.pasteboardReadingOptions(), using: { (draggingItem: NSDraggingItem, idx: Int, stop:UnsafeMutablePointer<ObjCBool>) in
                
                if draggingItem.item is URL {
                    let fileURL = draggingItem.item as! URL
                    draggingItem.draggingFrame = tableCellView.frame
                    
                    let item = FileSystemItem(fileURL: fileURL)
                    draggingItem.imageComponentsProvider = {
                        tableCellView.textField!.stringValue = item.localizedName
                        tableCellView.imageView!.image = item.icon
                        
                        return tableCellView.draggingImageComponents
                    }
                    validCount += 1
                } else {
                    draggingItem.imageComponentsProvider = nil
                }
                
                draggingInfo.numberOfValidItemsForDrop = validCount
                draggingInfo.draggingFormation = .list
            })
        }
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableViewDropOperation) -> Bool {
        self.performInsertWithDragInfo(info, row: row)
        return true
    }
    
    func performInsertWithDragInfo(_ info: NSDraggingInfo, row: Int) {
        info.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.init(rawValue: 0), for: tableview, classes: [NSURL.self], searchOptions: self.pasteboardReadingOptions(), using: { (draggingItem: NSDraggingItem, idx: Int, stop:UnsafeMutablePointer<ObjCBool>) in
            
            let fileURL = draggingItem.item as! URL
            let fileName: String! = fileURL.lastPathComponent
            let toURL: URL!
            
            if #available(OSX 10.11, *) {
                toURL = URL(fileURLWithPath: fileName, relativeTo: self.curFsItem.fileURL)
            } else {
                // Fallback on earlier versions
                let escapedFileName = fileName.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                toURL = URL(string: escapedFileName!, relativeTo: self.curFsItem.fileURL)
            }
            
            do {
                try self.fileManager.moveItem(at: fileURL, to: toURL)
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        })
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        
    }
    
    override func restoreState(with coder: NSCoder) {
        
    }
    
}
