//
//  CommanderPanel.swift
//  vCommander
//
//  Created by Jamie on 15/6/4.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class CommanderPanel: NSViewController, MMTabBarViewDelegate, NSMenuDelegate {

    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tabBar: MMTabBarView!
    
    @IBOutlet weak var visualEffectView: NSVisualEffectView!
    
    var isPrimary: Bool!
    
    let preferenceManager = PreferenceManager()
    
    static let TABBAR_HEIGHT: CGFloat = 25
    static let PATHCONTROL_HEIGHT: CGFloat = 19
    static let TABLEVIEW_HEADER_HEIGHT: CGFloat = 23
    
    var scrollViewTopInset: CGFloat = 0
    var tableViewTopInset: CGFloat = 0
    
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
            
            let contentLayoutRect = window.contentLayoutRect
            scrollViewTopInset = NSHeight(window.frame) - NSMaxY(contentLayoutRect) + CommanderPanel.TABBAR_HEIGHT + CommanderPanel.PATHCONTROL_HEIGHT
            tableViewTopInset = scrollViewTopInset + CommanderPanel.TABLEVIEW_HEADER_HEIGHT
        }
    }
    
    override func viewDidAppear() {
        print("CommanderPanel viewDidAppear")
        makeKeyResponder()
    }
    
//    func listenForDirChanges() {
//        let notificationKey = "DirectoryChanged"
//        NotificationCenter.default.addObserver(self, selector: #selector(CommanderPanel.storeTabsData), name: NSNotification.Name(rawValue: notificationKey), object: nil)
//    }
    
    func menuWillOpen(_ menu: NSMenu) {
        print("menuWillOpen called")
    }
    
    func addNewTab(to aTabView: NSTabView) {
        let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController
        let url = curViewController?.curFsItem.fileURL
        
        addNewTab(withUrl: url, andSelectIt: true)
        makeMeActive()
    }
    
    func addNewTab(withUrl url: URL?, andSelectIt isSelect: Bool? = false, withSelected item: URL? = nil) {
        let newModel = TabBarModel()
        let newItemController = TabItemController(nibName: "TabItemController", bundle: nil, url: url, isPrimary: isPrimary, withSelected: item)
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
        if (FileManager.default.fileExists(atPath: fileName, isDirectory: &isDirectory)) {
            let isPackage = NSWorkspace().isFilePackage(atPath: fileName)
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
    
    func goTo(url: URL) {
        guard let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController else {
            return
        }
        
        curViewController.goTo(url: url)
    }
    
    func getCurrentUrl() -> URL? {
        guard let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController else {
            return nil
        }
        return curViewController.curFsItem.fileURL
    }
    
    // Store all tab urls and selected index to UserDefaults
    func storeTabsData() {
        print("store tabs data called.")
        
        let items = tabView.tabViewItems
        let bookmarks = items.map { (item) -> NSData? in
            let controller = item.viewController as! TabItemController
            let url = controller.curFsItem.fileURL
            return bookmarkForURL(url: url) as NSData?
        }
        
        var selectedIndex = 0
        
        if let selectedTabItem = tabView.selectedTabViewItem {
            selectedIndex = tabView.indexOfTabViewItem(selectedTabItem)
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
                let selectedTab = tabView.tabViewItems[selectedIndex]
                tabView.selectTabViewItem(selectedTab)
            }
        }
        
        if tabView.numberOfTabViewItems == 0 {
            print("numberOfTabViewItems is 0, start to add a Tab")
            self.addNewTab(to: tabView)
        }
        
        print("Tabs restored.")
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
    
    @IBAction func addToHotlist(_ sender: AnyObject?) {
        
    }
    
    @IBAction func configHotlist(_ sender: AnyObject?) {
        
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
        
        var targetIndex: Int?
        if count == nil || count == 0 {
            targetIndex = (index + 1) % tabView.numberOfTabViewItems
        } else if count! > 0 && count! <= tabView.numberOfTabViewItems {
            targetIndex = count! - 1
        }
        
        if let toBeSelectedIndex = targetIndex {
            tabView.selectTabViewItem(at: toBeSelectedIndex)
        }
    }
    
    func handleKeyDown(with theEvent: NSEvent) -> NSEvent? {
        if !isActive() {
            return theEvent
        }
        
        print("keyCode: \(theEvent.keyCode)")
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
        let KEYCODE_D: UInt16 = 2
        
        switch theEvent.keyCode {
        case KEYCODE_TAB where hasControl && !hasShift,
             KEYCODE_L where hasCommand && hasOption:
            nextTab(self.view)
            return nil
            
        case KEYCODE_TAB where hasControl && hasShift,
             KEYCODE_H where hasCommand && hasOption:
            previousTab(self.view)
            return nil
            
        case KEYCODE_D where hasCommand && !hasOption && !hasControl && !hasShift:
            let frameRelativeToWindow = visualEffectView.convert(visualEffectView.bounds, to: nil)
            print("topInset: \(frameRelativeToWindow.minY)")
            self.view.menu?.popUp(positioning: nil, at: NSPoint(x: 0, y: self.view.bounds.maxY - tableViewTopInset), in: self.view)
            return nil
            
        default:
            print("return the event")
            return theEvent
        }
    }
    
    // MMTabBarView doesn't pop up mouseDown events, use this method to observe mouseDown events
    func tabView(_ aTabView: NSTabView, shouldDrag tabViewItem: NSTabViewItem, in tabBarView: MMTabBarView) -> Bool {
        makeMeActive()
        return true
    }
    
    func makeMeActive() {
        print("makeMeActive called.")
        if !isActive() {
            (self.view.window?.windowController as? MainWindowController)?.switchFocus()
        }
    }
    
    func makeKeyResponder() {
        // 修正一下选中状态
        if isActive() {
            (self.view.window?.windowController as? MainWindowController)?.switchFocus()
            (self.view.window?.windowController as? MainWindowController)?.switchFocus()
        }
    }
    
    func isActive() -> Bool {
        return self == (self.view.window?.windowController as? MainWindowController)?.activePanel
    }
}
