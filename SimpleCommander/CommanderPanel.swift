//
//  CommanderPanel.swift
//  SimpleCommander
//
//  Created by Jamie on 15/6/4.
//  Copyright (c) 2015年 Jamie. All rights reserved.
//

import Cocoa

class CommanderPanel: NSViewController, NSTableViewDataSource, NSTableViewDelegate, MMTabBarViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        tabBar.setShowAddTabButton(true)
        tabBar.setStyleNamed("Aqua")
        tabBar.setOnlyShowCloseOnHover(true)
        
        addNewTabToTabView(tabView)
    }
    
    
    @IBOutlet weak var tabView: NSTabView!
    
    @IBOutlet weak var tabBar: MMTabBarView!
    
    func addNewTabToTabView(aTabView: NSTabView!) {
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
    
    func tabView(aTabView: NSTabView!, shouldCloseTabViewItem tabViewItem: NSTabViewItem!) -> Bool {
        return true
    }
    
    func tabView(aTabView: NSTabView!, shouldAllowTabViewItem tabViewItem: NSTabViewItem!, toLeaveTabBarView tabBarView: MMTabBarView!) -> Bool {
        return true
    }
    
    func tabView(aTabView: NSTabView!, toolTipForTabViewItem tabViewItem: NSTabViewItem!) -> String! {
        return tabViewItem.label
    }
    
    func tabView(aTabView: NSTabView!, tabBarViewDidHide tabBarView: MMTabBarView!) {
        print("tabBarViewDidHide")
    }
    
    func tabView(aTabView: NSTabView!, tabBarViewDidUnhide tabBarView: MMTabBarView!) {
        print("tabBarViewDidUnhide")
    }
    
    @IBAction func addNewTab(sender: NSMenuItem) {
        addNewTabToTabView(tabView)
    }

    @IBAction func closeSelectedTab(sender: NSMenuItem) {
        closeTab()
    }
    
    @IBAction func previousTab(sender: NSMenuItem) {
        tabView.selectPreviousTabViewItem(sender)
    }
    
    @IBAction func nextTab(sender: NSMenuItem) {
        tabView.selectNextTabViewItem(sender)
    }
    
}
