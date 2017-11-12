//
//  CommanderPanel.swift
//  vCommander
//
//  Created by Jamie on 15/6/4.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class CommanderPanel: NSViewController, MMTabBarViewDelegate {

    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tabBar: MMTabBarView!
    
    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    
    var isPrimary: Bool!
    
    let preferenceManager = PreferenceManager()
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, isPrimary: Bool) {
        super.init(nibName: nibNameOrNil.map { NSNib.Name(rawValue: $0) }, bundle: nibBundleOrNil)
        self.isPrimary = isPrimary
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // todo: is this useful?
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        self.nextResponder = self.view
//        for subview in self.view.subviews {
//            subview.nextResponder = self
//        }
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.showAddTabButton = true
        tabBar.onlyShowCloseOnHover = true
        tabBar.automaticallyAnimates = true
        tabBar.useOverflowMenu = false
        tabBar.setStyleNamed("Yosemite")
        
        restoreTabs()
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown) {
            self.handleKeyDown(with: $0)
        }
//        listenForDirChanges()
        
//        let box = self.view as! NSBox
//        box.sizeToFit()
//        box.boxType = .custom
//        box.borderType = .lineBorder
//        box.borderColor = NSColor.blue
//        box.borderWidth = 2
    }
    
    override func viewWillLayout() {
        if let window = view.window {
            let topConstraint = NSLayoutConstraint(item: visualEffectView, attribute: .top, relatedBy: .equal, toItem: window.contentLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0.0)
            topConstraint.isActive = true
        }
    }
    
//    func listenForDirChanges() {
//        let notificationKey = "DirectoryChanged"
//        NotificationCenter.default.addObserver(self, selector: #selector(CommanderPanel.storeTabsData), name: NSNotification.Name(rawValue: notificationKey), object: nil)
//    }
    
    func addNewTab(to aTabView: NSTabView) {
        let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController
        let url = curViewController?.curFsItem.fileURL
        
        addNewTab(withUrl: url, andSelectIt: true)
        makeKeyResponder()
    }
    
    func addNewTab(withUrl url: URL?, andSelectIt isSelect: Bool? = false, withSelected item: URL? = nil) {
        let newModel = TabBarModel()
        let newItemController = TabItemController(nibName: "TabItemController", bundle: nil, url: url, isPrimary: isPrimary, withSelected: item)
        newItemController?.delegate = self
        newModel.title = newItemController?.title ?? "Untitled"
        
        let newItem = NSTabViewItem(identifier: newModel)
        newItem.viewController = newItemController!
        newItem.identifier = newModel
        newItem.initialFirstResponder = newItemController?.tableview  
        print("add new tab")
        tabView.addTabViewItem(newItem)
        
        if isSelect! {
            tabView.selectTabViewItem(newItem)
        }
    }
    
    func openFile(for fileName: String) -> Bool {
        var result = false
        var isDirectory: ObjCBool = false
        let fileUrl = URL(fileURLWithPath: fileName)
        var dirUrl: URL
        let isPackage = NSWorkspace().isFilePackage(atPath: fileName)
        if (FileManager.default.fileExists(atPath: fileName, isDirectory: &isDirectory)) {
            if !isDirectory.boolValue || isPackage {
                dirUrl = fileUrl.deletingLastPathComponent()
            } else {
                dirUrl = fileUrl
            }
            
            addNewTab(withUrl: dirUrl, andSelectIt: true, withSelected: fileUrl)
            result = true
        }
        
        return result
    }
    
    // Store all tab urls and selected index to UserDefaults
    func storeTabsData() {
        print("store tabs data called.")
        
        let items = tabView.tabViewItems
        let bookmarks = items.map { (item) -> NSData! in
            let controller = item.viewController as! TabItemController
            let url = controller.curFsItem.fileURL
            return bookmarkForURL(url: url) as NSData!
        }
        
        let selectedIndex = 0
        
        if let selectedTabItem = tabView.selectedTabViewItem {
            tabView.indexOfTabViewItem(selectedTabItem)
        }
        
        let panelData = ["bookmarks": bookmarks, "selected": selectedIndex] as [String : Any]
        
        if isPrimary {
            print("start to store leftPanel")
            preferenceManager.leftPanelData = panelData
        } else {
            print("start to store right panel")
            preferenceManager.rightPanelData = panelData
        }
    }
    
    func restoreTabs() {
        var panelData: [String : Any]?
        if isPrimary {
            panelData = preferenceManager.leftPanelData
        } else {
            panelData = preferenceManager.rightPanelData
        }
        
        if panelData != nil {
            let bookmarks = panelData?["bookmarks"] as? [NSData]
            
            if bookmarks != nil {
                for bookmarkData in bookmarks! {
                    let url = urlForBookmark(bookmark: bookmarkData)
                    print("The restored url is: " + (url?.absoluteString)!)
                    addNewTab(withUrl: url)
                }
                
                let selectedIndex = panelData?["selected"] as! NSInteger
                tabView.selectTabViewItem(tabView.tabViewItems[selectedIndex])
            }
        }
        
        if tabView.numberOfTabViewItems == 0 {
            print("numberOfTabViewItems is 0, start to add a Tab")
            self.addNewTab(to: tabView)
        }
    }
    
    func bookmarkForURL(url: URL) -> NSData? {
        var bookmarkData: NSData?
        do {
            try bookmarkData = url.bookmarkData(options: URL.BookmarkCreationOptions.suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil) as NSData
        } catch (_) {
            bookmarkData = nil
        }
        
        return bookmarkData
    }
    
    func urlForBookmark(bookmark: NSData) -> URL? {
        var bookmarkIsStale = false
        var bookmarkURL: URL?
        do {
            try bookmarkURL = URL(resolvingBookmarkData: bookmark as Data, options: URL.BookmarkResolutionOptions.withoutUI, relativeTo: nil, bookmarkDataIsStale: &bookmarkIsStale)
        } catch (_) {
            bookmarkURL = nil
        }
        
        return bookmarkURL
    }
    
    func closeTab() {
        if tabView.numberOfTabViewItems > 1 {
            if let selectedTab = tabView.selectedTabViewItem {
                tabView.removeTabViewItem(selectedTab)
            }
        }
    }
    
    func tabView(_ aTabView: NSTabView, didClose tabViewItem: NSTabViewItem) {
//        storeTabsData()
    }
    
    func tabView(_ aTabView: NSTabView, shouldAllow tabViewItem: NSTabViewItem, toLeave tabBarView: MMTabBarView) -> Bool {
        print("shouldAllow tabViewItem toLeave tabBarView?")
        return true
    }
    
    func tabView(_ aTabView: NSTabView, didDetach tabViewItem: NSTabViewItem) {
        print("didDetach tabViewItem")
//        storeTabsData()
    }
    
    func tabView(_ aTabView: NSTabView, didDrop tabViewItem: NSTabViewItem, in tabBarView: MMTabBarView) {
        print("didDrop tabViewItem")
//        storeTabsData()
    }
    
    func tabView(_ aTabView: NSTabView, toolTipFor tabViewItem: NSTabViewItem) -> String {
        return tabViewItem.label
    }
    
    func tabView(_ aTabView: NSTabView, tabBarViewDidHide tabBarView: MMTabBarView) {
        print("tabBarViewDidHide")
    }
    
    func tabView(_ aTabView: NSTabView, tabBarViewDidUnhide tabBarView: MMTabBarView) {
        print("tabBarViewDidUnhide")
    }
    
    @IBAction func addNewTab(_ sender: NSMenuItem) {
        print("add new tab hehehe")
        self.addNewTab(to: tabView)
    }

    @IBAction func closeSelectedTab(_ sender: NSMenuItem) {
        closeTab()
    }
    
    @IBAction func previousTab(_ sender: AnyObject?) {
        let index = tabView.indexOfTabViewItem(tabView.selectedTabViewItem!)
        
        if index == 0 {
            tabView.selectLastTabViewItem(sender)
        } else {
            tabView.selectPreviousTabViewItem(sender)
        }
    }
    
    @IBAction func nextTab(_ sender: AnyObject?) {
        if tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == tabView.numberOfTabViewItems - 1 {
            tabView.selectFirstTabViewItem(sender)
        } else {
            tabView.selectNextTabViewItem(sender)
        }
    }
    
    func previousTabWithCount(_ count: Int?) {
        let index = tabView.indexOfTabViewItem(tabView.selectedTabViewItem!)
        
        var targetIndex = 0
        if count == nil {
            targetIndex = (index - 1) % tabView.numberOfTabViewItems
        } else if count! > 0 {
            targetIndex = (index - count!) % tabView.numberOfTabViewItems
        }
        
        if targetIndex < 0 {
            targetIndex += tabView.numberOfTabViewItems
        }
        
        tabView.selectTabViewItem(at: targetIndex)
    }
    
    func nextTabWithCount(_ count: Int?) {
        let index = tabView.indexOfTabViewItem(tabView.selectedTabViewItem!)
        
        var targetIndex = 0
        if count == nil {
            targetIndex = (index + 1) % tabView.numberOfTabViewItems
        } else if count! > 0 {
            targetIndex = (index + count!) % tabView.numberOfTabViewItems
        }
        
        tabView.selectTabViewItem(at: targetIndex)
    }
    
    func handleKeyDown(with theEvent: NSEvent) -> NSEvent? {
        if !isActive() {
            return theEvent
        }
        
        print("keyCode: " + String(theEvent.keyCode))
        let flags = theEvent.modifierFlags
        let hasShift = flags.contains(NSEvent.ModifierFlags.shift)
        let hasControl = flags.contains(NSEvent.ModifierFlags.control)
        let hasOption = flags.contains(NSEvent.ModifierFlags.option)
        let hasCommand = flags.contains(NSEvent.ModifierFlags.command)
        print("hasShift: " + String(hasShift))
        print("hasControl: " + String(hasControl))
        
        let KEYCODE_TAB: UInt16 = 48
        let KEYCODE_H: UInt16 = 4
        let KEYCODE_L: UInt16 = 37
        
        switch theEvent.keyCode {
        case KEYCODE_TAB where hasControl && !hasShift,
             KEYCODE_L where hasCommand && hasOption:
            nextTab(self.view)
            return nil
            
        case KEYCODE_TAB where hasControl && hasShift,
             KEYCODE_H where hasCommand && hasOption:
            previousTab(self.view)
            return nil
            
        default:
            print("return the event")
            return theEvent
        }
    }
    
//    override func mouseDown(with event: NSEvent) {
//        print("mouseDown called.")
//        super.mouseDown(with: event)
//        if !isActive() {
//            (self.view.window?.windowController as? MainWindowController)?.switchFocus()
//        }
//    }

//    Can I add new tab inside of nsview?
//    override func newWindowForTab(_ sender: Any?) {
//        
//    }
    
    // MMTabBarView doesn't pop up mouseDown events, use this method to observe mouseDown events
    func tabView(_ aTabView: NSTabView, shouldDrag tabViewItem: NSTabViewItem, in tabBarView: MMTabBarView) -> Bool {
        makeKeyResponder()
        return true
    }
    
    func makeKeyResponder() {
        print("makeKeyResponder called.")
        if !isActive() {
            (self.view.window?.windowController as? MainWindowController)?.switchFocus()
        }
    }
    
    func isActive() -> Bool {
        return self == (self.view.window?.windowController as? MainWindowController)?.activePanel
    }
}
