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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        tabBar.setShowAddTabButton(true)
        tabBar.setStyleNamed("Aqua")
        tabBar.setOnlyShowCloseOnHover(true)
        
        self.addNewTab(to: tabView)
    }
    
    func addNewTab(to aTabView: NSTabView!) {
        let newModel = TabBarModel()
        
        let newItem = NSTabViewItem(identifier: newModel)
        
        let curViewController = tabView.selectedTabViewItem?.viewController as? TabItemController
        let url = curViewController?.curFsItem.fileURL
        
        let newItemController = TabItemController(nibName: "TabItemController", bundle: nil, url: url)
        
        newModel.title = newItemController?.title ?? "Untitled"
        
        newItem.viewController = newItemController!
        newItem.identifier = newModel
        
        tabView.addTabViewItem(newItem)
        tabView.selectTabViewItem(newItem)
    }
    
//    func getAllPath() {
//        tabView.tabViewItems
//    }
    
    func closeTab() {
        let tabCount = tabView.numberOfTabViewItems
        
        // Don't allow to close the last tab
        if tabCount == 1 {
            return
        }
        
        if let selectedTab = tabView.selectedTabViewItem {
            tabView.removeTabViewItem(selectedTab)
        }
    }
    
    func tabView(_ aTabView: NSTabView!, shouldClose tabViewItem: NSTabViewItem!) -> Bool {
        return true
    }
    
    func tabView(_ aTabView: NSTabView!, shouldAllow tabViewItem: NSTabViewItem!, toLeave tabBarView: MMTabBarView!) -> Bool {
        return true
    }
    
    func tabView(_ aTabView: NSTabView!, toolTipFor tabViewItem: NSTabViewItem!) -> String! {
        return tabViewItem.label
    }
    
    func tabView(_ aTabView: NSTabView!, tabBarViewDidHide tabBarView: MMTabBarView!) {
        print("tabBarViewDidHide")
    }
    
    func tabView(_ aTabView: NSTabView!, tabBarViewDidUnhide tabBarView: MMTabBarView!) {
        print("tabBarViewDidUnhide")
    }
    
    @IBAction func addNewTab(_ sender: NSMenuItem) {
        self.addNewTab(to: tabView)
    }

    @IBAction func closeSelectedTab(_ sender: NSMenuItem) {
        closeTab()
    }
    
    @IBAction func previousTab(_ sender: NSMenuItem) {
        tabView.selectPreviousTabViewItem(sender)
    }
    
    @IBAction func nextTab(_ sender: NSMenuItem) {
        tabView.selectNextTabViewItem(sender)
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        print("encodeRestorableState called.")
    }
    
    override func restoreState(with coder: NSCoder) {
        print("restoreState called.")
    }
}
