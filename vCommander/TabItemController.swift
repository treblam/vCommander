//
//  TabItemController.swift
//  vCommander
//
//  Created by Jamie on 15/6/2.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

import Quartz

import HanziPinyin

class TabItemController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, DirectoryMonitorDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, NSMenuDelegate, SCTableViewDelegate, NSTextFieldDelegate, NSTouchBarDelegate {

    @IBOutlet weak var tableview: SCTableView!
    @IBOutlet weak var scrollview: NSScrollView!
    @IBOutlet weak var pathControlEffectView: NSVisualEffectView!
    @IBOutlet weak var pathControlView: NSPathControl!
    
    var windowController: MainWindowController? {
        get {
            return self.view.window?.windowController as? MainWindowController
        }
    }
    
    var isPrimary: Bool? {
        get {
            if let leftPanelView = windowController?.leftPanel.view {
                return self.view.isDescendant(of: leftPanelView)
            }
            
            return nil
        }
    }
    
    var panel: CommanderPanel? {
        get {
            if isPrimary != nil {
                return isPrimary! ? windowController?.leftPanel : windowController?.rightPanel
            }
            
            return nil
        }
    }
    
    var curFsItem: FileSystemItem!
    
    let fileManager = FileManager()
    
    let dateFormatter = DateFormatter()
    
    let workspace = NSWorkspace.shared
    
    let preferenceManager = PreferenceManager()
    
    var directoryMonitor: DirectoryMonitor!
    
    var lastChildDir: URL?
    var lastChildDirIndex: Int?
    
    var isQLMode = false
    
    // Variables for type select
    var typeSelectTextField: NSTextField?
    var typeSelectIndices: [Int]?
    var isTypeSelectMode: Bool {
        if let field = typeSelectTextField {
            return !field.isHidden
        } else {
            return false
        }
    }
    
    var lastRenamedFileURL: URL?
    
    var lastRenamedFileIndex: Int?
    
    let pasteboard = NSPasteboard.general
    
    var selectedItems = [URL]()
    var selectedIndexes: IndexSet?
    var markedItems = [URL]()
    var needToRestoreSelected = false
    
    var isVimMode: Bool {
        return preferenceManager.mode == 1
    }
    
    var initUrl: URL?
    
    var scrollViewTopInset: CGFloat = 0
    
    let TABLEVIEW_HEADER_HEIGHT: CGFloat = 23
    let TABBAR_HEIGHT: CGFloat = 25
    let PATHCONTROL_HEIGHT: CGFloat = 19
    
    var inputString = ""
    
    var isActive: Bool {
        if let activePanelView = windowController?.activePanel.view {
            return self.view.isDescendant(of: activePanelView)
        }
        
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
//        tableview.target = self
        let NSFilenamesPboardTypeTemp = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        tableview.registerForDraggedTypes([NSFilenamesPboardTypeTemp])
        //tableview.selectionHighlightStyle = NSTableViewSelectionHighlightStyle.None
        tableview.setDraggingSourceOperationMask(NSDragOperation.every, forLocal: false)
        
        pathControlView.target = self
        pathControlView.doubleAction = #selector(TabItemController.onPathControlClicked)
        pathControlView.action = #selector(TabItemController.onPathControlClicked)
        goToDirectory(withUrl: initUrl!)
        
        print("viewDidLoad called \(String(describing: self.title))")
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) {
            self.handleKeyDown(with: $0)
        }
    }
    
    override func viewWillAppear() {
        print("viewWillAppear called \(String(describing: self.title))")
        observeFocusChange()
    }
    
    override func viewWillLayout() {
        print("viewWillLayout called.")
        scrollview.automaticallyAdjustsContentInsets = false
        if let window = view.window {
            let contentLayoutRect = window.contentLayoutRect
            scrollViewTopInset = NSHeight(window.frame) - NSMaxY(contentLayoutRect) + TABBAR_HEIGHT + PATHCONTROL_HEIGHT
            scrollview.contentInsets = NSEdgeInsets(top: scrollViewTopInset, left: 0, bottom: 0, right: 0)
            
            print("NSHeight(window.frame): \(NSHeight(window.frame))")
            print("NSMaxY(contentLayoutRect): \(NSMaxY(contentLayoutRect))")
            print("scrollViewTopInset: \(scrollViewTopInset)")
            
            let topConstraint = NSLayoutConstraint(item: pathControlEffectView, attribute: .top, relatedBy: .equal, toItem: window.contentLayoutGuide, attribute: .top, multiplier: 1.0, constant: TABBAR_HEIGHT)
            topConstraint.isActive = true
            
            updatePathControlBackground()
        }
    }
    
    override func viewDidLayout() {
        print("viewDidLayout called.")
        tableview.scrollRowToVisible(tableview.selectedRow)
    }
    
    override func viewWillDisappear() {
        stopObserveForFocusChange()
        print("viewWillDisappear called.")
    }
    
    @objc func onPathControlClicked() {
        print("onPathControlClicked called.")
        if !isActive {
            switchFocus()
        }
        
        if let clickedPathItem = pathControlView.clickedPathItem {
            let pathItems = pathControlView.pathItems
            if let index = pathItems.index(where: {
                $0.url == clickedPathItem.url
            }) {
//            if let index = pathItems.index(of: clickedPathItem) {
                if index == pathItems.count - 1 {
                    return
                }
                
                let childURL = pathItems[index + 1].url
                if let url = clickedPathItem.url {
                    goToDirectory(withUrl: url, andNoReload: false, fromChild: childURL)
                }
            }
        }
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
        openFileOrDirectory(byMouseClick: true)
    }
    
    @IBAction func openFile(_ sender:AnyObject) {
        openFileOrDirectory()
    }
    
    @IBAction func onRowClicked(_ sender:AnyObject) {
        print("row was clicked, \(tableview.clickedRow)")
        getFocus()
        
        if typeSelectIndices != nil && typeSelectIndices!.count > 0 {
            clearTypeSelect()
            
            if tableview.clickedRow >= 0 {
                selectRow(tableview.clickedRow)
            }
        }
    }
    
    func getFocus() {
        if !isActive {
            switchFocus()
        }
    }
    
    func openFileOrDirectory(byMouseClick isMouseClick: Bool = false) {
        let item = getSelectedItem()
        if isMouseClick && tableview.clickedRow == -1 {
            return
        }
        if item != nil {
            openFileOrDirectory(withItem: item!)
        }
    }
    
    func openFileOrDirectory(withItem item: FileSystemItem) {
        print("fileURL: " + item.fileURL.path)
        
        // If it's not readable, give an alert and return
        if !item.isReadable {
            let errorAlert = NSAlert()
            if item.localizedName != "" {
                errorAlert.messageText = "不能打开文件\(item.isDirectory ? "夹" : "")“\(item.localizedName ?? "")”，因为您没有权限查看其内容。"
            } else {
                errorAlert.messageText = "不能打开该文件\(item.isDirectory ? "夹" : "")，因为您没有权限查看其内容。"
            }
            
            errorAlert.addButton(withTitle: "确定")
            errorAlert.runModal()
            return
        }
        
        if item.isDirectory {
            goToDirectory(withUrl: item.fileURL as URL)
        } else if item.isSymbolicLink {
            openFileOrDirectory(withItem: item.destinationItem!)
        } else {
            print("It's not directory, can't step into")
            let defaultApp = workspace.urlForApplication(toOpen: item.fileURL)
            if defaultApp == nil {
                let alert = NSAlert()
                alert.messageText = "未设定用来打开文稿“\(item.localizedName)”的应用程序"
                alert.informativeText = "请选取应用程序"
                alert.addButton(withTitle: "选取应用程序")
                alert.addButton(withTitle: "取消")
                alert.alertStyle = .warning
                alert.window.initialFirstResponder = alert.buttons[0]
                
                alert.beginSheetModal(for: self.view.window!, completionHandler: { responseCode in
                    switch responseCode {
                    case NSApplication.ModalResponse.alertFirstButtonReturn:
                        self.view.window?.endSheet(alert.window)
                        self.openWith(nil)
                    default:
                        break
                    }
                })
                return
            }
            workspace.openFile(item.fileURL.path)
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
                                    case NSUserInterfaceItemIdentifier(rawValue: "localizedName"):
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
    
    func updateSelectedRowsApperance() {
        print("Start to updateSelectedRowsApperance")
        tableview.enumerateAvailableRowViews { rowView, rowIndex in
            for column in 0 ..< rowView.numberOfColumns {
                let cellView: AnyObject? = rowView.view(atColumn: column) as AnyObject?
                
                if let tableCellView = cellView as? NSTableCellView {
                    let textField = tableCellView.textField
                    if let _ = rowView as? SCTableRowView {
                        if let text = textField {
                            let isSelected = self.tableview.isRowSelected(rowIndex)
                            print("rowIndex: \(rowIndex)")
                            print("isSelected: \(isSelected)")
                            
                            if let str = tableCellView.identifier {
                                switch str {
                                case NSUserInterfaceItemIdentifier(rawValue: "localizedName"):
//                                    text.textColor = NSColor.controlTextColor
                                    let fontSize = text.font?.pointSize
                                    text.textColor = NSColor.black
                                    text.font = NSFont.systemFont(ofSize: fontSize!)
                                    print("start to change text color for row \(rowIndex)")
                                default:
                                    let fontSize = text.font?.pointSize
                                    text.textColor = NSColor.darkGray
                                    text.font = NSFont.systemFont(ofSize: fontSize!)
                                }
                            }
                            
//                            if isSelected {
//                                text.textColor = NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1)
//                            } else {
//                                if let str = tableCellView.identifier {
//                                    switch str {
//                                    case "localizedName":
//                                        text.textColor = NSColor.controlTextColor
//                                    default:
//                                        text.textColor = NSColor.disabledControlTextColor
//                                    }
//                                }
//                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let colIdentifier: String = tableColumn!.identifier.rawValue
        
        let tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: colIdentifier), owner: self) as! NSTableCellView
        
        let item = self.curFsItem.children[row]
        
        // Customize appearance for marked rows
        let isMarked = self.tableview.isRowMarked(row)
        
        if let textField = tableCellView.textField {
            if isMarked {
                textField.textColor = NSColor(calibratedRed: 26.0/255.0, green: 154.0/255.0, blue: 252.0/255.0, alpha: 1)
            } else {
                if let identifier = tableCellView.identifier {
                    switch identifier {
                    case NSUserInterfaceItemIdentifier(rawValue: "localizedName"):
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
        
        var tableRowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? SCTableRowView
        
        if tableRowView == nil {
            tableRowView = SCTableRowView(frame: NSMakeRect(0, 0, tableview.frame.size.width, 80))
            tableRowView?.identifier = NSUserInterfaceItemIdentifier(rawValue: cellId)
        }
        
//        tableRowView?.marked = tableView.isRowSelected(row)
        
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
        sortData()
        tableview.reloadData()
        
        print("Start to reselect items")
        reselectIfNecessary()
        tableview.markRowIndexes(getIndexesForItems(markedItems) as IndexSet, byExtendingSelection: false)
    }
    
    func sortData() {
        let sortDescriptors = tableview.sortDescriptors
        let objectsArray = curFsItem.children as NSArray
        let sortedObjects = objectsArray.sortedArray(using: sortDescriptors)
        
        curFsItem.children = sortedObjects as! [FileSystemItem]
    }
    
    func getIndexesForItems(_ items: [URL]) -> NSMutableIndexSet {
        let result = NSMutableIndexSet()
        let index = curFsItem?.children?.index {
            items.contains(($0.fileURL as NSURL).fileReferenceURL()!)
        }
        
        if let i = index {
            result.add(i)
        }
        return result
    }
    
    func rememberMarkedItems() {
        markedItems.removeAll()
        
        tableview.markedRows.enumerate({(index: Int, stop: UnsafeMutablePointer<ObjCBool>) in
            // todo: To be optimized for file deletion or move
            if index < 0 || index >= self.curFsItem.children.count {
                return
            }
            let fileRefURL = (self.curFsItem.children[index].fileURL as NSURL).fileReferenceURL()
            print("add \(String(describing: fileRefURL)) to markedItems")
            self.markedItems.append(fileRefURL!)
        })
    }
    
    func updateSelectedItems(withIndexes indexes: IndexSet) {
        print("Start to remember selected items")
        selectedIndexes = indexes
        selectedItems.removeAll()
        
        indexes.forEach {
            if $0 < 0 || $0 >= self.curFsItem.children.count {
                return
            }
            
            let fileRefURL = (self.curFsItem.children[$0].fileURL as NSURL).fileReferenceURL()
            if fileRefURL != nil {
                print("add file to selectedItems: \(fileRefURL!)")
                self.selectedItems.append(fileRefURL!)
            }
        }
    }
    
    func updateSelectedItems(withUrl url: URL) {
        selectedIndexes = getIndexesForItems([url]) as IndexSet
        selectedItems.removeAll()
        let fileRefURL = (url as NSURL).fileReferenceURL()
        
        if fileRefURL != nil {
            selectedItems.append(fileRefURL!)
        }
    }
    
    func tableViewMarkedViewsDidChange() {
        print("tableViewMarkedViewsDidChange() called, start to rememberMarkedItems()")
        rememberMarkedItems()
        updateMarkedRowsApperance()
    }
    
    func clearSelectedItems() {
        selectedItems.removeAll()
        selectedIndexes = nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDigChange called. index: \(String(describing: tableview.selectedRowIndexes.first))")
        updateSelectedItems(withIndexes: tableview.selectedRowIndexes)
        
//        updateSelectedRowsApperance()
        
        if isQLMode {
            QLPreviewPanel.shared().reloadData()
        }
    }

    func cleanTableViewData(_ isFromChild: Bool) {
        tableview.cleanData()
        clearTypeSelect()
        if !isFromChild {
            clearSelectedItems()
        }
    }
    
    func goToDirectory(withUrl url: URL, andNoReload noReload: Bool = false, fromChild childURL: URL? = nil) {
        if !fileManager.fileExists(atPath: url.relativePath) {
            backToParentDirectory()
            return
        }

        // The fileManager's current directory is used when rename a file
        let suc = fileManager.changeCurrentDirectoryPath(url.path)
        if (!suc) {
            print("change directory fail")
        }

        print(fileManager.currentDirectoryPath)
        
        if initUrl != nil {
            initUrl = nil
        } else {
            curFsItem = FileSystemItem(fileURL: url)
        }
        
        pathControlView.url = url
        
        var isFromChild = false
        if let child = childURL {
            updateSelectedItems(withUrl: child)
            isFromChild = true
        }
        
        // Clean the data for last directory
        if (tableview !== nil) {
            print("clean data")
            cleanTableViewData(isFromChild)
        }
        
        // Notify the panel the directory was changed.
        // sendNotification()
        
        // Change tab name
        self.title = curFsItem.localizedName
        if let tabview = (self.view.superview as? NSTabView) {
            let tabItem = tabview.selectedTabViewItem
            let model = tabItem?.identifier as? TabBarModel
            model?.title = self.title!
            tabItem?.identifier = model
        }
        
        startMonitoring(directory: url)
        
        if !noReload {
            tableview.reloadData()
        }
        reselectIfNecessary()
    }
    
    func startMonitoring(directory url: URL) {
        // Start to monitor directory for changes
        if directoryMonitor != nil {
            directoryMonitor.stopMonitoring()
            directoryMonitor.delegate = nil
            directoryMonitor = nil
        }
        
        directoryMonitor = DirectoryMonitor(URL: url)
        directoryMonitor.delegate = self
        directoryMonitor.startMonitoring()
        print("start monitor \(curFsItem.fileURL.path)")
    }
    
    func sendNotification() {
        let notificationKey = "DirectoryChanged"
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: notificationKey), object: self)
    }
    
    func observeFocusChange() {
        let notificationKey = "FocusChanged"
        print("Start to observe for focus change notification")
        NotificationCenter.default.addObserver(self, selector: #selector(TabItemController.updatePathControlBackground), name: NSNotification.Name(rawValue: notificationKey), object: nil)
    }
    
    func stopObserveForFocusChange() {
        let notificationKey = "FocusChanged"
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: notificationKey), object: nil)
    }
    
    @objc func updatePathControlBackground() {
        print("Got focus change notification")
        if isActive {
            print("start to change pathControl background color to light blue \(String(describing: self.title))")
            pathControlView.backgroundColor = NSColor(calibratedRed: 229.0/255.0, green: 236.0/255.0, blue: 248.0/255.0, alpha: 1.0)
            // NSColor(calibratedRed: 254.0/255.0, green: 205.0/255.0, blue: 82.0/255.0, alpha: 1.0)
        } else {
            pathControlView.backgroundColor = NSColor.white
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        print("mouseDown in TabItemController called.")
    }
    
    func convertToInt(_ str: String) -> Int {
        let s1 = str.unicodeScalars
        let s2 = s1[s1.startIndex].value
        return Int(s2)
    }
    
    func backToParentDirectory() {
        var parentUrl: URL
        // At the root directory already
        if curFsItem.fileURL.relativePath == "/" {
            parentUrl = URL(fileURLWithPath: "/Volumes")
        } else if curFsItem.fileURL.relativePath == "/Volumes" {
            return
        } else {
            parentUrl = curFsItem.fileURL.deletingLastPathComponent()
            while !fileManager.fileExists(atPath: parentUrl.relativePath) {
                parentUrl = parentUrl.deletingLastPathComponent()
            }
        }
        
        // Remember last directory, this dir should be selected when backed to parent dir
        // updateSelectedItems(withUrl: curFsItem.fileURL as URL)
        print("start goToParent withUrl: \(parentUrl)")
        goToDirectory(withUrl: parentUrl, andNoReload: false, fromChild: curFsItem.fileURL as URL)
    }
    
    override func keyDown(with theEvent: NSEvent) {
        print("TabItemController keydown called.")
        print("keyCode: " + String(theEvent.keyCode))
        
        let flags = theEvent.modifierFlags
        let s = theEvent.characters!
        let char = convertToInt(s)
        print("s: \"\(s)\"")
        print("char:" + String(char))
        
        let hasCommand = flags.contains(NSEvent.ModifierFlags.command)
        let hasShift = flags.contains(NSEvent.ModifierFlags.shift)
        let hasOption = flags.contains(NSEvent.ModifierFlags.option)
        let hasControl = flags.contains(NSEvent.ModifierFlags.control)
        print("hasCommand: " + String(hasCommand))
        print("hasShift: " + String(hasShift))
        print("hasAlt: " + String(hasOption))
        print("hasControl: " + String(hasControl))
        print("isVimMode: \(isVimMode)")
        
        let noneModifiers = !hasCommand && !hasShift && !hasOption && !hasControl
        print("noneModifiers: " + String(noneModifiers))
        
        let isInputText = !hasCommand && !hasOption && !hasControl
        
        let KEYCODE_BACKSPACE = 127
        let KEYCODE_ENTER = 13
        let KEYCODE_TAB = 9
        let KEYCODE_ESCAPE = 27
        
        print("convertToInt(\"h\"): \(convertToInt("h"))")
        print("convertToInt(\"j\"): \(convertToInt("j"))")
        print("convertToInt(\"\"): \(convertToInt(" "))")
        
        if hasControl {
            if let chars = theEvent.charactersIgnoringModifiers {
                print("chars: \(chars)")
                switch chars  {
                case "l" where isVimMode, "h" where isVimMode:
                    switchFocus()
                    return
                default:
                    break
                }
            }
        }
        
        switch char {
        case KEYCODE_ESCAPE:
            handleEscape()
            return
            
        case KEYCODE_BACKSPACE where noneModifiers,
            convertToInt("h") where noneModifiers && isVimMode && !isTypeSelectMode,
            NSLeftArrowFunctionKey where noneModifiers:
            // delete or h or left arrow
            // h was used to emulate vim hotkeys
            // 127 is backspace key
            
            if char == KEYCODE_BACKSPACE && noneModifiers {
                if let field = typeSelectTextField {
                    if !field.isHidden {
                        let stringValue = field.stringValue
                        let len = stringValue.count
                        
                        if len > 0 {
                            let index = stringValue.index(stringValue.endIndex, offsetBy: -1)
                            let filterString = "\(stringValue[..<index])"
                            field.stringValue = filterString
                            updateTypeSelectMatches(byString: filterString)
                        }
                        
                        return
                    }
                }
            }
            
            backToParentDirectory()
            return
            
        case KEYCODE_ENTER where noneModifiers,
            convertToInt("l") where noneModifiers && isVimMode && !isTypeSelectMode,
            NSRightArrowFunctionKey where noneModifiers:
            // enter or l or right arrow
            // l is used to emulate vim hotkeys
            openFileOrDirectory()
            return
            
        case convertToInt("h") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            clearTypeSelect()
            backToParentDirectory()
            return
        
        case convertToInt("j") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            clearTypeSelect()
            selectNextRow()
            return
            
        case convertToInt("k") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            clearTypeSelect()
            selectPrevRow()
            return
            
        case convertToInt("l") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            clearTypeSelect()
            openFileOrDirectory()
            return
        
        case convertToInt("p") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            findPrevious()
            return
            
        case convertToInt("n") where isVimMode && hasCommand && !hasOption && !hasShift && !hasControl:
            findNext()
            return
            
        case NSF5FunctionKey where noneModifiers:
            copySelectedFiles(nil)
            return
            
        case NSF6FunctionKey where noneModifiers:
            moveSelectedFiles(nil)
            return
            
        case NSF7FunctionKey where noneModifiers:
            // create new directory
            return;
            
        case NSF7FunctionKey where hasShift && !hasCommand && !hasOption && !hasControl:
            newDocument(nil)
            return
            
        case NSF8FunctionKey where noneModifiers:
            deleteSelectedFiles(nil)
            return
            
        case convertToInt("H") where isVimMode && !isTypeSelectMode:
            print("Start to call selectFirstVisibleRow")
            selectFirstVisibleRow()
            return
            
        case convertToInt("L") where isVimMode && !isTypeSelectMode:
            print("Start to call selectFirstVisibleRow")
            selectLastVisibleRow()
            return
            
        case convertToInt("M") where isVimMode && !isTypeSelectMode:
            print("Start to call selectMiddleVisibleRow")
            selectMiddleVisibleRow()
            return
            
        case KEYCODE_TAB where (noneModifiers || hasShift && !hasCommand && !hasOption && !hasControl):
            switchFocus()
            return
            
        default:
            break
        }
        
        if let insertString = theEvent.characters {
            if isInputText && !insertString.isEmpty {
                if isVimMode {
                    if isTypeSelectMode {
                        if handleInsertText(insertString) {
                            return
                        }
                    } else {
                        detectVimCommands(insertString)
                        return
                    }
                } else if handleInsertText(insertString) {
                    return
                }
//                if handleInsertText(insertString) {
//                    print("handleInsertText return true, just return")
//                    return
//                } else if isVimMode && !isTypeSelectMode {
//                    customInsertText(insertString)
//                }
                
                // 非搜索模式下一律不发声
                if !isTypeSelectMode {
                    return
                }
            }
        }
        
        interpretKeyEvents([theEvent])
        super.keyDown(with: theEvent)
    }
    
    func handleKeyDown(with theEvent: NSEvent) -> NSEvent? {
        if !isActive {
            return theEvent
        }
        
        print("TabItemController handleKeydown")
        
        print("keyCode: " + String(theEvent.keyCode))
        let flags = theEvent.modifierFlags
        let hasShift = flags.contains(NSEvent.ModifierFlags.shift)
        let hasControl = flags.contains(NSEvent.ModifierFlags.control)
        let hasOption = flags.contains(NSEvent.ModifierFlags.option)
        let hasCommand = flags.contains(NSEvent.ModifierFlags.command)
        let noneModifiers = !hasShift && !hasCommand && !hasOption && !hasControl
        print("hasShift: " + String(hasShift))
        print("hasControl: " + String(hasControl))
        
        let KEYCODE_DOWN: UInt16 = 125
        let KEYCODE_UP: UInt16 = 126
        
        switch theEvent.keyCode {
        case KEYCODE_DOWN where noneModifiers && tableview.selectedRowIndexes.first == curFsItem.children.count - 1:
            findNext()
            return nil

        case KEYCODE_UP where noneModifiers && tableview.selectedRowIndexes.first == 0:
            findPrevious()
            return nil

        default:
            print("return the event")
            return theEvent
        }
    }
    
    // todo
    override func flagsChanged(with event: NSEvent) {
        if event.modifierFlags.contains(NSEvent.ModifierFlags.shift) {
            print("shift pressed")
        }
    }
    
    func exec(command: String, withRepetition repetition: Int?) -> Bool {
        switch command {
        case "dd":
            deleteFiles(withCount: repetition)
            return true
        case "d":
            let hasMarkedFiles = getMarkedItems(false).count > 0
            if hasMarkedFiles {
                deleteMarkedFiles()
                return true
            }
            return false
        case "j":
            selectNextRow(withCount: repetition)
            return true
        case "k":
            selectPrevRow(withCount: repetition)
            return true
        case "gg":
            selectRow(withNum: repetition, isDefaultTop: true)
            return true
        case "G":
            selectRow(withNum: repetition, isDefaultTop: false)
            return true
        case "yy":
            copyToClipboard(withCount: repetition)
            return true
        case "y":
            let hasMarkedFiles = getMarkedItems(false).count > 0
            if hasMarkedFiles {
                copyMarkedItemsToClipboard()
                return true
            }
            return false
        case "S", "cc":
            renameRow()
            return true
        case "i", "a", "A":
            renameRow(withCursorPosition: "right")
            return true
        case "I":
            renameRow(withCursorPosition: "left")
            return true
        case "gt":
            panel?.nextTabWithCount(repetition)
            return true
        case "gT":
            panel?.previousTabWithCount(repetition)
            return true
        case "f", "F", "/":
            startTypeSelectMode()
            return true
        default:
            break
        }
        
        return false
    }
    
    func matches(for regex: String, in text: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let nsString = text as NSString
            let results = regex.matches(in: text, range: NSRange(location: 0, length: nsString.length))
            return results.map { [nsString.substring(with: $0.range), nsString.substring(with: $0.range(at: 1)), nsString.substring(with: $0.range(at: 2))] }
        } catch let error {
            print("invalid regex: \(error.localizedDescription)")
            return [[]]
        }
    }
    
    func selectNextRow(withCount count: Int? = 1) {
        let curIndex = tableview.selectedRowIndexes.first
        if curIndex == nil {
            return
        }
        let countInner = count == nil || count == 0 ? 1 : count!
        let targetIndex = min(numberOfRows(in: tableview) - 1, curIndex! + countInner)
        selectRow(targetIndex)
    }
    
    func selectPrevRow(withCount count: Int? = 1) {
        let curIndex = tableview.selectedRowIndexes.first
        if curIndex == nil {
            return
        }
        let countInner = count == nil || count == 0 ? 1 : count!
        let targetIndex = max(0, curIndex! - countInner)
        selectRow(targetIndex)
    }
    
    func selectFirstRow() {
        selectRow(0)
    }
    
    func selectLastRow() {
        let lastRowIndex = numberOfRows(in: tableview) - 1
        selectRow(lastRowIndex)
    }
    
    func selectRow(withNum num: Int?, isDefaultTop: Bool) {
        if let numInner = num {
            selectRow(numInner)
        } else {
            if isDefaultTop {
                selectFirstRow()
            } else {
                selectLastRow()
            }
        }
    }
    
    func selectRow(_ rowIndex: Int?, isScroll: Bool = true) {
        if let row = rowIndex {
            let indexSet = IndexSet(integer: row)
            tableview.selectRowIndexes(indexSet, byExtendingSelection: false)
            
            print("Select row \(row)")
            if isScroll {
                print("Slect row to visible \(row)")
                tableview.scrollRowToVisible(row)
            }
        }
    }
    
    func visibleRows() -> NSIndexSet {
        let rect = tableview.visibleRect
        let contentHeight = (tableview.enclosingScrollView?.contentSize.height)! - scrollViewTopInset - TABLEVIEW_HEADER_HEIGHT
        print("contentHeight: \(contentHeight)")
        print("rect.origin.x: \(rect.origin.x), rect.origin.y: \(rect.origin.y)")
        
        let realVisibleRect = NSMakeRect(rect.origin.x, rect.origin.y + rect.height - contentHeight, rect.width, contentHeight)
        let range = tableview.rows(in: realVisibleRect)
        print("location in range: \(range.location)")
        print("length in range: \(range.length)")
        return NSIndexSet(indexesIn: range)
    }
    
    func selectFirstVisibleRow() {
        let indexes = visibleRows()
        selectRow(indexes.firstIndex, isScroll: false)
    }
    
    func selectLastVisibleRow() {
        let indexes = visibleRows()
        selectRow(indexes.lastIndex, isScroll: false)
    }
    
    func selectMiddleVisibleRow() {
        let indexes = visibleRows()
        let middleRow = indexes.firstIndex + indexes.count/2
        selectRow(middleRow, isScroll: false)
    }
    
    func reselectIfNecessary() {
        let indexesForUrls = getIndexesForItems(selectedItems)
        var toBeSelectedIndex: Int?
        if indexesForUrls.count > 0 {
            toBeSelectedIndex = indexesForUrls.firstIndex
        } else {
            toBeSelectedIndex = selectedIndexes?.first ?? 0
        }
        
        let count = curFsItem.children.count
        if count > 0 {
            if toBeSelectedIndex != nil {
                if toBeSelectedIndex! < 0 {
                    toBeSelectedIndex = 0
                } else if toBeSelectedIndex! >= count {
                    toBeSelectedIndex = count - 1
                }
            }
            selectRow(toBeSelectedIndex ?? 0)
        }
        
//        var toBeSelectedRowIndex: Int?
//        if curFsItem.children.count > 0 {
//            if let lastViewedDir = lastChildDir {
//                toBeSelectedRowIndex = curFsItem.children.index(where: {$0.fileURL == lastViewedDir})
//                lastChildDir = nil
//            }
//            
//            if toBeSelectedRowIndex != nil && toBeSelectedRowIndex! >= 0 {
//                selectRow(toBeSelectedRowIndex!)
//            }
//        }
    }
    
    @IBAction func showQuickLookPanel(_ sender: AnyObject?) {
        QLPreviewPanel.shared().makeKeyAndOrderFront(self)
    }
    
    @IBAction func copySelectedFiles(_ sender: AnyObject?) {
        let items = getMarkedItems()
        copyFiles(items)
    }
    
    func copyMarkedFiles() {
        let items = getMarkedItems(false)
        copyFiles(items)
    }
    
    func copyFiles(_ items: [FileSystemItem]) {
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
    
    func copyFiles(withCount count: Int?) {
        let items = getItems(withCount: count)
        copyFiles(items)
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
        deleteFiles(items)
    }
    
    func deleteMarkedFiles() {
        let items = getMarkedItems(false)
        deleteFiles(items)
    }
    
    func getItems(withCount count: Int?) -> [FileSystemItem] {
        // 0 count doesn't make sense
        let countInner = (count == nil || count == 0) ? 1 : count!
        
        let startIndex = Int(tableview.selectedRowIndexes.first!)
        let endIndex = min(startIndex + countInner - 1, numberOfRows(in: tableview) - 1)
        return Array(curFsItem.children[startIndex...endIndex])
    }
    
    func deleteFiles(withCount count: Int?) {
        let items = getItems(withCount: count)
        print("items.count: \(items.count)")
        deleteFiles(items)
    }
    
    func deleteFiles(_ items: [FileSystemItem]) {
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
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                self.workspace.recycle(fileUrls, completionHandler: {(newUrls, error) in
                    if error != nil {
                        let errorAlert = NSAlert()
                        print("error")
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
//    override func insertTab(_ sender: Any?) {
//        print("Tab pressed")
//        switchFocus()
//    }
    
    // shift + tab键按下
//    override func insertBacktab(_ sender: Any?) {
//        print("Back tab pressed")
//        switchFocus()
//    }
    
    func switchFocus() {
        let windowController = self.view.window!.windowController as! MainWindowController
        clearTypeSelect()
        windowController.switchFocus()
    }
    
    func handleInsertText(_ insertString: Any) -> Bool {
        print(insertString)
        
        var stringValue: String
        
        // Vim 模式下输入非斜杠，直接返回
//        if isVimMode && insertString as! String != "/" && !isTypeSelectMode {
//            return false
//        }
        
        startTypeSelectMode()
        
        stringValue = typeSelectTextField!.stringValue + (insertString as! String)
        
//        if insertString as! String == "/" {
//            return true
//        }
        
        updateTypeSelectMatches(byString: stringValue)
        
        // If find at least one match
        if typeSelectIndices!.count > 0 {
            typeSelectTextField!.stringValue = stringValue
            selectRow(typeSelectIndices![0])
            return true
        }
        
        return false
    }
    
    func detectVimCommands(_ insertString: Any) {
        print("insertString: \(insertString)")
        
        if let char = insertString as? String {
            inputString += char
            print("inputString: \(inputString)")
            
            let textMatches = matches(for: "(\\d*)(dd|d|gg|G|yy|y|h|j|k|l|v|V|cc|S|i|I|a|A|gt|gT|\\/|f|F)$", in: inputString)
            if textMatches.count > 0 {
                let match = textMatches[textMatches.count - 1]
                
                print("match[0]: \(match[0])")
                print("match[1]: \(match[1])")
                print("match[2]: \(match[2])")
                
                let handled = exec(command: match[2], withRepetition: Int(match[1]))
                if handled {
                    inputString = ""
                }
            }
        }
    }
    
    func updateTypeSelectMatches(byString string: String) {
        typeSelectIndices = curFsItem.children.enumerated().filter {
            let outputFormat = PinyinOutputFormat(toneType: .none, vCharType: .vCharacter, caseType: .lowercased)
            let pinyin = $0.element.localizedName.toPinyin(withFormat: outputFormat, separator: "").trimmingCharacters(in: .whitespaces)
            print("HanziPinyin: \(pinyin)")
            return pinyin.range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil
            //            return $0.element.localizedName.transformToPinYin().range(of: string, options: .caseInsensitive, range: nil, locale: nil) != nil
        }.map {
            $0.offset
        }
    }

    func clearTypeSelect() {
        print("Start to clear type select")
        typeSelectTextField?.stringValue = ""
        typeSelectTextField?.isHidden = true
        typeSelectIndices = nil
    }
    
    func startTypeSelectMode() {
        
        if isTypeSelectMode {
            return
        }
        
        print("start type select mode")
        
        // Clear vim inputs
        inputString = ""
        
        // If the textfield already exists
        if let field = typeSelectTextField {
            if field.isHidden {
                field.isHidden = false
            }
            
        } else {
            // Create a new NSTextField
            typeSelectTextField = NSTextField()
            
            typeSelectTextField!.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(typeSelectTextField!)
            typeSelectTextField?.isEditable = false
            typeSelectTextField?.drawsBackground = false
            
            let trailingConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: -20)
            let bottomConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: -20)
            let widthConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150)
            let heightConstraint = NSLayoutConstraint(item: typeSelectTextField!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
            self.view.addConstraints([widthConstraint, heightConstraint, trailingConstraint, bottomConstraint])
            //            self.view.window!.makeFirstResponder(typeSelectTextField!)
        }
    }
    
    func handleEscape() {
        if typeSelectTextField != nil && !typeSelectTextField!.isHidden {
            clearTypeSelect()
        } else {
            tableview.unmarkAll()
        }
    }
        
//    convenience override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: nil, isPrimary: true, withSelected: nil)
//    }
    
    convenience init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, url: URL?, isPrimary: Bool) {
        self.init(nibName: nibNameOrNil, bundle: nibBundleOrNil, url: url, isPrimary: isPrimary, withSelected: nil)
    }
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, url: URL?, isPrimary: Bool, withSelected itemUrl: URL?) {
        super.init(nibName: nibNameOrNil.map { NSNib.Name(rawValue: $0) }, bundle: nibBundleOrNil)
        
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        if itemUrl != nil {
            updateSelectedItems(withUrl: itemUrl!)
        }
        
        initUrl = url ?? URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        curFsItem = FileSystemItem(fileURL: initUrl!)
        self.title = curFsItem.localizedName
//        self.isPrimary = isPrimary
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
//        curFsItem.children = nil
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
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                let dirName = textField.stringValue
                let dirUrl = self.curFsItem.fileURL.appendingPathComponent(dirName)
                
                let theError: NSErrorPointer? = nil
                do {
                    try self.fileManager.createDirectory(at: dirUrl, withIntermediateDirectories: false, attributes: nil)
                    print("Start to updateSelectedItems")
                    self.updateSelectedItems(withUrl: dirUrl)
                } catch let error as NSError {
                    theError??.pointee = error
                    print("create directory error: \(String(describing: error))")
                    if error.code == NSFileWriteFileExistsError {
                        print("File exists")
                        let alert = NSAlert()
                        alert.messageText = "新建文件夹失败"
                        alert.informativeText = "已存在同名文件夹"
                        alert.beginSheetModal(for: self.view.window!, completionHandler: {responseCode in
                        })
                    }
                    // handle the error
                } catch {
                    fatalError()
                }
            default:
                break
            }
        })
    }
    
    @IBAction func newDocument(_ sender: NSMenuItem?) {
        let alert = NSAlert()
        alert.addButton(withTitle: "确定")
        alert.addButton(withTitle: "取消")
        alert.messageText = "新建文件"
        alert.informativeText = "请输入文件名"
        
        let textField = NSTextField(frame: NSMakeRect(0, 0, 200, 24))
        textField.placeholderString = "文件名"
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField
        
        alert.beginSheetModal(for: self.view.window!, completionHandler: { responseCode in
            switch responseCode {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                let fileName = textField.stringValue
                let fileUrl = self.curFsItem.fileURL.appendingPathComponent(fileName)
                
                if self.fileManager.fileExists(atPath: fileUrl.path) {
                    let alert = NSAlert()
                    alert.messageText = "新建文件失败"
                    alert.informativeText = "已存在同名文件"
                    alert.beginSheetModal(for: self.view.window!, completionHandler: {responseCode in
                    })
                    return
                }
                
                if self.fileManager.createFile(atPath: fileUrl.path, contents: nil, attributes: nil) {
                    print("Start to updateSelectedItems")
                    self.updateSelectedItems(withUrl: fileUrl)
                } else {
                    let alert = NSAlert()
                    alert.messageText = "新建文件失败"
                    alert.informativeText = "无法创建该文件"
                    alert.beginSheetModal(for: self.view.window!, completionHandler: {responseCode in
                    })
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
            if isPrimary != nil {
                if isPrimary! {
                    _ = execcmd(preferenceManager.diffTool! + " \"" + curItems[0].path + "\" \"" + targetItems[0].path + "\"")
                } else {
                    _ = execcmd(preferenceManager.diffTool! + " \"" + targetItems[0].path + "\" \"" + curItems[0].path + "\"")
                }
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
                if result.rawValue == NSFileHandlingPanelOKButton {
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
        renameRow()
    }
    
    func renameRow(withCursorPosition cursorPosition: String = "select") {
        let row = tableview.selectedRow
        let selected = getSelectedItem()
        print("path:" + (selected?.path)!)
        print("row:" + String(row))
        
        let cellview = tableview.view(atColumn: 0, row: row, makeIfNecessary: false) as! NSTableCellView
        cellview.textField?.isEditable = true
        
        tableview.editColumn(0, row: row, with: nil, select: true)
        if cursorPosition == "left" {
            cellview.textField?.currentEditor()?.moveToBeginningOfLine(nil)
        } else if cursorPosition == "right" {
            cellview.textField?.currentEditor()?.moveToEndOfLine(nil)
        }
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
        let items = getMarkedItems()
        copyToClipboard(items)
    }
    
    func copyToClipboard(withCount count: Int?) {
        let items = getItems(withCount: count)
        copyToClipboard(items)
    }
    
    func copyMarkedItemsToClipboard() {
        let items = getMarkedItems(false)
        copyToClipboard(items)
    }
    
    func copyToClipboard(_ items: [FileSystemItem]) {
        let objectsToCopy: Array<URL>
        
        if items.count > 0 {
            pasteboard.clearContents()
            objectsToCopy = items.map {
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
        pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        print("filesToGetInfo: \(filesToGetInfo)")
        
        let NSFilenamesPboardTypeTemp = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        pasteboard.setPropertyList(filesToGetInfo, forType: NSFilenamesPboardTypeTemp)
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
        
        textField?.isEditable = false
        
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
        
        if textField!.tag == 1 {
            do {
                print("start to change name")
                try fileManager.moveItem(atPath: currentName!, toPath: newName!)
                // Remember the path after rename
                print("Rename done.")
                // no need to update selectedItems, cause it's been done
//                let encodedNewName = newName!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
                
//                if let theEncodedNewName = encodedNewName {
//                    updateSelectedItems(withUrl: URL(string: theEncodedNewName, relativeTo: curFsItem.fileURL as URL)!)
//                }
            } catch let error as NSError {
                print("Ooops! Something went wrong: \(error)")
            }
        }
    }
    
    // Make the NSTextField not editable when escape key is pressed
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        print("control textView doCommandBy")
        if commandSelector == #selector(cancelOperation(_:)) {
            if let textField = control as? NSTextField {
                textField.isEditable = false
            }
        }
        return false
    }
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        let items = getMarkedItems()
        return items.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        print("previewPanel previewItemAtIndex method called.")
        let items = getMarkedItems()
        let item = items[index]
        return item.fileURL as QLPreviewItem?
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
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let selectedItem = getSelectedItem()
        
        if selectedItem == nil {
            if menuItem.action == #selector(TabItemController.openFile(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.openWith(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.revealInFinder(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.rename(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.showQuickLookPanel(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.editSelectedFile(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.deleteSelectedFiles(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.copy(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.copyFullPath(_:)) {
                return false
            }
            
            if menuItem.action == #selector(TabItemController.getInfo(_:)) {
                return false
            }
        }
        
        return true
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        let NSFilenamesPboardTypeTemp = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        pboard.declareTypes([NSFilenamesPboardTypeTemp], owner: self)
        pboard.setData(data, forType: NSFilenamesPboardTypeTemp)
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
        
        // should I accept the proposed index
        var isAccept = false
        
        // type select array index
        var myArrIndex: Int?
        
        var myProposedIndex: Int?
        
//        let selectedIndexes = NSMutableIndexSet()
        
        if let indices = typeSelectIndices {
            print("typeSelectIndices is not nil, count: \(indices.count)")
            myArrIndex = indices.index(of: currentIndex ?? -1)
            print("myArrIndex: \(String(describing: myArrIndex))")
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
            
            // if proposedIndex is in my array, just accept it
            if indices.index(of: proposedIndex ?? -1) != nil {
                isAccept = true
            }
        } else if proposedIndex != nil {
            isAccept = true
        }
        
        /*else {
            if let url = lastRenamedFileURL {
                lastRenamedFileIndex = curFsItem.children.index {fileItem in
                    return fileItem.fileURL.path == url.path
                }
                
                if let theIndex = lastRenamedFileIndex {
                    selectedIndexes.add(theIndex)
                    selectedItems.removeAll()
                }
                
                print("lastRenamedFileURL: \(lastRenamedFileURL)")
                print("lastRenamedFileIndex: \(lastRenamedFileIndex)")
                lastRenamedFileURL = nil
            }
            
            print("Start to reselect")
            if selectedIndexes.count > 0 {
                myProposedIndex = selectedIndexes.firstIndex
                if myProposedIndex == proposedIndex {
                    isAccept = true
                }
            } else {
                isAccept = true
            }
        }*/
        
        print("proposedIndex: \(String(describing: proposedIndex))")
        print("currentIndex: \(String(describing: currentIndex))")
        print("myProposedIndex: \(String(describing: myProposedIndex))")
        print("isAccept: \(String(describing: isAccept))")
        
        if isAccept {
            print("Accept proposedIndex, and remember it: \(String(describing: proposedIndex))")
            return proposedSelectionIndexes
        } else {
            if let index = myProposedIndex {
                print("Start to select myProposedIndex: \(index)")
                selectRow(index)
            }
            print("Don't accept, just return the currentIndex: \(String(describing: currentIndex))")
            return IndexSet(integer: currentIndex ?? 0)
        }
    }
    
    func nextMatchIndex(_ moveDown: Bool = true) -> IndexSet.Element? {
        if !isTypeSelectMode {
            return nil
        }

        if let indices = typeSelectIndices {
            if indices.count == 0 {
                return nil
            }
            
            let currentIndex = tableview.selectedRowIndexes.first
            
            var typeSelectIndex = indices.index(of: currentIndex ?? -1)
            
            if moveDown {
                //这是Fundation的bug？ indices.contains(indices[indices.endIndex] 竟然是false，最后一个index是endIndex的前面一个，是不是很奇怪？
                if typeSelectIndex == indices.count - 1 {
                    typeSelectIndex = 0
                } else {
                    typeSelectIndex = typeSelectIndex! + 1
                }
            } else {
                if typeSelectIndex == 0 {
                    typeSelectIndex = indices.count - 1
                } else {
                    typeSelectIndex = typeSelectIndex! - 1
                }
            }
            
            return indices[typeSelectIndex!]
        }
        
        return nil
    }
    
    func findNext() {
        selectRow(nextMatchIndex())
    }
    
    func findPrevious() {
        selectRow(nextMatchIndex(false))
    }

    func pasteboardReadingOptions() -> [NSPasteboard.ReadingOptionKey : Any]? {
        return [
            NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true as AnyObject
        ]
    }
    
    func containsAcceptableURLsFromPasteboard(_ pasteboard: NSPasteboard) -> Bool {
        return pasteboard.canReadObject(forClasses: [NSURL.self], options: self.pasteboardReadingOptions())
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        
        if dropOperation == NSTableView.DropOperation.above {
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
            let tableCellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "localizedName"), owner: self) as! NSTableCellView
            var validCount = 0
            
            draggingInfo.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.init(rawValue: 0), for: tableView, classes: [NSURL.self, NSPasteboardItem.self], searchOptions: self.pasteboardReadingOptions()!, using: { (draggingItem: NSDraggingItem, idx: Int, stop:UnsafeMutablePointer<ObjCBool>) in
                
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
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        self.performInsertWithDragInfo(info, row: row)
        return true
    }
    
    func performInsertWithDragInfo(_ info: NSDraggingInfo, row: Int) {
        info.enumerateDraggingItems(options: NSDraggingItemEnumerationOptions.init(rawValue: 0), for: tableview, classes: [NSURL.self], searchOptions: self.pasteboardReadingOptions()!, using: { (draggingItem: NSDraggingItem, idx: Int, stop:UnsafeMutablePointer<ObjCBool>) in
            
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
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        let mainBar = NSTouchBar()
        mainBar.delegate = self
        mainBar.defaultItemIdentifiers = [.fixedSpaceLarge, .renameFile, .fixedSpaceSmall, .previewFiles, .fixedSpaceSmall, .editFile, .fixedSpaceSmall, .copyFiles, .fixedSpaceSmall, .moveFiles, .fixedSpaceSmall, .createDirectory, .fixedSpaceSmall, .deleteFiles]
        return mainBar
    }
    
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case NSTouchBarItem.Identifier.renameFile:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "重命名", target: self, action: #selector(rename(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.previewFiles:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "预览", target: self, action: #selector(showQuickLookPanel(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.editFile:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "编辑", target: self, action: #selector(editSelectedFile(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.copyFiles:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "复制", target: self, action: #selector(copySelectedFiles(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.moveFiles:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "移动", target: self, action: #selector(moveSelectedFiles(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.createDirectory:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "新建文件夹", target: self, action: #selector(newDirectory(_:)))
            return customViewItem
        case NSTouchBarItem.Identifier.deleteFiles:
            let customViewItem = NSCustomTouchBarItem(identifier: identifier)
            customViewItem.view = NSButton(title: "删除", target: self, action: #selector(deleteSelectedFiles(_:)))
            return customViewItem
//        case NSTouchBarItem.Identifier.groupBar:
//            let groupBar = NSGroupTouchBarItem(identifier: .groupBar, items: [self.touchBar(touchBar, makeItemForIdentifier: .renameFile)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .previewFiles)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .editFile)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .copyFiles)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .moveFiles)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .createDirectory)!,
//                                                                              self.touchBar(touchBar, makeItemForIdentifier: .deleteFiles)!])
//            return groupBar
        default:
            return nil
        }
    }
    
}

@available(OSX 10.12.2, *)
extension NSTouchBarItem.Identifier {
    static let renameFile = NSTouchBarItem.Identifier("renameFile")
    static let previewFiles = NSTouchBarItem.Identifier("previewFiles")
    static let editFile = NSTouchBarItem.Identifier("editFile")
    static let copyFiles = NSTouchBarItem.Identifier("copyFiles")
    static let moveFiles = NSTouchBarItem.Identifier("moveFiles")
    static let createDirectory = NSTouchBarItem.Identifier("createDirectory")
    static let deleteFiles = NSTouchBarItem.Identifier("deleteFiles")
//    static let groupBar = NSTouchBarItem.Identifier("groupBar")
}
