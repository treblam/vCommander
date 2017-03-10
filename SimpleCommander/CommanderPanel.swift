//
//  CommanderPanel.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/4.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class CommanderPanel: NSViewController, NSTableViewDataSource, NSTableViewDelegate, MMTabBarViewDelegate {

    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tabBar: MMTabBarView!
    
    var panelName: String?
    
    let preferenceManager = PreferenceManager()
    
    init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, panelName: String) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)!
        self.panelName = panelName
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.showAddTabButton = true
        tabBar.onlyShowCloseOnHover = true
        tabBar.setStyleNamed("Yosemite")
        
        restoreTabs()
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
            self.handleKeyDown(with: $0)
        }
//        listenForDirChanges()
    }
    
//    func listenForDirChanges() {
//        let notificationKey = "DirectoryChanged"
//        NotificationCenter.default.addObserver(self, selector: #selector(CommanderPanel.storeTabsData), name: NSNotification.Name(rawValue: notificationKey), object: nil)
//    }
    
    func addNewTab(to aTabView: NSTabView) {
        let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController
        let url = curViewController?.curFsItem.fileURL
        
        addNewTab(withUrl: url, andSelectIt: true)
    }
    
    func addNewTab(withUrl url: URL?, andSelectIt isSelect: Bool? = false, withSelected item: URL? = nil) {
        let newModel = TabBarModel()
        let newItem = NSTabViewItem(identifier: newModel)
        
        let newItemController = TabItemController(nibName: "TabItemController", bundle: nil, url: url, withSelected: item)
        
        newModel.title = newItemController?.title ?? "Untitled"
        
        newItem.viewController = newItemController!
        newItem.identifier = newModel
        
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
        if (FileManager.default.fileExists(atPath: fileName, isDirectory: &isDirectory)) {
            if !isDirectory.boolValue {
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
        
        if panelName == "leftPanel" {
            print("start to store leftPanel")
            preferenceManager.leftPanelData = panelData
        } else if panelName == "rightPanel" {
            print("start to store right panel")
            preferenceManager.rightPanelData = panelData
        }
    }
    
    func restoreTabs() {
        var panelData: [String : Any]?
        if panelName == "leftPanel" {
            panelData = preferenceManager.leftPanelData
        } else if panelName == "rightPanel" {
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
        print("add new tab")
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
    
    func handleKeyDown(with theEvent: NSEvent) -> NSEvent? {
        if !isActive() {
            return theEvent
        }
        
        print("keyCode: " + String(theEvent.keyCode))
        let flags = theEvent.modifierFlags
        let hasShift = flags.contains(.shift)
        let hasControl = flags.contains(.control)
        print("hasShift: " + String(hasShift))
        print("hasControl: " + String(hasControl))
        
        let TabKey_KeyCode: UInt16 = 48
        
        switch theEvent.keyCode {
        case TabKey_KeyCode where hasControl && !hasShift:
            nextTab(self.view)
            return nil
            
        case TabKey_KeyCode where hasControl && hasShift:
            previousTab(self.view)
            return nil
            
        default:
            return theEvent
        }
    }
    
    func isActive() -> Bool {
        return self == (self.view.window?.windowController as! MainWindowController).activePanel
    }
}
